import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import '../providers/blossom_config_provider.dart';
import '../services/ndk_service.dart';
import '../providers/key_provider.dart';
import '../services/login_service.dart';
import '../models/lockbox_file.dart';
import '../models/cached_file.dart';
import 'logger.dart';

/// Provider for FileStorageService
final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService(
    ref.read(ndkServiceProvider),
    ref.read(loginServiceProvider),
    ref.read(blossomConfigServiceProvider),
  );
});

/// Service for managing file storage operations
class FileStorageService {
  // ignore: unused_field
  final NdkService _ndkService; // Reserved for future NDK Blossom API integration
  final LoginService _loginService;
  // ignore: unused_field
  final BlossomConfigService _blossomConfigService; // Reserved for future Blossom config usage

  FileStorageService(
    this._ndkService,
    this._loginService,
    this._blossomConfigService,
  );

  static const String _cachedFilesKey = 'cached_files';
  static const int _maxTotalSizeBytes = 1073741824; // 1GB

  /// Opens native file picker and returns selected files
  Future<List<PlatformFile>> pickFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      // Validate total size
      int totalSize = 0;
      for (final file in result.files) {
        totalSize += file.size;
      }

      if (totalSize > _maxTotalSizeBytes) {
        throw ArgumentError(
          'Total file size ($totalSize bytes) exceeds maximum allowed size (${_maxTotalSizeBytes} bytes)',
        );
      }

      return result.files;
    } catch (e) {
      Log.error('Error picking files', e);
      rethrow;
    }
  }

  /// Encrypts file and uploads to Blossom server
  Future<LockboxFile> encryptAndUploadFile({
    required PlatformFile file,
    required Uint8List encryptionKey,
    required String serverUrl,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Step 1: Read file bytes
      Uint8List fileBytes;
      if (file.bytes != null) {
        fileBytes = file.bytes!;
      } else if (file.path != null) {
        final fileObj = File(file.path!);
        fileBytes = await fileObj.readAsBytes();
      } else {
        throw ArgumentError('File must have either bytes or path');
      }

      // Step 2: Generate encryption salt
      final salt = _generateSalt();

      // Step 3: Encrypt bytes using AES-256-GCM
      final encryptedBytes = await _encryptAesGcm(fileBytes, encryptionKey, salt);

      // Step 4: Upload to Blossom via HTTP
      final blossomResult = await _uploadToBlossom(
        encryptedBytes: encryptedBytes,
        serverUrl: serverUrl,
        onProgress: onProgress,
      );

      // Step 5: Create LockboxFile metadata
      final lockboxFile = LockboxFile.create(
        name: file.name,
        sizeBytes: file.size,
        mimeType: file.extension ?? 'application/octet-stream',
        blossomHash: blossomResult['hash'] as String,
        blossomUrl: blossomResult['url'] as String,
        encryptionSalt: base64Encode(salt),
      );

      lockboxFile.validate();
      return lockboxFile;
    } catch (e) {
      Log.error('Error encrypting and uploading file', e);
      rethrow;
    }
  }

  /// Downloads encrypted file from Blossom (without decrypting)
  Future<Uint8List> downloadEncryptedFile({
    required String blossomUrl,
    required String blossomHash,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Step 1: Download encrypted bytes from Blossom
      final encryptedBytes = await _downloadFromBlossom(
        blossomUrl: blossomUrl,
        onProgress: onProgress,
      );

      // Step 2: Verify SHA-256 hash
      final computedHash = sha256.convert(encryptedBytes).toString();
      if (computedHash != blossomHash) {
        throw Exception('File hash mismatch: expected $blossomHash, got $computedHash');
      }

      return encryptedBytes;
    } catch (e) {
      Log.error('Error downloading encrypted file', e);
      rethrow;
    }
  }

  /// Downloads encrypted file from Blossom and decrypts
  Future<Uint8List> downloadAndDecryptFile({
    required String blossomUrl,
    required String blossomHash,
    required Uint8List encryptionKey,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Step 1: Download encrypted bytes from Blossom
      final encryptedBytes = await downloadEncryptedFile(
        blossomUrl: blossomUrl,
        blossomHash: blossomHash,
        onProgress: onProgress,
      );

      // Step 2: Decrypt bytes using AES-256-GCM
      // Nonce is embedded in the encrypted data (first 12 bytes)
      final decryptedBytes = await _decryptAesGcm(encryptedBytes, encryptionKey);

      return decryptedBytes;
    } catch (e) {
      Log.error('Error downloading and decrypting file', e);
      rethrow;
    }
  }

  /// Deletes file from Blossom server
  Future<bool> deleteFile({
    required String blossomHash,
    required String serverUrl,
  }) async {
    try {
      // Blossom delete via HTTP DELETE request
      final uri = Uri.parse('$serverUrl/$blossomHash');
      final keyPair = await _loginService.getStoredNostrKey();
      if (keyPair == null) {
        throw Exception('No Nostr key available for authentication');
      }

      // TODO: Add Nostr signature authentication header
      final response = await http.delete(uri);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 404) {
        // Already deleted
        return false;
      } else {
        throw Exception('Failed to delete file: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      Log.error('Error deleting file from Blossom', e);
      rethrow;
    }
  }

  /// Saves decrypted file to user-chosen location
  Future<bool> saveFile({
    required Uint8List fileBytes,
    required String suggestedName,
    String? mimeType,
  }) async {
    try {
      final result = await FilePicker.platform.saveFile(
        fileName: suggestedName,
      );

      if (result == null) {
        return false; // User cancelled
      }

      final file = File(result);
      await file.writeAsBytes(fileBytes);
      return true;
    } catch (e) {
      Log.error('Error saving file', e);
      rethrow;
    }
  }

  /// Caches encrypted file locally for key holder
  Future<CachedFile> cacheEncryptedFile({
    required String lockboxId,
    required String fileHash,
    required String fileName,
    required Uint8List encryptedBytes,
  }) async {
    try {
      // Get cache directory
      final cacheDir = await getApplicationCacheDirectory();
      final lockboxDir = Directory('${cacheDir.path}/encrypted_files/$lockboxId');
      if (!await lockboxDir.exists()) {
        await lockboxDir.create(recursive: true);
      }

      // Write encrypted bytes
      final cacheFile = File('${lockboxDir.path}/$fileHash.enc');
      await cacheFile.writeAsBytes(encryptedBytes);

      // Create CachedFile metadata
      final cachedFile = CachedFile(
        lockboxId: lockboxId,
        fileHash: fileHash,
        fileName: fileName,
        sizeBytes: encryptedBytes.length,
        cachedAt: DateTime.now(),
        cachePath: cacheFile.path,
      );

      cachedFile.validate();

      // Save metadata to SharedPreferences
      await _saveCachedFileMetadata(cachedFile);

      return cachedFile;
    } catch (e) {
      Log.error('Error caching encrypted file', e);
      rethrow;
    }
  }

  /// Retrieves cached encrypted file
  Future<Uint8List?> getCachedFile({
    required String lockboxId,
    required String fileHash,
  }) async {
    try {
      final cachedFiles = await getAllCachedFiles();
      final cachedFile = cachedFiles.firstWhere(
        (f) => f.lockboxId == lockboxId && f.fileHash == fileHash,
        orElse: () => throw Exception('Cached file not found'),
      );

      // Check if file exists on disk
      if (!await cachedFile.existsOnDisk()) {
        // Cache evicted by OS, remove metadata
        await _removeCachedFileMetadata(cachedFile);
        return null;
      }

      final file = File(cachedFile.cachePath);
      return await file.readAsBytes();
    } catch (e) {
      Log.debug('Cached file not found or error reading', e);
      return null;
    }
  }

  /// Deletes cached files for a lockbox
  Future<int> deleteCachedFiles(String lockboxId) async {
    try {
      final cachedFiles = await getAllCachedFiles();
      final lockboxFiles = cachedFiles.where((f) => f.lockboxId == lockboxId).toList();

      int deletedCount = 0;
      for (final cachedFile in lockboxFiles) {
        try {
          final file = File(cachedFile.cachePath);
          if (await file.exists()) {
            await file.delete();
            deletedCount++;
          }
          await _removeCachedFileMetadata(cachedFile);
        } catch (e) {
          Log.warning('Error deleting cached file ${cachedFile.cachePath}', e);
        }
      }

      // Try to remove directory if empty
      try {
        final cacheDir = await getApplicationCacheDirectory();
        final lockboxDir = Directory('${cacheDir.path}/encrypted_files/$lockboxId');
        if (await lockboxDir.exists()) {
          await lockboxDir.delete(recursive: true);
        }
      } catch (e) {
        // Directory might not be empty or already deleted
        Log.debug('Could not delete lockbox cache directory', e);
      }

      return deletedCount;
    } catch (e) {
      Log.error('Error deleting cached files', e);
      rethrow;
    }
  }

  /// Gets all cached files
  Future<List<CachedFile>> getAllCachedFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_cachedFilesKey);

      if (jsonData == null || jsonData.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonData);
      final cachedFiles = jsonList
          .map((json) => CachedFile.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter out files that no longer exist on disk
      final validFiles = <CachedFile>[];
      for (final file in cachedFiles) {
        if (await file.existsOnDisk()) {
          validFiles.add(file);
        } else {
          // Remove from metadata
          await _removeCachedFileMetadata(file);
        }
      }

      return validFiles;
    } catch (e) {
      Log.error('Error loading cached files', e);
      return [];
    }
  }

  // Private helper methods

  Uint8List _generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return Uint8List.fromList(utf8.encode(random));
  }

  Future<Uint8List> _encryptAesGcm(
    Uint8List plaintext,
    Uint8List key,
    Uint8List salt,
  ) async {
    try {
      if (key.length != 32) {
        throw ArgumentError('Encryption key must be 32 bytes (256 bits)');
      }

      // Use AES-256-GCM from cryptography package
      final algorithm = AesGcm.with256bits();
      final secretKey = SecretKey(key);
      final nonce = algorithm.newNonce(); // Generate random nonce

      // Encrypt
      final secretBox = await algorithm.encrypt(
        plaintext,
        secretKey: secretKey,
        nonce: nonce,
      );

      // Combine nonce + ciphertext + mac for storage
      // Format: [nonce (12 bytes)][ciphertext][mac (16 bytes)]
      final result = Uint8List(nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length);
      result.setRange(0, nonce.length, nonce);
      result.setRange(nonce.length, nonce.length + secretBox.cipherText.length, secretBox.cipherText);
      result.setRange(
        nonce.length + secretBox.cipherText.length,
        result.length,
        secretBox.mac.bytes,
      );

      return result;
    } catch (e) {
      Log.error('Error encrypting with AES-GCM', e);
      rethrow;
    }
  }

  Future<Uint8List> _decryptAesGcm(
    Uint8List ciphertext,
    Uint8List key,
  ) async {
    try {
      if (key.length != 32) {
        throw ArgumentError('Encryption key must be 32 bytes (256 bits)');
      }

      // Extract nonce, ciphertext, and mac
      // Format: [nonce (12 bytes)][ciphertext][mac (16 bytes)]
      if (ciphertext.length < 28) {
        throw ArgumentError('Ciphertext too short');
      }

      final nonce = ciphertext.sublist(0, 12);
      final macBytes = ciphertext.sublist(ciphertext.length - 16);
      final encryptedData = ciphertext.sublist(12, ciphertext.length - 16);

      // Use AES-256-GCM from cryptography package
      final algorithm = AesGcm.with256bits();
      final secretKey = SecretKey(key);
      final mac = Mac(macBytes);

      final secretBox = SecretBox(
        encryptedData,
        nonce: nonce,
        mac: mac,
      );

      // Decrypt
      final decrypted = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return Uint8List.fromList(decrypted);
    } catch (e) {
      Log.error('Error decrypting with AES-GCM', e);
      rethrow;
    }
  }

  Future<Map<String, String>> _uploadToBlossom({
    required Uint8List encryptedBytes,
    required String serverUrl,
    void Function(double progress)? onProgress,
  }) async {
    // Blossom upload via HTTP POST
    final uri = Uri.parse('$serverUrl/upload');
    final keyPair = await _loginService.getStoredNostrKey();
    if (keyPair == null) {
      throw Exception('No Nostr key available for authentication');
    }

    // TODO: Add Nostr signature authentication header
    // For now, basic HTTP upload
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        encryptedBytes,
        filename: 'encrypted.bin',
      ),
    );

    final streamedResponse = await request.send();

    if (onProgress != null) {
      // Track progress
      int uploaded = 0;
      streamedResponse.stream.listen(
        (chunk) {
          uploaded += chunk.length;
          onProgress(uploaded / encryptedBytes.length);
        },
      );
    }

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Blossom upload failed: ${response.statusCode} ${response.body}');
    }

    // Parse response to get hash and URL
    final responseData = json.decode(response.body) as Map<String, dynamic>;
    return {
      'hash': responseData['hash'] as String,
      'url': responseData['url'] as String,
    };
  }

  Future<Uint8List> _downloadFromBlossom({
    required String blossomUrl,
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse(blossomUrl);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Blossom download failed: ${response.statusCode}');
    }

    if (onProgress != null) {
      onProgress(1.0);
    }

    return response.bodyBytes;
  }

  Future<void> _saveCachedFileMetadata(CachedFile cachedFile) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedFiles = await getAllCachedFiles();

    // Remove existing entry if present
    cachedFiles.removeWhere(
      (f) => f.lockboxId == cachedFile.lockboxId && f.fileHash == cachedFile.fileHash,
    );

    // Add new entry
    cachedFiles.add(cachedFile);

    // Save to SharedPreferences
    final jsonList = cachedFiles.map((f) => f.toJson()).toList();
    await prefs.setString(_cachedFilesKey, json.encode(jsonList));
  }

  Future<void> _removeCachedFileMetadata(CachedFile cachedFile) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedFiles = await getAllCachedFiles();

    cachedFiles.removeWhere(
      (f) => f.lockboxId == cachedFile.lockboxId && f.fileHash == cachedFile.fileHash,
    );

    final jsonList = cachedFiles.map((f) => f.toJson()).toList();
    await prefs.setString(_cachedFilesKey, json.encode(jsonList));
  }
}

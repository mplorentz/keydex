import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/lockbox_file.dart';
import '../models/cached_file.dart';
import 'logger.dart';

/// Manages file selection, encryption, upload to Blossom, caching, and download/decryption
class FileStorageService {
  static const String _cachedFilesKey = 'cached_files';
  final _uuid = const Uuid();

  /// Opens native file picker and returns selected files
  Future<List<PlatformFile>> pickFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
      );

      if (result == null) {
        return [];
      }

      // Validate total size
      final totalSize = result.files.fold<int>(0, (sum, file) => sum + (file.size));
      if (totalSize > 1073741824) {
        // 1GB
        throw StateError('Total file size exceeds 1GB limit');
      }

      return result.files;
    } catch (e) {
      Log.error('File picker failed', e);
      throw StateError('Failed to pick files: $e');
    }
  }

  /// Encrypts file and uploads to Blossom server
  /// 
  /// Note: This is a stub implementation. Full Blossom integration will be added in Phase 3.5+
  Future<LockboxFile> encryptAndUploadFile({
    required PlatformFile file,
    required Uint8List encryptionKey,
    required String serverUrl,
    void Function(double progress)? onProgress,
  }) async {
    try {
      Log.info('Encrypting and uploading file: ${file.name}');
      
      // Read file bytes
      Uint8List fileBytes;
      if (file.bytes != null) {
        fileBytes = file.bytes!;
      } else if (file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      } else {
        throw StateError('File has no bytes or path');
      }

      // Simulate encryption progress
      onProgress?.call(0.3);
      
      // TODO: Actual encryption with ntcdcrypto
      // For now, simulate encrypted bytes
      await Future.delayed(const Duration(milliseconds: 100));
      onProgress?.call(0.6);

      // TODO: Actual upload to Blossom via NDK
      // Simulate upload
      await Future.delayed(const Duration(milliseconds: 300));
      onProgress?.call(0.9);

      // Generate placeholder hash and URL
      final hash = _generateMockHash(fileBytes);
      final blossomUrl = '$serverUrl/$hash';
      
      onProgress?.call(1.0);

      // Create LockboxFile metadata
      final lockboxFile = LockboxFile(
        id: _uuid.v4(),
        name: file.name,
        sizeBytes: file.size,
        mimeType: file.extension != null ? 'application/${file.extension}' : 'application/octet-stream',
        blossomHash: hash,
        blossomUrl: blossomUrl,
        uploadedAt: DateTime.now(),
        encryptionSalt: base64Encode(List.generate(16, (i) => i)),
      );

      Log.info('File uploaded successfully: ${file.name}');
      return lockboxFile;
    } catch (e) {
      Log.error('Failed to encrypt and upload file: ${file.name}', e);
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
      Log.info('Downloading and decrypting file from: $blossomUrl');

      // TODO: Actual download from Blossom via NDK
      // Simulate download
      onProgress?.call(0.3);
      await Future.delayed(const Duration(milliseconds: 300));
      onProgress?.call(0.6);

      // TODO: Verify hash
      // TODO: Actual decryption with ntcdcrypto
      // Simulate decryption
      await Future.delayed(const Duration(milliseconds: 100));
      onProgress?.call(0.9);

      // Return mock decrypted bytes
      final mockBytes = Uint8List.fromList('Mock file content'.codeUnits);
      onProgress?.call(1.0);

      Log.info('File downloaded and decrypted successfully');
      return mockBytes;
    } catch (e) {
      Log.error('Failed to download and decrypt file from: $blossomUrl', e);
      rethrow;
    }
  }

  /// Deletes file from Blossom server
  Future<bool> deleteFile({
    required String blossomHash,
    required String serverUrl,
  }) async {
    try {
      Log.info('Deleting file from Blossom: $blossomHash');

      // TODO: Actual delete via NDK Blossom API
      // Simulate delete
      await Future.delayed(const Duration(milliseconds: 100));

      Log.info('File deleted from Blossom: $blossomHash');
      return true;
    } catch (e) {
      Log.error('Failed to delete file from Blossom: $blossomHash', e);
      return false;
    }
  }

  /// Saves decrypted file to user-chosen location
  Future<bool> saveFile({
    required Uint8List fileBytes,
    required String suggestedName,
    String? mimeType,
  }) async {
    try {
      Log.info('Saving file: $suggestedName');

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save file',
        fileName: suggestedName,
      );

      if (outputPath == null) {
        Log.info('File save cancelled by user');
        return false;
      }

      await File(outputPath).writeAsBytes(fileBytes);
      Log.info('File saved successfully: $outputPath');
      return true;
    } catch (e) {
      Log.error('Failed to save file: $suggestedName', e);
      throw StateError('Failed to save file: $e');
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
      Log.info('Caching encrypted file: $fileName for lockbox $lockboxId');

      // Get cache directory
      final cacheDir = await getApplicationCacheDirectory();
      final encryptedFilesDir = Directory('${cacheDir.path}/encrypted_files/$lockboxId');
      
      // Create directory if not exists
      if (!await encryptedFilesDir.exists()) {
        await encryptedFilesDir.create(recursive: true);
      }

      // Write encrypted file
      final filePath = '${encryptedFilesDir.path}/$fileHash.enc';
      await File(filePath).writeAsBytes(encryptedBytes);

      // Create metadata
      final cachedFile = CachedFile(
        lockboxId: lockboxId,
        fileHash: fileHash,
        fileName: fileName,
        sizeBytes: encryptedBytes.length,
        cachedAt: DateTime.now(),
        cachePath: filePath,
      );

      // Save metadata
      await _addCachedFileMetadata(cachedFile);

      Log.info('File cached successfully: $fileName');
      return cachedFile;
    } catch (e) {
      Log.error('Failed to cache encrypted file: $fileName', e);
      rethrow;
    }
  }

  /// Retrieves cached encrypted file
  Future<Uint8List?> getCachedFile({
    required String lockboxId,
    required String fileHash,
  }) async {
    try {
      // Load metadata
      final cachedFiles = await getAllCachedFiles();
      final cachedFile = cachedFiles.firstWhere(
        (f) => f.lockboxId == lockboxId && f.fileHash == fileHash,
        orElse: () => throw StateError('File not in cache'),
      );

      // Read from disk
      final file = File(cachedFile.cachePath);
      if (!await file.exists()) {
        Log.warning('Cached file not found on disk (evicted by OS): ${cachedFile.fileName}');
        await _removeCachedFileMetadata(lockboxId, fileHash);
        return null;
      }

      return await file.readAsBytes();
    } catch (e) {
      Log.error('Failed to get cached file: lockbox=$lockboxId hash=$fileHash', e);
      return null;
    }
  }

  /// Deletes cached files for a lockbox
  Future<int> deleteCachedFiles(String lockboxId) async {
    try {
      Log.info('Deleting cached files for lockbox: $lockboxId');

      // Get cached files for this lockbox
      final cachedFiles = await getAllCachedFiles();
      final filesToDelete = cachedFiles.where((f) => f.lockboxId == lockboxId).toList();

      // Delete directory
      final cacheDir = await getApplicationCacheDirectory();
      final lockboxDir = Directory('${cacheDir.path}/encrypted_files/$lockboxId');
      if (await lockboxDir.exists()) {
        await lockboxDir.delete(recursive: true);
      }

      // Remove metadata
      for (final file in filesToDelete) {
        await _removeCachedFileMetadata(file.lockboxId, file.fileHash);
      }

      Log.info('Deleted ${filesToDelete.length} cached files');
      return filesToDelete.length;
    } catch (e) {
      Log.error('Failed to delete cached files for lockbox: $lockboxId', e);
      return 0;
    }
  }

  /// Gets all cached files
  Future<List<CachedFile>> getAllCachedFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cachedFilesKey);
      
      if (jsonStr == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonStr) as List;
      return jsonList
          .map((json) => CachedFile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Log.error('Failed to load cached files metadata', e);
      return [];
    }
  }

  /// Internal: Add cached file metadata
  Future<void> _addCachedFileMetadata(CachedFile cachedFile) async {
    final cachedFiles = await getAllCachedFiles();
    cachedFiles.add(cachedFile);
    await _saveCachedFilesMetadata(cachedFiles);
  }

  /// Internal: Remove cached file metadata
  Future<void> _removeCachedFileMetadata(String lockboxId, String fileHash) async {
    final cachedFiles = await getAllCachedFiles();
    cachedFiles.removeWhere((f) => f.lockboxId == lockboxId && f.fileHash == fileHash);
    await _saveCachedFilesMetadata(cachedFiles);
  }

  /// Internal: Save cached files metadata
  Future<void> _saveCachedFilesMetadata(List<CachedFile> cachedFiles) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = cachedFiles.map((f) => f.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    await prefs.setString(_cachedFilesKey, jsonStr);
  }

  /// Internal: Generate mock hash for testing
  String _generateMockHash(Uint8List bytes) {
    // Simple mock hash for testing - not cryptographically secure
    final hashBytes = bytes.take(32).toList();
    while (hashBytes.length < 32) {
      hashBytes.add(0);
    }
    return hashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}


import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lockbox.dart';
import 'key_service.dart';
import 'logger.dart';

/// Service for managing persistent, encrypted lockbox storage
class LockboxService {
  static const String _lockboxesKey = 'encrypted_lockboxes';
  static List<Lockbox>? _cachedLockboxes;
  static bool _isInitialized = false;

  /// Initialize the storage and load existing lockboxes
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadLockboxes();

      // If no lockboxes exist, create some sample data for first-time users
      if (_cachedLockboxes!.isEmpty) {
        await _createSampleData();
      }

      _isInitialized = true;
    } catch (e) {
      Log.error('Error initializing LockboxService', e);
      _cachedLockboxes = [];
      _isInitialized = true;
    }
  }

  /// Load lockboxes from SharedPreferences and decrypt them
  static Future<void> _loadLockboxes() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(_lockboxesKey);
    Log.info('Loading encrypted lockboxes from SharedPreferences');

    if (encryptedData == null || encryptedData.isEmpty) {
      _cachedLockboxes = [];
      Log.info('No encrypted lockboxes found in SharedPreferences');
      return;
    }

    try {
      // Decrypt the data using our Nostr key
      final decryptedJson = await KeyService.decryptText(encryptedData);
      final List<dynamic> jsonList = json.decode(decryptedJson);
      Log.info('Decrypted ${jsonList.length} lockboxes');

      // TODO: Don't cache these decrypted in memory
      _cachedLockboxes =
          jsonList.map((json) => Lockbox.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      Log.error('Error decrypting lockboxes', e);
      _cachedLockboxes = [];
    }
  }

  /// Save lockboxes to SharedPreferences with encryption
  static Future<void> _saveLockboxes() async {
    if (_cachedLockboxes == null) return;

    try {
      // Convert to JSON
      final jsonList = _cachedLockboxes!.map((lockbox) => lockbox.toJson()).toList();
      final jsonString = json.encode(jsonList);

      // Encrypt the JSON data using our Nostr key
      final encryptedData = await KeyService.encryptText(jsonString);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lockboxesKey, encryptedData);
      Log.info('Saved ${jsonList.length} encrypted lockboxes to SharedPreferences');
    } catch (e) {
      Log.error('Error encrypting and saving lockboxes', e);
      throw Exception('Failed to save lockboxes: $e');
    }
  }

  /// Create sample data for first-time users
  static Future<void> _createSampleData() async {
    _cachedLockboxes = [
      Lockbox(
        id: '1',
        name: 'Personal Notes',
        content:
            'This is my private journal entry. It contains sensitive thoughts and ideas that I want to keep secure.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Lockbox(
        id: '2',
        name: 'Passwords',
        content: 'Gmail: mypassword123\nBank: secretbank456\nSocial Media: social789',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Lockbox(
        id: '3',
        name: 'Secret Recipe',
        content:
            'Grandma\'s secret chocolate chip cookie recipe:\n- 2 cups flour\n- 1 cup butter\n- Secret ingredient: love',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];

    // Save the sample data
    await _saveLockboxes();
  }

  /// Get all lockboxes
  static Future<List<Lockbox>> getAllLockboxes() async {
    await initialize();
    return List.unmodifiable(_cachedLockboxes ?? []);
  }

  /// Add a new lockbox
  static Future<void> addLockbox(Lockbox lockbox) async {
    await initialize();
    _cachedLockboxes!.add(lockbox);
    await _saveLockboxes();
  }

  /// Update an existing lockbox
  static Future<void> updateLockbox(String id, String name, String content) async {
    await initialize();
    final index = _cachedLockboxes!.indexWhere((lb) => lb.id == id);
    if (index != -1) {
      _cachedLockboxes![index] = Lockbox(
        id: id,
        name: name,
        content: content,
        createdAt: _cachedLockboxes![index].createdAt,
      );
      await _saveLockboxes();
    }
  }

  /// Delete a lockbox
  static Future<void> deleteLockbox(String id) async {
    await initialize();
    _cachedLockboxes!.removeWhere((lb) => lb.id == id);
    await _saveLockboxes();
  }

  /// Get a specific lockbox by ID
  static Future<Lockbox?> getLockbox(String id) async {
    await initialize();
    try {
      return _cachedLockboxes!.firstWhere((lb) => lb.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear all lockboxes (for testing)
  static Future<void> clearAll() async {
    _cachedLockboxes = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockboxesKey);
    _isInitialized = false;
  }

  /// Refresh the cached data from storage
  static Future<void> refresh() async {
    _isInitialized = false;
    _cachedLockboxes = null;
    await initialize();
  }
}

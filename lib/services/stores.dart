import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction for key-value preferences storage (e.g., SharedPreferences)
abstract class PreferencesStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

/// Default implementation backed by SharedPreferences
class SharedPreferencesStore implements PreferencesStore {
  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  @override
  Future<String?> getString(String key) async {
    final prefs = await _prefs();
    return prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await _prefs();
    await prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await _prefs();
    await prefs.remove(key);
  }
}

/// Abstraction for secure key storage (e.g., FlutterSecureStorage)
abstract class SecureKeyStore {
  Future<void> write({required String key, required String? value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

/// Default implementation backed by FlutterSecureStorage
class FlutterSecureKeyStore implements SecureKeyStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<void> write({required String key, required String? value}) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }
}


import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper class for mocking Flutter Secure Storage in tests.
///
/// This class provides a simple way to set up and tear down secure storage
/// mocking across multiple test files. It maintains an in-memory Map to
/// simulate secure storage operations.
///
/// Usage:
/// ```dart
/// final secureStorageMock = SecureStorageMock();
///
/// setUpAll(() {
///   secureStorageMock.setUpAll();
/// });
///
/// tearDownAll(() {
///   secureStorageMock.tearDownAll();
/// });
///
/// setUp(() {
///   secureStorageMock.clear();
/// });
/// ```
class SecureStorageMock {
  static const MethodChannel _secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final Map<String, String> _store = {};

  /// Gets the in-memory store for direct access (e.g., for assertions)
  Map<String, String> get store => Map<String, String>.from(_store);

  /// Sets up the secure storage mock handler.
  ///
  /// Call this in setUpAll() to register the mock handler for all tests.
  void setUpAll() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, _handleMethodCall);
  }

  /// Tears down the secure storage mock handler.
  ///
  /// Call this in tearDownAll() to clean up the mock handler.
  void tearDownAll() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  }

  /// Clears the in-memory store.
  ///
  /// Call this in setUp() to reset the store before each test.
  void clear() {
    _store.clear();
  }

  /// Handles method calls from Flutter Secure Storage.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'write':
        final String key = (call.arguments as Map)['key'] as String;
        final String? value = (call.arguments as Map)['value'] as String?;
        if (value == null) {
          _store.remove(key);
        } else {
          _store[key] = value;
        }
        return null;
      case 'read':
        final String key = (call.arguments as Map)['key'] as String;
        return _store[key];
      case 'readAll':
        return Map<String, String>.from(_store);
      case 'delete':
        final String key = (call.arguments as Map)['key'] as String;
        _store.remove(key);
        return null;
      case 'deleteAll':
        _store.clear();
        return null;
      case 'containsKey':
        final String key = (call.arguments as Map)['key'] as String;
        return _store.containsKey(key);
      default:
        return null;
    }
  }
}

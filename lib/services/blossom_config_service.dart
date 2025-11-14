import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/blossom_server_config.dart';
import 'logger.dart';

/// Provider for BlossomConfigService
final blossomConfigServiceProvider = Provider<BlossomConfigService>((ref) {
  return BlossomConfigService();
});

/// Service for managing Blossom server configuration
class BlossomConfigService {
  static const String _configsKey = 'blossom_server_configs';

  /// Gets all configured Blossom servers
  Future<List<BlossomServerConfig>> getAllConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_configsKey);

    if (jsonData == null || jsonData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonData);
      return jsonList
          .map((json) => BlossomServerConfig.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Log.error('Error loading Blossom configs', e);
      return [];
    }
  }

  /// Gets the default Blossom server for file uploads
  Future<BlossomServerConfig?> getDefaultServer() async {
    final configs = await getAllConfigs();
    final defaults = configs.where((c) => c.isDefault).toList();

    if (defaults.isEmpty) {
      return null;
    }

    if (defaults.length > 1) {
      Log.error('Multiple default servers found, using first one');
    }

    return defaults.first;
  }

  /// Gets all enabled Blossom servers
  Future<List<BlossomServerConfig>> getEnabledServers() async {
    final configs = await getAllConfigs();
    final enabled = configs.where((c) => c.isEnabled).toList();

    // Sort: default first, then by name
    enabled.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return a.name.compareTo(b.name);
    });

    return enabled;
  }

  /// Adds a new Blossom server configuration
  Future<BlossomServerConfig> addServer({
    required String url,
    required String name,
    bool isDefault = false,
  }) async {
    // Validate URL
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw ArgumentError('URL must be valid HTTP or HTTPS');
      }
    } catch (e) {
      throw ArgumentError('Invalid URL format: $url');
    }

    // Remove trailing slash
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    // Check for duplicates
    final configs = await getAllConfigs();
    if (configs.any((c) => c.url == cleanUrl)) {
      throw ArgumentError('This server is already configured');
    }

    // Validate name
    if (name.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }

    // If setting as default, clear default flag on other servers
    if (isDefault) {
      for (final config in configs) {
        if (config.isDefault) {
          await updateServer(config.copyWith(isDefault: false));
        }
      }
    }

    final newConfig = BlossomServerConfig.create(
      url: cleanUrl,
      name: name.trim(),
      isDefault: isDefault,
    );

    configs.add(newConfig);
    await _saveConfigs(configs);

    Log.info('Added Blossom server: $name ($cleanUrl)');
    return newConfig;
  }

  /// Updates an existing Blossom server configuration
  Future<void> updateServer(BlossomServerConfig config) async {
    config.validate();

    final configs = await getAllConfigs();
    final index = configs.indexWhere((c) => c.id == config.id);

    if (index == -1) {
      throw ArgumentError('Server configuration not found: ${config.id}');
    }

    // If isDefault changed, handle default flag
    final oldConfig = configs[index];
    if (config.isDefault && !oldConfig.isDefault) {
      // Setting this as default, clear others
      for (final c in configs) {
        if (c.id != config.id && c.isDefault) {
          configs[configs.indexOf(c)] = c.copyWith(isDefault: false);
        }
      }
    }

    configs[index] = config;
    await _saveConfigs(configs);

    Log.info('Updated Blossom server: ${config.name}');
  }

  /// Deletes a Blossom server configuration
  Future<void> deleteServer(String id) async {
    final configs = await getAllConfigs();
    final config = configs.firstWhere(
      (c) => c.id == id,
      orElse: () => throw ArgumentError('Server configuration not found: $id'),
    );

    if (config.isDefault) {
      throw ArgumentError('Cannot delete default server. Set a different default first.');
    }

    configs.removeWhere((c) => c.id == id);
    await _saveConfigs(configs);

    Log.info('Deleted Blossom server: ${config.name}');
  }

  /// Sets a server as the default
  Future<void> setDefaultServer(String id) async {
    final configs = await getAllConfigs();
    final config = configs.firstWhere(
      (c) => c.id == id,
      orElse: () => throw ArgumentError('Server configuration not found: $id'),
    );

    // Clear default flag on all servers
    for (int i = 0; i < configs.length; i++) {
      if (configs[i].isDefault) {
        configs[i] = configs[i].copyWith(isDefault: false);
      }
    }

    // Set default flag on specified server
    final index = configs.indexWhere((c) => c.id == id);
    configs[index] = config.copyWith(isDefault: true);

    await _saveConfigs(configs);

    Log.info('Set default Blossom server: ${config.name}');
  }

  /// Tests connectivity to a Blossom server
  Future<bool> testConnection(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );

      // 200 or 404 both mean server is up
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      Log.debug('Connection test failed for $url: $e');
      return false;
    }
  }

  /// Initializes default Blossom servers for new users
  Future<void> initializeDefaults() async {
    final configs = await getAllConfigs();
    if (configs.isNotEmpty) {
      return; // Already initialized
    }

    // Add localhost server for development
    await addServer(
      url: 'http://localhost:10548',
      name: 'Local Blossom Server',
      isDefault: true,
    );

    Log.info('Initialized default Blossom server: localhost:10548');
  }

  /// Save configs to SharedPreferences
  Future<void> _saveConfigs(List<BlossomServerConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = configs.map((c) => c.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(_configsKey, jsonString);
  }
}

/// Exception thrown when connection times out
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}


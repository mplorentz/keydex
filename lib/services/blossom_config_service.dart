import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blossom_server_config.dart';
import 'logger.dart';

/// Manages Blossom server configuration
class BlossomConfigService {
  static const String _storageKey = 'blossom_server_configs';

  /// Gets all configured Blossom servers
  Future<List<BlossomServerConfig>> getAllConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      
      if (jsonStr == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonStr) as List;
      return jsonList
          .map((json) => BlossomServerConfig.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Log.error('Failed to load Blossom server configs', e);
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
      throw StateError('Multiple default Blossom servers found');
    }

    return defaults.first;
  }

  /// Gets all enabled Blossom servers
  Future<List<BlossomServerConfig>> getEnabledServers() async {
    final configs = await getAllConfigs();
    final enabled = configs.where((c) => c.isEnabled).toList();
    
    // Sort with default first
    enabled.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return 0;
    });

    return enabled;
  }

  /// Adds a new Blossom server configuration
  Future<BlossomServerConfig> addServer({
    required String url,
    required String name,
    bool isDefault = false,
  }) async {
    // Validate inputs
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      throw ArgumentError('URL must be HTTP or HTTPS');
    }
    if (url.endsWith('/')) {
      throw ArgumentError('URL must not end with trailing slash');
    }
    if (name.isEmpty) {
      throw ArgumentError('Server name cannot be empty');
    }

    // Check for duplicates
    final configs = await getAllConfigs();
    if (configs.any((c) => c.url == url)) {
      throw StateError('This server is already configured');
    }

    // Generate ID and create config
    final id = 'blossom-${DateTime.now().millisecondsSinceEpoch}';
    final config = BlossomServerConfig(
      id: id,
      url: url,
      name: name,
      isEnabled: true,
      isDefault: isDefault,
      lastUsed: null,
    );

    // If setting as default, clear others
    if (isDefault) {
      for (var i = 0; i < configs.length; i++) {
        configs[i] = configs[i].copyWith(isDefault: false);
      }
    }

    // Add new config
    configs.add(config);

    // Save
    await _saveConfigs(configs);
    Log.info('Added Blossom server: $name ($url)');

    return config;
  }

  /// Updates an existing Blossom server configuration
  Future<void> updateServer(BlossomServerConfig config) async {
    final configs = await getAllConfigs();
    final index = configs.indexWhere((c) => c.id == config.id);

    if (index == -1) {
      throw StateError('Server configuration not found');
    }

    // If changing to default, clear others
    if (config.isDefault) {
      for (var i = 0; i < configs.length; i++) {
        if (i != index) {
          configs[i] = configs[i].copyWith(isDefault: false);
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
      orElse: () => throw StateError('Server configuration not found'),
    );

    if (config.isDefault) {
      throw StateError('Cannot delete default server. Set a different default first.');
    }

    configs.removeWhere((c) => c.id == id);
    await _saveConfigs(configs);
    Log.info('Deleted Blossom server: ${config.name}');
  }

  /// Sets a server as the default
  Future<void> setDefaultServer(String id) async {
    final configs = await getAllConfigs();
    final index = configs.indexWhere((c) => c.id == id);

    if (index == -1) {
      throw StateError('Server configuration not found');
    }

    // Clear all defaults
    for (var i = 0; i < configs.length; i++) {
      configs[i] = configs[i].copyWith(isDefault: i == index);
    }

    await _saveConfigs(configs);
    Log.info('Set default Blossom server: ${configs[index].name}');
  }

  /// Tests connectivity to a Blossom server
  Future<bool> testConnection(String url) async {
    try {
      // TODO: Implement actual HTTP test once NDK provides Blossom API
      // For now, just validate URL format
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        return false;
      }
      
      // Simulate connectivity test
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      Log.error('Failed to test Blossom server connection: $url', e);
      return false;
    }
  }

  /// Initializes default Blossom servers for new users
  Future<void> initializeDefaults() async {
    final configs = await getAllConfigs();
    
    // Only initialize if no servers configured
    if (configs.isEmpty) {
      await addServer(
        url: 'http://localhost:10548',
        name: 'Local Blossom Server',
        isDefault: true,
      );
      Log.info('Initialized default Blossom server configuration');
    }
  }

  /// Updates the lastUsed timestamp for a server
  Future<void> markServerUsed(String url) async {
    final configs = await getAllConfigs();
    final index = configs.indexWhere((c) => c.url == url);

    if (index != -1) {
      configs[index] = configs[index].copyWith(lastUsed: DateTime.now());
      await _saveConfigs(configs);
    }
  }

  /// Internal: Save configs to SharedPreferences
  Future<void> _saveConfigs(List<BlossomServerConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = configs.map((c) => c.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    await prefs.setString(_storageKey, jsonStr);
  }
}


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/blossom_config_service.dart';
import '../models/blossom_server_config.dart';

/// Provider for BlossomConfigService
final blossomConfigServiceProvider = Provider<BlossomConfigService>((ref) {
  return BlossomConfigService();
});

/// Provider for all Blossom server configurations
final blossomConfigsProvider = FutureProvider<List<BlossomServerConfig>>((ref) async {
  final service = ref.watch(blossomConfigServiceProvider);
  return await service.getAllConfigs();
});

/// Provider for the default Blossom server
final defaultBlossomServerProvider = FutureProvider<BlossomServerConfig?>((ref) async {
  final service = ref.watch(blossomConfigServiceProvider);
  return await service.getDefaultServer();
});

/// Provider for enabled Blossom servers
final enabledBlossomServersProvider = FutureProvider<List<BlossomServerConfig>>((ref) async {
  final service = ref.watch(blossomConfigServiceProvider);
  return await service.getEnabledServers();
});


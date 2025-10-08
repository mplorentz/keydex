import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/relay_configuration.dart';
import '../services/relay_scan_service.dart';

/// FutureProvider for relay configurations list
final relayListProvider = FutureProvider<List<RelayConfiguration>>((ref) async {
  return await RelayScanService.getRelayConfigurations();
});

/// FutureProvider for enabled relays only
final enabledRelayListProvider = FutureProvider<List<RelayConfiguration>>((ref) async {
  return await RelayScanService.getRelayConfigurations(enabledOnly: true);
});

/// FutureProvider for scanning status
final scanningStatusProvider = FutureProvider<ScanningStatus>((ref) async {
  return await RelayScanService.getScanningStatus();
});

/// FutureProvider for whether scanning is active
final isScanningActiveProvider = FutureProvider<bool>((ref) async {
  return await RelayScanService.isScanningActive();
});

/// Provider for relay repository operations
final relayRepositoryProvider = Provider<RelayRepository>((ref) {
  return RelayRepository(ref);
});

/// Repository class to handle relay operations
class RelayRepository {
  final Ref _ref;

  RelayRepository(this._ref);

  /// Add a new relay configuration
  Future<void> addRelay(RelayConfiguration relay) async {
    await RelayScanService.addRelayConfiguration(relay);
    _refreshProviders();
  }

  /// Update an existing relay configuration
  Future<void> updateRelay(RelayConfiguration relay) async {
    await RelayScanService.updateRelayConfiguration(relay);
    _refreshProviders();
  }

  /// Remove a relay configuration
  Future<void> removeRelay(String relayId) async {
    await RelayScanService.removeRelayConfiguration(relayId);
    _refreshProviders();
  }

  /// Start relay scanning
  Future<void> startScanning({Duration? scanInterval}) async {
    await RelayScanService.startRelayScanning(scanInterval: scanInterval);
    _refreshProviders();
  }

  /// Stop relay scanning
  Future<void> stopScanning() async {
    await RelayScanService.stopRelayScanning();
    _refreshProviders();
  }

  /// Perform a manual scan
  Future<void> scanNow() async {
    await RelayScanService.scanNow();
    _refreshProviders();
  }

  /// Clear all relays (for testing/debugging)
  Future<void> clearAll() async {
    await RelayScanService.clearAll();
    _refreshProviders();
  }

  /// Refresh all providers after an operation
  void _refreshProviders() {
    _ref.invalidate(relayListProvider);
    _ref.invalidate(enabledRelayListProvider);
    _ref.invalidate(scanningStatusProvider);
    _ref.invalidate(isScanningActiveProvider);
  }
}

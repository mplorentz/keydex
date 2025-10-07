import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/relay_configuration.dart';
import 'ndk_service.dart';
import 'logger.dart';

/// Scanning status data class
class ScanningStatus {
  final bool isActive;
  final DateTime? lastScan;
  final int totalRelays;
  final int activeRelays;
  final int sharesFound;
  final int requestsFound;
  final String? lastError;

  const ScanningStatus({
    required this.isActive,
    this.lastScan,
    required this.totalRelays,
    required this.activeRelays,
    required this.sharesFound,
    required this.requestsFound,
    this.lastError,
  });

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'lastScan': lastScan?.toIso8601String(),
      'totalRelays': totalRelays,
      'activeRelays': activeRelays,
      'sharesFound': sharesFound,
      'requestsFound': requestsFound,
      'lastError': lastError,
    };
  }

  factory ScanningStatus.fromJson(Map<String, dynamic> json) {
    return ScanningStatus(
      isActive: json['isActive'] as bool,
      lastScan: json['lastScan'] != null ? DateTime.parse(json['lastScan'] as String) : null,
      totalRelays: json['totalRelays'] as int,
      activeRelays: json['activeRelays'] as int,
      sharesFound: json['sharesFound'] as int,
      requestsFound: json['requestsFound'] as int,
      lastError: json['lastError'] as String?,
    );
  }
}

/// Service for managing Nostr relay scanning and configuration
class RelayScanService {
  static const String _relayConfigsKey = 'relay_configurations';
  static const String _scanningStatusKey = 'scanning_status';
  static List<RelayConfiguration>? _cachedRelays;
  static bool _isInitialized = false;
  static bool _isScanning = false;
  static Timer? _scanTimer;
  static ScanningStatus? _scanningStatus;

  /// Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadRelayConfigurations();
      await _loadScanningStatus();
      _isInitialized = true;
      Log.info('RelayScanService initialized with ${_cachedRelays?.length ?? 0} relays');
    } catch (e) {
      Log.error('Error initializing RelayScanService', e);
      _cachedRelays = [];
      _isInitialized = true;
    }
  }

  /// Load relay configurations from storage
  static Future<void> _loadRelayConfigurations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_relayConfigsKey);

    if (jsonData == null || jsonData.isEmpty) {
      _cachedRelays = [];
      return;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonData);
      _cachedRelays = jsonList
          .map((json) => RelayConfiguration.fromJson(json as Map<String, dynamic>))
          .toList();
      Log.info('Loaded ${_cachedRelays!.length} relay configurations from storage');
    } catch (e) {
      Log.error('Error loading relay configurations', e);
      _cachedRelays = [];
    }
  }

  /// Save relay configurations to storage
  static Future<void> _saveRelayConfigurations() async {
    if (_cachedRelays == null) return;

    try {
      final jsonList = _cachedRelays!.map((relay) => relay.toJson()).toList();
      final jsonString = json.encode(jsonList);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_relayConfigsKey, jsonString);
      Log.info('Saved ${jsonList.length} relay configurations to storage');
    } catch (e) {
      Log.error('Error saving relay configurations', e);
      throw Exception('Failed to save relay configurations: $e');
    }
  }

  /// Load scanning status from storage
  static Future<void> _loadScanningStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_scanningStatusKey);

    if (jsonData == null || jsonData.isEmpty) {
      _scanningStatus = const ScanningStatus(
        isActive: false,
        totalRelays: 0,
        activeRelays: 0,
        sharesFound: 0,
        requestsFound: 0,
      );
      return;
    }

    try {
      final jsonMap = json.decode(jsonData) as Map<String, dynamic>;
      _scanningStatus = ScanningStatus.fromJson(jsonMap);
      Log.info('Loaded scanning status from storage');
    } catch (e) {
      Log.error('Error loading scanning status', e);
      _scanningStatus = const ScanningStatus(
        isActive: false,
        totalRelays: 0,
        activeRelays: 0,
        sharesFound: 0,
        requestsFound: 0,
      );
    }
  }

  /// Save scanning status to storage
  static Future<void> _saveScanningStatus() async {
    if (_scanningStatus == null) return;

    try {
      final jsonString = json.encode(_scanningStatus!.toJson());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_scanningStatusKey, jsonString);
      Log.info('Saved scanning status to storage');
    } catch (e) {
      Log.error('Error saving scanning status', e);
    }
  }

  /// Get all configured relays
  static Future<List<RelayConfiguration>> getRelayConfigurations({
    bool? enabledOnly,
  }) async {
    await initialize();

    var relays = List<RelayConfiguration>.from(_cachedRelays ?? []);

    // Filter by enabled status if requested
    if (enabledOnly == true) {
      relays = relays.where((r) => r.isEnabled).toList();
    }

    return relays;
  }

  /// Get a specific relay configuration by ID
  static Future<RelayConfiguration?> getRelayConfiguration(String relayId) async {
    await initialize();

    try {
      return _cachedRelays!.firstWhere((r) => r.id == relayId);
    } catch (e) {
      return null;
    }
  }

  /// Add a new relay configuration
  static Future<void> addRelayConfiguration(RelayConfiguration relay) async {
    await initialize();

    // Validate the relay configuration
    if (!relay.isValid) {
      throw ArgumentError('Invalid relay configuration');
    }

    // Check for duplicate URL
    final existingRelay = _cachedRelays!.where((r) => r.url == relay.url).firstOrNull;
    if (existingRelay != null) {
      throw ArgumentError('Relay with URL ${relay.url} already exists');
    }

    _cachedRelays!.add(relay);
    await _saveRelayConfigurations();

    Log.info('Added relay configuration: ${relay.name} (${relay.url})');

    // If the relay is enabled and we're scanning, add it to NDK immediately
    if (relay.isEnabled && _isScanning) {
      try {
        await NdkService.addRelay(relay.url);
        Log.info('Added relay to NDK real-time listening: ${relay.url}');
      } catch (e) {
        Log.error('Error adding relay to NDK', e);
      }
    }
  }

  /// Update an existing relay configuration
  static Future<void> updateRelayConfiguration(RelayConfiguration relay) async {
    await initialize();

    // Validate the relay configuration
    if (!relay.isValid) {
      throw ArgumentError('Invalid relay configuration');
    }

    final relayIndex = _cachedRelays!.indexWhere((r) => r.id == relay.id);
    if (relayIndex == -1) {
      throw ArgumentError('Relay configuration not found: ${relay.id}');
    }

    final oldRelay = _cachedRelays![relayIndex];
    _cachedRelays![relayIndex] = relay;
    await _saveRelayConfigurations();

    Log.info('Updated relay configuration: ${relay.name} (${relay.url})');

    // Update NDK if we're scanning
    if (_isScanning) {
      try {
        // If relay was disabled, remove from NDK
        if (!relay.isEnabled && oldRelay.isEnabled) {
          await NdkService.removeRelay(relay.url);
          Log.info('Removed disabled relay from NDK: ${relay.url}');
        }
        // If relay was enabled, add to NDK
        else if (relay.isEnabled && !oldRelay.isEnabled) {
          await NdkService.addRelay(relay.url);
          Log.info('Added enabled relay to NDK: ${relay.url}');
        }
      } catch (e) {
        Log.error('Error updating relay in NDK', e);
      }
    }
  }

  /// Remove a relay configuration
  static Future<void> removeRelayConfiguration(String relayId) async {
    await initialize();

    final relay = _cachedRelays!.firstWhere(
      (r) => r.id == relayId,
      orElse: () => throw ArgumentError('Relay configuration not found: $relayId'),
    );

    _cachedRelays!.removeWhere((r) => r.id == relayId);
    await _saveRelayConfigurations();

    Log.info('Removed relay configuration: $relayId');

    // Remove from NDK if we're scanning
    if (_isScanning && relay.isEnabled) {
      try {
        await NdkService.removeRelay(relay.url);
        Log.info('Removed relay from NDK: ${relay.url}');
      } catch (e) {
        Log.error('Error removing relay from NDK', e);
      }
    }
  }

  /// Start scanning relays for new shares and recovery requests
  static Future<void> startRelayScanning({Duration? scanInterval}) async {
    await initialize();

    if (_isScanning) {
      Log.info('Relay scanning is already active');
      return;
    }

    _isScanning = true;
    Log.info('Started relay scanning');

    // Initialize NDK for real-time listening
    try {
      await NdkService.initialize();
      Log.info('NDK initialized for relay scanning');

      // Add all enabled relays to NDK for real-time listening
      final enabledRelays = _cachedRelays!.where((r) => r.isEnabled).toList();
      for (final relay in enabledRelays) {
        await NdkService.addRelay(relay.url);
      }
      Log.info('Added ${enabledRelays.length} enabled relays to NDK');
    } catch (e) {
      Log.error('Error initializing NDK', e);
    }

    // Update scanning status
    _scanningStatus = ScanningStatus(
      isActive: true,
      lastScan: DateTime.now(),
      totalRelays: _cachedRelays!.length,
      activeRelays: _cachedRelays!.where((r) => r.isEnabled).length,
      sharesFound: _scanningStatus?.sharesFound ?? 0,
      requestsFound: _scanningStatus?.requestsFound ?? 0,
    );
    await _saveScanningStatus();

    // Set up periodic scanning (NDK handles real-time, this is for statistics/fallback)
    final interval = scanInterval ?? const Duration(minutes: 5);
    _scanTimer = Timer.periodic(interval, (timer) async {
      await _performScan();
    });

    // Perform initial scan
    await _performScan();
  }

  /// Stop scanning relays
  static Future<void> stopRelayScanning() async {
    await initialize();

    if (!_isScanning) {
      Log.info('Relay scanning is not active');
      return;
    }

    _isScanning = false;
    _scanTimer?.cancel();
    _scanTimer = null;

    // Stop NDK listening
    try {
      await NdkService.stopListening();
      Log.info('Stopped NDK listening');
    } catch (e) {
      Log.error('Error stopping NDK', e);
    }

    // Update scanning status
    _scanningStatus = ScanningStatus(
      isActive: false,
      lastScan: _scanningStatus?.lastScan,
      totalRelays: _cachedRelays!.length,
      activeRelays: 0,
      sharesFound: _scanningStatus?.sharesFound ?? 0,
      requestsFound: _scanningStatus?.requestsFound ?? 0,
    );
    await _saveScanningStatus();

    Log.info('Stopped relay scanning');
  }

  /// Check if scanning is currently active
  static Future<bool> isScanningActive() async {
    await initialize();
    return _isScanning;
  }

  /// Get scanning status and statistics
  static Future<ScanningStatus> getScanningStatus() async {
    await initialize();

    return _scanningStatus ??
        ScanningStatus(
          isActive: _isScanning,
          totalRelays: _cachedRelays!.length,
          activeRelays: _cachedRelays!.where((r) => r.isEnabled).length,
          sharesFound: 0,
          requestsFound: 0,
        );
  }

  /// Perform a scan of all enabled relays
  static Future<void> _performScan() async {
    Log.info('Performing relay scan (NDK handles real-time listening)...');

    final enabledRelays = _cachedRelays!.where((r) => r.isEnabled).toList();
    String? lastError;

    try {
      // Update last scanned timestamp for each relay
      for (final relay in enabledRelays) {
        if (!relay.shouldScan) continue;

        try {
          Log.info('Updating scan timestamp for relay: ${relay.name} (${relay.url})');

          // Update last scanned timestamp
          final updatedRelay = relay.copyWith(
            lastScanned: DateTime.now(),
          );

          // Update without triggering NDK changes
          final relayIndex = _cachedRelays!.indexWhere((r) => r.id == relay.id);
          if (relayIndex != -1) {
            _cachedRelays![relayIndex] = updatedRelay;
          }
        } catch (e) {
          Log.error('Error updating relay ${relay.name}', e);
          lastError = 'Error updating relay ${relay.name}: $e';
        }
      }

      // Save updated configurations
      await _saveRelayConfigurations();

      // NDK handles real-time event listening via subscriptions
      // This periodic scan just updates timestamps and maintains status
      final ndkRelays = NdkService.getActiveRelays();

      // Update scanning status
      _scanningStatus = ScanningStatus(
        isActive: _isScanning,
        lastScan: DateTime.now(),
        totalRelays: _cachedRelays!.length,
        activeRelays: ndkRelays.length,
        sharesFound: _scanningStatus?.sharesFound ?? 0,
        requestsFound: _scanningStatus?.requestsFound ?? 0,
        lastError: lastError,
      );
      await _saveScanningStatus();

      Log.info('Relay scan complete. NDK listening on ${ndkRelays.length} relays');
    } catch (e) {
      Log.error('Error during relay scan', e);

      _scanningStatus = ScanningStatus(
        isActive: _isScanning,
        lastScan: DateTime.now(),
        totalRelays: _cachedRelays!.length,
        activeRelays: enabledRelays.length,
        sharesFound: _scanningStatus?.sharesFound ?? 0,
        requestsFound: _scanningStatus?.requestsFound ?? 0,
        lastError: 'Scan failed: $e',
      );
      await _saveScanningStatus();
    }
  }

  /// Manually trigger a scan of all enabled relays
  static Future<void> scanNow() async {
    await initialize();
    await _performScan();
  }

  /// Clear all relay configurations (for testing)
  static Future<void> clearAll() async {
    _cachedRelays = [];
    _scanningStatus = null;
    _isScanning = false;
    _scanTimer?.cancel();
    _scanTimer = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_relayConfigsKey);
    await prefs.remove(_scanningStatusKey);
    _isInitialized = false;

    Log.info('Cleared all relay configurations and scanning status');
  }

  /// Refresh the cached data from storage
  static Future<void> refresh() async {
    _isInitialized = false;
    _cachedRelays = null;
    _scanningStatus = null;
    await initialize();
  }
}

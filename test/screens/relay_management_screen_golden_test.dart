import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/relay_configuration.dart';
import 'package:horcrux/screens/relay_management_screen.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/relay_scan_service.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Sample test data
  final relay1 = RelayConfiguration(
    id: 'relay-1',
    url: 'wss://relay1.example.com',
    name: 'Example Relay 1',
    isEnabled: true,
    isTrusted: false,
    lastScanned: DateTime(2024, 10, 1, 10, 30),
  );

  final relay2 = RelayConfiguration(
    id: 'relay-2',
    url: 'wss://relay2.example.com',
    name: 'Trusted Relay',
    isEnabled: true,
    isTrusted: true,
    lastScanned: DateTime(2024, 10, 1, 9, 15),
  );

  final relay3 = RelayConfiguration(
    id: 'relay-3',
    url: 'wss://relay3.example.com',
    name: 'Disabled Relay',
    isEnabled: false,
    isTrusted: false,
    lastScanned: DateTime(2024, 9, 30, 14, 20),
  );

  final multipleRelays = [relay1, relay2, relay3];

  group('RelayManagementScreen Golden Tests', () {
    testGoldens('loading state', (tester) async {
      final container = ProviderContainer();
      final mockService = _MockRelayScanService(
        relays: null,
        scanningStatus: null,
        isScanning: null,
        neverCompletes: true,
        container: container,
      );

      final testContainer = ProviderContainer(
        parent: container,
        overrides: [
          relayScanServiceProvider.overrideWith((ref) => mockService),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RelayManagementScreen(),
        container: testContainer,
        waitForSettle: false, // Loading state
      );

      await screenMatchesGoldenWithoutSettle<RelayManagementScreen>(
        tester,
        'relay_management_screen_loading',
      );

      testContainer.dispose();
      container.dispose();
    });

    testGoldens('empty state - no relays', (tester) async {
      final container = ProviderContainer();
      final mockService = _MockRelayScanService(
        relays: [],
        scanningStatus: const ScanningStatus(
          isActive: false,
          totalRelays: 0,
          activeRelays: 0,
          sharesFound: 0,
          requestsFound: 0,
        ),
        isScanning: false,
        container: container,
      );

      final testContainer = ProviderContainer(
        parent: container,
        overrides: [
          relayScanServiceProvider.overrideWith((ref) => mockService),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RelayManagementScreen(),
        container: testContainer,
      );

      await screenMatchesGolden(tester, 'relay_management_screen_empty');

      testContainer.dispose();
      container.dispose();
    });

    testGoldens('with single enabled relay', (tester) async {
      final container = ProviderContainer();
      final mockService = _MockRelayScanService(
        relays: [relay1],
        scanningStatus: ScanningStatus(
          isActive: true,
          lastScan: DateTime(2024, 10, 1, 10, 30),
          totalRelays: 1,
          activeRelays: 1,
          sharesFound: 0,
          requestsFound: 0,
        ),
        isScanning: true,
        container: container,
      );

      final testContainer = ProviderContainer(
        parent: container,
        overrides: [
          relayScanServiceProvider.overrideWith((ref) => mockService),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RelayManagementScreen(),
        container: testContainer,
      );

      await screenMatchesGolden(
        tester,
        'relay_management_screen_single_relay',
      );

      testContainer.dispose();
      container.dispose();
    });

    testGoldens('with multiple relays - mixed states', (tester) async {
      final container = ProviderContainer();
      final mockService = _MockRelayScanService(
        relays: multipleRelays,
        scanningStatus: ScanningStatus(
          isActive: true,
          lastScan: DateTime(2024, 10, 1, 10, 30),
          totalRelays: 3,
          activeRelays: 2,
          sharesFound: 5,
          requestsFound: 2,
        ),
        isScanning: true,
        container: container,
      );

      final testContainer = ProviderContainer(
        parent: container,
        overrides: [
          relayScanServiceProvider.overrideWith((ref) => mockService),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RelayManagementScreen(),
        container: testContainer,
        surfaceSize: const Size(375, 1000), // Taller to show all relays
      );

      await screenMatchesGolden(
        tester,
        'relay_management_screen_multiple_relays',
      );

      testContainer.dispose();
      container.dispose();
    });

    testGoldens('scanning stopped state', (tester) async {
      final container = ProviderContainer();
      final mockService = _MockRelayScanService(
        relays: [relay1, relay2],
        scanningStatus: ScanningStatus(
          isActive: false,
          lastScan: DateTime(2024, 10, 1, 8, 0),
          totalRelays: 2,
          activeRelays: 0,
          sharesFound: 3,
          requestsFound: 1,
        ),
        isScanning: false,
        container: container,
      );

      final testContainer = ProviderContainer(
        parent: container,
        overrides: [
          relayScanServiceProvider.overrideWith((ref) => mockService),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RelayManagementScreen(),
        container: testContainer,
      );

      await screenMatchesGolden(
        tester,
        'relay_management_screen_scanning_stopped',
      );

      testContainer.dispose();
      container.dispose();
    });

    testGoldens('with scanning status error', (tester) async {
      final container = ProviderContainer();
      final mockService = _MockRelayScanService(
        relays: [relay1],
        scanningStatus: ScanningStatus(
          isActive: true,
          lastScan: DateTime(2024, 10, 1, 10, 30),
          totalRelays: 1,
          activeRelays: 1,
          sharesFound: 0,
          requestsFound: 0,
          lastError: 'Connection timeout',
        ),
        isScanning: true,
        container: container,
      );

      final testContainer = ProviderContainer(
        parent: container,
        overrides: [
          relayScanServiceProvider.overrideWith((ref) => mockService),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const RelayManagementScreen(),
        container: testContainer,
      );

      await screenMatchesGolden(
        tester,
        'relay_management_screen_with_error',
      );

      testContainer.dispose();
      container.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final container = ProviderContainer();
      final mockService = _MockRelayScanService(
        relays: multipleRelays,
        scanningStatus: ScanningStatus(
          isActive: true,
          lastScan: DateTime(2024, 10, 1, 10, 30),
          totalRelays: 3,
          activeRelays: 2,
          sharesFound: 5,
          requestsFound: 2,
        ),
        isScanning: true,
        container: container,
      );

      final testContainer = ProviderContainer(
        parent: container,
        overrides: [
          relayScanServiceProvider.overrideWith((ref) => mockService),
        ],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(
          widget: const RelayManagementScreen(),
          name: 'multiple_relays',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: testContainer,
        ),
      );

      await screenMatchesGolden(
        tester,
        'relay_management_screen_multiple_devices',
      );

      testContainer.dispose();
      container.dispose();
    });
  });
}

/// Mock RelayScanService for testing
class _MockRelayScanService extends RelayScanService {
  final List<RelayConfiguration>? _relays;
  final ScanningStatus? _scanningStatus;
  final bool? _isScanning;
  final bool _neverCompletes;

  _MockRelayScanService({
    required List<RelayConfiguration>? relays,
    required ScanningStatus? scanningStatus,
    required bool? isScanning,
    bool neverCompletes = false,
    required ProviderContainer container,
  })  : _relays = relays,
        _scanningStatus = scanningStatus,
        _isScanning = isScanning,
        _neverCompletes = neverCompletes,
        super(ndkService: _MockNdkService(container));

  @override
  Future<List<RelayConfiguration>> getRelayConfigurations({
    bool? enabledOnly,
  }) async {
    if (_neverCompletes) {
      // Use a Completer that never completes to simulate loading state
      final completer = Completer<List<RelayConfiguration>>();
      return completer.future; // This will never complete
    }
    final relays = _relays ?? [];
    if (enabledOnly == true) {
      return relays.where((r) => r.isEnabled).toList();
    }
    return relays;
  }

  @override
  Future<ScanningStatus> getScanningStatus() async {
    if (_neverCompletes) {
      final completer = Completer<ScanningStatus>();
      return completer.future; // This will never complete
    }
    return _scanningStatus ??
        const ScanningStatus(
          isActive: false,
          totalRelays: 0,
          activeRelays: 0,
          sharesFound: 0,
          requestsFound: 0,
        );
  }

  @override
  Future<bool> isScanningActive() async {
    if (_neverCompletes) {
      final completer = Completer<bool>();
      return completer.future; // This will never complete
    }
    return _isScanning ?? false;
  }

  @override
  Future<void> addRelayConfiguration(RelayConfiguration relay) async {
    // Mock implementation - no-op for testing
  }

  @override
  Future<void> updateRelayConfiguration(RelayConfiguration relay) async {
    // Mock implementation - no-op for testing
  }

  @override
  Future<void> removeRelayConfiguration(String relayId) async {
    // Mock implementation - no-op for testing
  }

  @override
  Future<void> startRelayScanning({Duration? scanInterval}) async {
    // Mock implementation - no-op for testing
  }

  @override
  Future<void> stopRelayScanning() async {
    // Mock implementation - no-op for testing
  }

  @override
  Future<void> scanNow() async {
    // Mock implementation - no-op for testing
  }
}

/// Mock Ref for NdkService - implements only methods actually used
class _MockRef implements Ref {
  final ProviderContainer _container;

  _MockRef(this._container);

  @override
  T read<T>(ProviderListenable<T> provider) => _container.read(provider);

  @override
  T watch<T>(ProviderListenable<T> provider) => _container.read(provider);

  @override
  ProviderContainer get container => _container;

  @override
  bool exists(ProviderBase<Object?> provider) => _container.exists(provider);

  @override
  KeepAliveLink keepAlive() {
    // Not used by NdkService, return a no-op link
    return _NoOpKeepAliveLink();
  }

  @override
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) =>
      _container.listen(provider, listener, onError: onError, fireImmediately: fireImmediately);

  @override
  void listenSelf(
    void Function(Object?, Object?) cb, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    // Not used by NdkService, no-op
  }

  @override
  void notifyListeners() {
    // Not used by NdkService, no-op
  }

  @override
  void onAddListener(void Function() cb) {
    // Not used by NdkService, no-op
  }

  @override
  void onCancel(void Function() cb) {
    // Not used by NdkService, no-op
  }

  @override
  void onRemoveListener(void Function() cb) {
    // Not used by NdkService, no-op
  }

  @override
  void onResume(void Function() cb) {
    // Not used by NdkService, no-op
  }

  @override
  T refresh<T>(Refreshable<T> provider) => _container.refresh(provider);

  @override
  void invalidate(ProviderOrFamily provider) => _container.invalidate(provider);

  @override
  void invalidateSelf() {
    // Not used by NdkService, no-op
  }

  @override
  Ref onDispose(void Function() callback) {
    // Not used by NdkService, return this
    return this;
  }
}

/// No-op KeepAliveLink for testing
class _NoOpKeepAliveLink implements KeepAliveLink {
  @override
  void close() {
    // No-op
  }
}

/// Mock NdkService for testing
class _MockNdkService extends NdkService {
  _MockNdkService(ProviderContainer container)
      : super(
          ref: _MockRef(container),
          loginService: _MockLoginService(),
          getInvitationService: () => throw UnimplementedError(),
        );

  @override
  Future<void> initialize() async {
    // Mock implementation - no-op for testing
  }

  @override
  Future<void> dispose() async {
    // Mock implementation - no-op for testing
  }

  @override
  List<String> getActiveRelays() => [];

  @override
  Future<void> addRelay(String url) async {
    // Mock implementation - no-op for testing
  }

  @override
  Future<void> removeRelay(String url) async {
    // Mock implementation - no-op for testing
  }

  @override
  Future<void> stopListening() async {
    // Mock implementation - no-op for testing
  }
}

/// Mock LoginService for testing
class _MockLoginService extends LoginService {
  _MockLoginService() : super();
}

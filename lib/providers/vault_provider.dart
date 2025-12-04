import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vault.dart';
import '../models/shard_data.dart';
import '../models/recovery_request.dart';
import '../models/backup_config.dart';
import '../models/steward.dart';
import '../models/steward_status.dart';
import '../services/login_service.dart';
import '../services/logger.dart';
import 'key_provider.dart';

/// Stream provider that automatically subscribes to vault changes
/// This will emit a new list whenever vaultes are added, updated, or deleted
final vaultListProvider = StreamProvider.autoDispose<List<Vault>>((ref) {
  final repository = ref.watch(vaultRepositoryProvider);

  // Return the stream directly and let Riverpod handle the subscription
  return Stream.multi((controller) async {
    // First, load and emit initial data
    try {
      final initialVaultes = await repository.getAllVaultes();
      controller.add(initialVaultes);
    } catch (e) {
      Log.error('Error loading initial vaultes', e);
      controller.addError(e);
    }

    // Then listen to the repository stream for updates
    final subscription = repository.vaultesStream.listen(
      (vaultes) {
        controller.add(vaultes);
      },
      onError: (error) {
        Log.error('Error in vaultesStream', error);
        controller.addError(error);
      },
      onDone: () {
        controller.close();
      },
    );

    // Clean up when the provider is disposed
    controller.onCancel = () {
      subscription.cancel();
    };
  });
});

/// Provider for a specific vault by ID
/// This will automatically update when the vault changes
final vaultProvider = StreamProvider.family<Vault?, String>((
  ref,
  vaultId,
) {
  final repository = ref.watch(vaultRepositoryProvider);

  // Return a stream that:
  // 1. Loads initial data
  // 2. Subscribes to updates from the repository stream
  return Stream.multi((controller) async {
    // First, load and emit initial vault
    try {
      final initialVault = await repository.getVault(vaultId);
      controller.add(initialVault);
    } catch (e) {
      Log.error('Error loading initial vault', e);
      controller.addError(e);
    }

    // Then listen to the repository stream for updates
    final subscription = repository.vaultesStream.listen(
      (vaultes) {
        try {
          final vault = vaultes.firstWhere((box) => box.id == vaultId);
          controller.add(vault);
        } catch (e) {
          // Vault not found in the list (might have been deleted)
          controller.add(null);
        }
      },
      onError: (error) {
        Log.error('Error in vaultesStream for $vaultId', error);
        controller.addError(error);
      },
      onDone: () {
        controller.close();
      },
    );

    // Clean up when the provider is disposed
    controller.onCancel = () {
      subscription.cancel();
    };
  });
});

/// Provider for vault repository operations
/// Riverpod automatically ensures this is a singleton - only one instance exists
/// per ProviderScope. The instance is kept alive for the lifetime of the app.
final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final repository = VaultRepository(ref.read(loginServiceProvider));

  // Properly clean up when the app is disposed
  ref.onDispose(() {
    repository.dispose();
  });

  return repository;
});

/// Repository class to handle vault operations
/// This provides a clean API layer between the UI and the service
class VaultRepository {
  final LoginService _loginService;
  static const String _vaultesKey = 'encrypted_vaultes';
  List<Vault>? _cachedVaultes;
  bool _isInitialized = false;

  // Stream controller for notifying listeners when vaultes change
  final StreamController<List<Vault>> _vaultesController =
      StreamController<List<Vault>>.broadcast();

  // Regular constructor - Riverpod manages the singleton behavior
  VaultRepository(this._loginService);

  /// Stream that emits the updated list of vaultes whenever they change
  Stream<List<Vault>> get vaultesStream => _vaultesController.stream;

  /// Initialize the storage and load existing vaultes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadVaultes();
      _isInitialized = true;
    } catch (e) {
      Log.error('Error initializing VaultRepository', e);
      _cachedVaultes = [];
      _isInitialized = true;
    }
  }

  /// Load vaultes from SharedPreferences and decrypt them
  Future<void> _loadVaultes() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(_vaultesKey);
    Log.info('Loading encrypted vaultes from SharedPreferences');

    if (encryptedData == null || encryptedData.isEmpty) {
      _cachedVaultes = [];
      Log.info('No encrypted vaultes found in SharedPreferences');
      return;
    }

    try {
      // Decrypt the data using our Nostr key
      final decryptedJson = await _loginService.decryptText(encryptedData);
      final List<dynamic> jsonList = json.decode(decryptedJson);
      Log.info('Decrypted ${jsonList.length} vaultes');

      _cachedVaultes =
          jsonList.map((json) => Vault.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      Log.error('Error decrypting vaultes', e);
      _cachedVaultes = [];
    }
  }

  /// Save vaultes to SharedPreferences with encryption
  Future<void> _saveVaultes() async {
    if (_cachedVaultes == null) return;

    try {
      Log.debug('Starting to save ${_cachedVaultes!.length} vaultes');

      // Convert to JSON with detailed error tracking
      final jsonList = <Map<String, dynamic>>[];
      for (var i = 0; i < _cachedVaultes!.length; i++) {
        final vault = _cachedVaultes![i];
        Log.debug('Converting vault $i (id: ${vault.id}) to JSON');
        Log.debug('  - Name: ${vault.name}');
        Log.debug('  - Owner: ${vault.ownerPubkey}');
        Log.debug('  - Shards count: ${vault.shards.length}');
        Log.debug(
          '  - Recovery requests count: ${vault.recoveryRequests.length}',
        );

        try {
          final vaultJson = vault.toJson();
          jsonList.add(vaultJson);
          Log.debug('  ✓ Vault $i converted successfully');
        } catch (e) {
          Log.error('  ✗ Error converting vault $i to JSON', e);

          // Try to identify which recovery request is causing the issue
          for (var j = 0; j < vault.recoveryRequests.length; j++) {
            final request = vault.recoveryRequests[j];
            Log.debug(
              '    - Recovery request $j: id=${request.id}, status=${request.status.name}',
            );
            Log.debug(
              '      stewardResponses count: ${request.stewardResponses.length}',
            );

            // Check each response
            for (var entry in request.stewardResponses.entries) {
              final pubkey = entry.key;
              final response = entry.value;
              Log.debug(
                '        Response from ${pubkey.substring(0, 8)}: approved=${response.approved}, shardData=${response.shardData != null ? "present" : "null"}',
              );

              if (response.shardData != null) {
                final shard = response.shardData!;
                Log.debug('          ShardData details:');
                Log.debug('            shard type: ${shard.shard.runtimeType}');
                Log.debug(
                  '            threshold type: ${shard.threshold.runtimeType}',
                );
                Log.debug(
                  '            shardIndex type: ${shard.shardIndex.runtimeType}',
                );
                Log.debug(
                  '            totalShards type: ${shard.totalShards.runtimeType}',
                );
                Log.debug(
                  '            primeMod type: ${shard.primeMod.runtimeType}',
                );
                Log.debug(
                  '            creatorPubkey type: ${shard.creatorPubkey.runtimeType}',
                );
                Log.debug(
                  '            createdAt type: ${shard.createdAt.runtimeType}',
                );
                Log.debug(
                  '            vaultId: ${shard.vaultId} (type: ${shard.vaultId?.runtimeType})',
                );
                Log.debug(
                  '            vaultName: ${shard.vaultName} (type: ${shard.vaultName?.runtimeType})',
                );
                Log.debug(
                  '            peers: ${shard.peers} (type: ${shard.peers?.runtimeType})',
                );
                Log.debug(
                  '            recipientPubkey: ${shard.recipientPubkey} (type: ${shard.recipientPubkey?.runtimeType})',
                );
                Log.debug(
                  '            nostrEventId: ${shard.nostrEventId} (type: ${shard.nostrEventId?.runtimeType})',
                );
              }
            }
          }
          rethrow;
        }
      }

      Log.debug('All vaultes converted to JSON, encoding...');
      final jsonString = json.encode(jsonList);
      Log.debug('JSON encoded successfully (${jsonString.length} characters)');

      // Encrypt the JSON data using our Nostr key
      final encryptedData = await _loginService.encryptText(jsonString);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_vaultesKey, encryptedData);
      Log.info(
        'Saved ${jsonList.length} encrypted vaultes to SharedPreferences',
      );

      // Notify listeners that vaultes have changed
      final vaultesList = List<Vault>.unmodifiable(_cachedVaultes!);
      _vaultesController.add(vaultesList);
    } catch (e) {
      Log.error('Error encrypting and saving vaultes', e);
      throw Exception('Failed to save vaultes: $e');
    }
  }

  /// Get all vaultes
  Future<List<Vault>> getAllVaultes() async {
    await initialize();
    return List.unmodifiable(_cachedVaultes ?? []);
  }

  /// Get a specific vault by ID
  Future<Vault?> getVault(String id) async {
    await initialize();
    try {
      return _cachedVaultes!.firstWhere((lb) => lb.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Save a vault (add new or update existing)
  Future<void> saveVault(Vault vault) async {
    await initialize();

    final index = _cachedVaultes!.indexWhere((lb) => lb.id == vault.id);
    if (index == -1) {
      // Add new vault
      _cachedVaultes!.add(vault);
    } else {
      // Update existing vault
      _cachedVaultes![index] = vault;
    }

    await _saveVaultes();
  }

  /// Add a new vault
  Future<void> addVault(Vault vault) async {
    await initialize();
    _cachedVaultes!.add(vault);
    await _saveVaultes();
  }

  /// Update an existing vault
  Future<void> updateVault(String id, String name, String content) async {
    await initialize();
    final index = _cachedVaultes!.indexWhere((lb) => lb.id == id);
    if (index != -1) {
      final existingVault = _cachedVaultes![index];
      _cachedVaultes![index] = existingVault.copyWith(
        name: name,
        content: content,
      );
      await _saveVaultes();
    }
  }

  /// Delete a vault
  Future<void> deleteVault(String id) async {
    await initialize();
    _cachedVaultes!.removeWhere((lb) => lb.id == id);
    await _saveVaultes();
  }

  /// Clear all vaultes (for testing/debugging)
  Future<void> clearAll() async {
    _cachedVaultes = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vaultesKey);
    _isInitialized = false;
  }

  /// Refresh vaultes from storage
  Future<void> refresh() async {
    _isInitialized = false;
    _cachedVaultes = null;
    await initialize();
  }

  // ========== Backup Config Operations ==========

  /// Update backup configuration for a vault
  Future<void> updateBackupConfig(String vaultId, BackupConfig config) async {
    await initialize();

    final index = _cachedVaultes!.indexWhere((lb) => lb.id == vaultId);
    if (index == -1) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    final vault = _cachedVaultes![index];
    _cachedVaultes![index] = vault.copyWith(backupConfig: config);
    await _saveVaultes();
    Log.info('Updated backup configuration for vault $vaultId');
  }

  /// Get backup configuration for a vault
  Future<BackupConfig?> getBackupConfig(String vaultId) async {
    await initialize();

    final vault = _cachedVaultes!.firstWhere(
      (lb) => lb.id == vaultId,
      orElse: () => throw ArgumentError('Vault not found: $vaultId'),
    );

    return vault.backupConfig;
  }

  /// Update steward status in backup configuration
  /// This is the single source of truth for steward status updates
  Future<void> updateStewardStatus({
    required String vaultId,
    required String pubkey, // Hex format
    required StewardStatus status,
    DateTime? acknowledgedAt,
    String? acknowledgmentEventId,
    int? acknowledgedDistributionVersion,
  }) async {
    await initialize();

    final vault = _cachedVaultes!.firstWhere(
      (lb) => lb.id == vaultId,
      orElse: () => throw ArgumentError('Vault not found: $vaultId'),
    );

    final backupConfig = vault.backupConfig;
    if (backupConfig == null) {
      throw ArgumentError('Vault $vaultId has no backup configuration');
    }

    // Find and update the steward
    final stewardIndex = backupConfig.stewards.indexWhere(
      (h) => h.pubkey == pubkey,
    );
    if (stewardIndex == -1) {
      throw ArgumentError('Steward $pubkey not found in vault $vaultId');
    }

    final updatedStewards = List<Steward>.from(backupConfig.stewards);
    updatedStewards[stewardIndex] = copySteward(
      updatedStewards[stewardIndex],
      status: status,
      acknowledgedAt: acknowledgedAt,
      acknowledgmentEventId: acknowledgmentEventId,
      acknowledgedDistributionVersion: acknowledgedDistributionVersion,
    );

    final updatedConfig = copyBackupConfig(
      backupConfig,
      stewards: updatedStewards,
    );
    await updateBackupConfig(vaultId, updatedConfig);

    Log.info(
      'Updated steward $pubkey status to $status in vault $vaultId',
    );
  }

  // ========== Shard Management Methods ==========

  /// Add a shard to a vault (supports multiple shards during recovery)
  Future<void> addShardToVault(String vaultId, ShardData shard) async {
    await initialize();

    final index = _cachedVaultes!.indexWhere((lb) => lb.id == vaultId);
    if (index == -1) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    final vault = _cachedVaultes![index];
    final updatedShards = List<ShardData>.from(vault.shards)..add(shard);

    _cachedVaultes![index] = vault.copyWith(shards: updatedShards);
    await _saveVaultes();
    Log.info(
      'Added shard to vault $vaultId (total shards: ${updatedShards.length})',
    );
  }

  /// Get all shards for a vault
  Future<List<ShardData>> getShardsForVault(String vaultId) async {
    await initialize();

    final vault = _cachedVaultes!.firstWhere(
      (lb) => lb.id == vaultId,
      orElse: () => throw ArgumentError('Vault not found: $vaultId'),
    );

    return List.unmodifiable(vault.shards);
  }

  /// Clear all shards for a vault
  Future<void> clearShardsForVault(String vaultId) async {
    await initialize();

    final index = _cachedVaultes!.indexWhere((lb) => lb.id == vaultId);
    if (index == -1) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    _cachedVaultes![index] = _cachedVaultes![index].copyWith(shards: []);
    await _saveVaultes();
    Log.info('Cleared all shards for vault $vaultId');
  }

  /// Check if we are a steward for a vault (have any shards)
  Future<bool> isKeyHolderForVault(String vaultId) async {
    await initialize();

    final vault = _cachedVaultes!.firstWhere(
      (lb) => lb.id == vaultId,
      orElse: () => throw ArgumentError('Vault not found: $vaultId'),
    );

    return vault.isSteward;
  }

  // ========== Recovery Request Management Methods ==========

  /// Add a recovery request to a vault
  Future<void> addRecoveryRequestToVault(
    String vaultId,
    RecoveryRequest request,
  ) async {
    await initialize();

    final index = _cachedVaultes!.indexWhere((lb) => lb.id == vaultId);
    if (index == -1) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    final vault = _cachedVaultes![index];
    final updatedRequests = List<RecoveryRequest>.from(vault.recoveryRequests)..add(request);

    _cachedVaultes![index] = vault.copyWith(
      recoveryRequests: updatedRequests,
    );
    await _saveVaultes();
    Log.info('Added recovery request ${request.id} to vault $vaultId');
  }

  /// Update a recovery request in a vault
  Future<void> updateRecoveryRequestInVault(
    String vaultId,
    String requestId,
    RecoveryRequest updatedRequest,
  ) async {
    await initialize();

    final index = _cachedVaultes!.indexWhere((lb) => lb.id == vaultId);
    if (index == -1) {
      throw ArgumentError('Vault not found: $vaultId');
    }

    final vault = _cachedVaultes![index];
    final requestIndex = vault.recoveryRequests.indexWhere(
      (r) => r.id == requestId,
    );

    if (requestIndex == -1) {
      throw ArgumentError('Recovery request not found: $requestId');
    }

    final updatedRequests = List<RecoveryRequest>.from(
      vault.recoveryRequests,
    );
    updatedRequests[requestIndex] = updatedRequest;

    _cachedVaultes![index] = vault.copyWith(
      recoveryRequests: updatedRequests,
    );
    await _saveVaultes();
    Log.info('Updated recovery request $requestId in vault $vaultId');
  }

  /// Get all recovery requests for a vault
  Future<List<RecoveryRequest>> getRecoveryRequestsForVault(
    String vaultId,
  ) async {
    await initialize();

    final vault = _cachedVaultes!.firstWhere(
      (lb) => lb.id == vaultId,
      orElse: () => throw ArgumentError('Vault not found: $vaultId'),
    );

    return List.unmodifiable(vault.recoveryRequests);
  }

  /// Get the active recovery request for a vault (if any)
  Future<RecoveryRequest?> getActiveRecoveryRequest(String vaultId) async {
    await initialize();

    final vault = _cachedVaultes!.firstWhere(
      (lb) => lb.id == vaultId,
      orElse: () => throw ArgumentError('Vault not found: $vaultId'),
    );

    return vault.activeRecoveryRequest;
  }

  /// Get all recovery requests across all vaultes
  Future<List<RecoveryRequest>> getAllRecoveryRequests() async {
    await initialize();

    final allRequests = <RecoveryRequest>[];
    for (final vault in _cachedVaultes!) {
      allRequests.addAll(vault.recoveryRequests);
    }

    return allRequests;
  }

  /// Dispose resources
  void dispose() {
    _vaultesController.close();
  }
}

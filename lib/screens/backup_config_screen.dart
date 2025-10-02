import 'package:flutter/material.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/key_holder.dart';
import '../services/backup_service.dart';
import '../services/shard_distribution_service.dart';
import '../services/key_service.dart';
import '../services/lockbox_service.dart';
import 'package:ndk/ndk.dart';

/// Backup configuration screen for setting up distributed backup
///
/// This screen allows users to configure backup settings including:
/// - Threshold and total number of keys
/// - Key holders (trusted contacts)
/// - Nostr relay selection
///
/// Note: Requires a valid lockboxId to load the lockbox content for backup
class BackupConfigScreen extends StatefulWidget {
  final String lockboxId;

  const BackupConfigScreen({super.key, required this.lockboxId});

  @override
  State<BackupConfigScreen> createState() => _BackupConfigScreenState();
}

class _BackupConfigScreenState extends State<BackupConfigScreen> {
  int _threshold = 2;
  int _totalKeys = 3;
  final List<KeyHolder> _keyHolders = [];
  final List<String> _relays = ['wss://relay.damus.io'];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Configuration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Threshold and Total Keys Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup Settings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text('Threshold: $_threshold (minimum keys needed)'),
                    Slider(
                      value: _threshold.toDouble(),
                      min: 2,
                      max: _totalKeys.toDouble(),
                      divisions: _totalKeys - 2,
                      onChanged: (value) {
                        setState(() {
                          _threshold = value.round();
                        });
                      },
                    ),
                    Text('Total Keys: $_totalKeys'),
                    Slider(
                      value: _totalKeys.toDouble(),
                      min: _threshold.toDouble(),
                      max: 10,
                      divisions: 10 - _threshold,
                      onChanged: (value) {
                        setState(() {
                          _totalKeys = value.round();
                          if (_threshold > _totalKeys) {
                            _threshold = _totalKeys;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Key Holders Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Key Holders (${_keyHolders.length}/$_totalKeys)',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        ElevatedButton.icon(
                          onPressed: _addKeyHolder,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Contact'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_keyHolders.isEmpty)
                      const Text(
                          'No key holders added yet. Add trusted contacts to distribute backup keys.')
                    else
                      ..._keyHolders.map((holder) => ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(holder.displayName),
                            subtitle: Text(holder.npub),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle),
                              onPressed: () {
                                setState(() {
                                  _keyHolders.remove(holder);
                                });
                              },
                            ),
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Relay Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nostr Relays',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ..._relays.map((relay) => ListTile(
                          leading: const Icon(Icons.cloud),
                          title: Text(relay),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () {
                              if (_relays.length > 1) {
                                setState(() {
                                  _relays.remove(relay);
                                });
                              }
                            },
                          ),
                        )),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement add relay functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Add relay - TODO')),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Relay'),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canCreateBackup() && !_isCreating ? _createBackup : null,
                    child: _isCreating
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Creating...'),
                            ],
                          )
                        : const Text('Create Backup'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canCreateBackup() {
    return _keyHolders.length == _totalKeys && _relays.isNotEmpty;
  }

  Future<void> _addKeyHolder() async {
    final npubController = TextEditingController();
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Key Holder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: npubController,
              decoration: const InputDecoration(
                labelText: 'Nostr Public Key (npub)',
                hintText: 'npub1...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name (optional)',
                hintText: 'Alice',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Convert bech32 npub to hex pubkey
        final npub = npubController.text.trim();
        final decoded = Helpers.decodeBech32(npub);
        if (decoded[0].isEmpty) {
          throw Exception('Invalid npub format: $npub');
        }

        final keyHolder = createKeyHolder(
          pubkey: decoded[0], // Hex format
          name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
        );

        setState(() {
          _keyHolders.add(keyHolder);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid key holder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _createBackup() async {
    if (!_canCreateBackup()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // Use the lockbox ID passed to this screen
      final lockboxId = widget.lockboxId;

      // Create backup configuration
      final config = await BackupService.createBackupConfiguration(
        lockboxId: lockboxId,
        threshold: _threshold,
        totalKeys: _totalKeys,
        keyHolders: _keyHolders,
        relays: _relays,
      );

      // Get actual lockbox content
      final lockbox = await LockboxService.getLockbox(lockboxId);
      if (lockbox == null) {
        throw Exception('Lockbox not found: $lockboxId');
      }
      final content = lockbox.content;

      final creatorKeyPair = await KeyService.getStoredNostrKey();
      final creatorPubkey = creatorKeyPair?.publicKey;
      final creatorPrivkey = creatorKeyPair?.privateKey;
      if (creatorPubkey == null || creatorPrivkey == null) {
        throw Exception('No key available');
      }

      final shards = await BackupService.generateShamirShares(
        content: content,
        threshold: _threshold,
        totalShards: _totalKeys,
        creatorPubkey: creatorPubkey,
      );

      // Distribute shards
      final ndk = Ndk.defaultConfig();
      ndk.accounts.loginPrivateKey(
        pubkey: creatorPubkey,
        privkey: creatorPrivkey,
      );
      await ShardDistributionService.distributeShards(
        ownerPubkey: creatorPubkey,
        config: config,
        shards: shards,
        ndk: ndk,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}

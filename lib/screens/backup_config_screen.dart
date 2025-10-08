import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/key_holder.dart';
import '../models/lockbox.dart';
import '../providers/backup_provider.dart';

/// Backup configuration screen for setting up distributed backup
///
/// This screen allows users to configure backup settings including:
/// - Threshold and total number of keys
/// - Key holders (trusted contacts)
/// - Nostr relay selection
///
/// Note: Requires a valid lockboxId to load the lockbox content for backup
class BackupConfigScreen extends ConsumerStatefulWidget {
  final String lockboxId;

  const BackupConfigScreen({super.key, required this.lockboxId});

  @override
  ConsumerState<BackupConfigScreen> createState() => _BackupConfigScreenState();
}

class _BackupConfigScreenState extends ConsumerState<BackupConfigScreen> {
  int _threshold = LockboxBackupConstraints.defaultThreshold;
  int _totalKeys = LockboxBackupConstraints.defaultTotalKeys;
  final List<KeyHolder> _keyHolders = [];
  final List<String> _relays = ['ws://localhost:10547'];
  bool _isCreating = false;
  bool _isInitialized = false;

  void _initializeFromConfig(dynamic config) {
    if (config != null && !_isInitialized) {
      setState(() {
        _threshold = config.threshold;
        _totalKeys = config.totalKeys;
        _keyHolders.clear();
        _keyHolders.addAll(config.keyHolders);
        _relays.clear();
        _relays.addAll(config.relays);
        _isInitialized = true;
      });
    } else if (config == null && !_isInitialized) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the backup config provider
    final backupConfigAsync = ref.watch(backupConfigProvider(widget.lockboxId));

    return backupConfigAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Backup Configuration'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Backup Configuration'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading backup config: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(backupConfigProvider(widget.lockboxId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (config) {
        // Initialize from config if available
        _initializeFromConfig(config);

        return _buildConfigScreen(context);
      },
    );
  }

  Widget _buildConfigScreen(BuildContext context) {

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
                    Text('Backup Settings', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Text('Threshold: $_threshold (minimum keys needed)'),
                    Slider(
                      value: _threshold.toDouble(),
                      min: LockboxBackupConstraints.minThreshold.toDouble(),
                      max: _totalKeys.toDouble(),
                      divisions: (_totalKeys - LockboxBackupConstraints.minThreshold) > 0
                          ? _totalKeys - LockboxBackupConstraints.minThreshold
                          : null,
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
                      max: LockboxBackupConstraints.maxTotalKeys.toDouble(),
                      divisions: (LockboxBackupConstraints.maxTotalKeys - _threshold) > 0
                          ? LockboxBackupConstraints.maxTotalKeys - _threshold
                          : null,
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
                        'No key holders added yet. Add trusted contacts to distribute backup keys.',
                      )
                    else
                      ..._keyHolders.map(
                        (holder) => ListTile(
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
                        ),
                      ),
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
                    Text('Nostr Relays', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    ..._relays.map(
                      (relay) => ListTile(
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
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addRelay,
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
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
            SnackBar(content: Text('Invalid key holder: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _addRelay() async {
    final relayController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Nostr Relay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: relayController,
              decoration: const InputDecoration(
                labelText: 'Relay URL',
                hintText: 'wss://relay.example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Must be a valid WebSocket URL (wss:// or ws://)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );

    if (result == true) {
      try {
        final relayUrl = relayController.text.trim();

        // Validate relay URL
        if (relayUrl.isEmpty) {
          throw Exception('Relay URL cannot be empty');
        }

        final uri = Uri.parse(relayUrl);
        if (uri.scheme != 'wss' && uri.scheme != 'ws') {
          throw Exception('Relay URL must start with wss:// or ws://');
        }

        // Check if relay already exists
        if (_relays.contains(relayUrl)) {
          throw Exception('This relay is already in the list');
        }

        setState(() {
          _relays.add(relayUrl);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid relay URL: $e'), backgroundColor: Colors.red),
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
      // Create/recreate the backup configuration and distribute shards using repository
      await ref.read(backupRepositoryProvider).createAndDistributeBackup(
            lockboxId: widget.lockboxId,
            threshold: _threshold,
            totalKeys: _totalKeys,
            keyHolders: _keyHolders,
            relays: _relays,
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
          SnackBar(content: Text('Failed to create backup: $e'), backgroundColor: Colors.red),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/key_holder.dart';
import '../models/lockbox.dart';
import '../services/backup_service.dart';
import '../providers/lockbox_provider.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  /// Load existing backup configuration if one exists
  Future<void> _loadExistingConfig() async {
    try {
      final repository = ref.read(lockboxRepositoryProvider);
      final existingConfig = await repository.getBackupConfig(widget.lockboxId);

      if (existingConfig != null && mounted) {
        setState(() {
          _threshold = existingConfig.threshold;
          _totalKeys = existingConfig.totalKeys;
          _keyHolders.clear();
          _keyHolders.addAll(existingConfig.keyHolders);
          _relays.clear();
          _relays.addAll(existingConfig.relays);
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Backup Configuration'),
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Configuration'),
        centerTitle: false,
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: SingleChildScrollView(
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

                // Invite by Link Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite by Link',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'Invitee Name',
                            hintText: 'Enter name for the invitee',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Stub: Non-functional for now
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invitation link generation coming soon'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.link),
                            label: const Text('Generate Invitation Link'),
                          ),
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

                const SizedBox(height: 16),

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
                const SizedBox(height: 16), // Bottom padding inside scroll view
              ],
            ),
          ),
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
      final repository = ref.read(lockboxRepositoryProvider);

      // Create/recreate the backup configuration and distribute shards
      // BackupService will handle overwriting existing config
      await BackupService.createAndDistributeBackup(
        lockboxId: widget.lockboxId,
        threshold: _threshold,
        totalKeys: _totalKeys,
        keyHolders: _keyHolders,
        relays: _relays,
        repository: repository,
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

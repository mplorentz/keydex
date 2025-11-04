import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/key_holder.dart';
import '../models/key_holder_status.dart';
import '../models/lockbox.dart';
import '../models/invitation_link.dart';
import '../services/backup_service.dart';
import '../services/invitation_service.dart';
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

  // Invitation link generation state
  final TextEditingController _inviteeNameController = TextEditingController();
  // Map to track invitation links by invitee name
  final Map<String, InvitationLink> _invitationLinksByInviteeName = {};
  bool _isGeneratingInvitation = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  @override
  void dispose() {
    _inviteeNameController.dispose();
    super.dispose();
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

                // Unified Key Holders Section
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
                              'Key Holders (${_keyHolders.length})',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Add Key Holder Input Section
                        TextField(
                          controller: _inviteeNameController,
                          decoration: const InputDecoration(
                            labelText: 'Invitee Name',
                            hintText: 'Enter name for the invitee',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_isGeneratingInvitation || _relays.isEmpty)
                                    ? null
                                    : _generateInvitationLink,
                                icon: _isGeneratingInvitation
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.link),
                                label: Text(_isGeneratingInvitation
                                    ? 'Generating...'
                                    : 'Generate Invitation Link'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _addKeyHolderManually,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add Manually'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Key Holders List
                        if (_keyHolders.isEmpty)
                          const Text(
                            'No key holders added yet. Add trusted contacts to distribute backup keys.',
                          )
                        else
                          ..._keyHolders.map(
                            (holder) => _buildKeyHolderListItem(holder),
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
    return _keyHolders.isNotEmpty && _relays.isNotEmpty;
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

  Future<void> _generateInvitationLink() async {
    final inviteeName = _inviteeNameController.text.trim();
    if (inviteeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an invitee name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_relays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one relay before generating an invitation'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if key holder with this name already exists
    if (_keyHolders.any((holder) => holder.name == inviteeName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A key holder with the name "$inviteeName" already exists'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Limit to first 3 relays as per design
    final relayUrls = _relays.take(3).toList();

    setState(() {
      _isGeneratingInvitation = true;
    });

    try {
      final invitationService = ref.read(invitationServiceProvider);
      final invitation = await invitationService.generateInvitationLink(
        lockboxId: widget.lockboxId,
        inviteeName: inviteeName,
        relayUrls: relayUrls,
      );

      if (mounted) {
        // Create invited key holder and add to list
        final invitedKeyHolder = createInvitedKeyHolder(name: inviteeName);

        setState(() {
          _keyHolders.add(invitedKeyHolder);
          _invitationLinksByInviteeName[inviteeName] = invitation;
          _inviteeNameController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation link generated and key holder added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate invitation link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingInvitation = false;
        });
      }
    }
  }

  Future<void> _addKeyHolderManually() async {
    final inviteeName = _inviteeNameController.text.trim();
    if (inviteeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an invitee name first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final npubController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Key Holder Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adding: $inviteeName',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: npubController,
              decoration: const InputDecoration(
                labelText: 'Nostr Public Key (npub)',
                hintText: 'npub1...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
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

        // Check if key holder with this pubkey already exists
        if (_keyHolders.any((holder) => holder.pubkey == decoded[0])) {
          throw Exception('A key holder with this public key already exists');
        }

        final keyHolder = createKeyHolder(
          pubkey: decoded[0], // Hex format
          name: inviteeName,
        );

        setState(() {
          _keyHolders.add(keyHolder);
          _inviteeNameController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Key holder added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid key holder: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildKeyHolderListItem(KeyHolder holder) {
    final invitation = holder.name != null ? _invitationLinksByInviteeName[holder.name] : null;

    return ListTile(
      leading: Icon(
        holder.status == KeyHolderStatus.invited ? Icons.mail_outline : Icons.person,
      ),
      title: Text(holder.displayName),
      subtitle: Text(holder.displaySubtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (holder.status == KeyHolderStatus.invited && invitation != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () => _copyInvitationLinkForHolder(invitation),
              tooltip: 'Copy invitation link',
            ),
          IconButton(
            icon: const Icon(Icons.remove_circle),
            onPressed: () => _removeKeyHolder(holder),
            tooltip: 'Remove key holder',
          ),
        ],
      ),
    );
  }

  void _copyInvitationLinkForHolder(InvitationLink invitation) {
    final url = invitation.toUrl();
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation link copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeKeyHolder(KeyHolder holder) {
    setState(() {
      _keyHolders.remove(holder);
      if (holder.name != null) {
        _invitationLinksByInviteeName.remove(holder.name);
      }
    });
  }

  Future<void> _createBackup() async {
    if (!_canCreateBackup()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final backupService = ref.read(backupServiceProvider);

      // Use actual key holders count for totalKeys
      final totalKeys = _keyHolders.length;

      // Create/recreate the backup configuration (without distributing shares)
      // Shares can be distributed later once all invites are confirmed
      await backupService.saveBackupConfig(
        lockboxId: widget.lockboxId,
        threshold: _threshold,
        totalKeys: totalKeys,
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

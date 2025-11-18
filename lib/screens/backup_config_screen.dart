import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/key_holder.dart';
import '../models/key_holder_status.dart';
import '../models/backup_status.dart';
import '../models/lockbox.dart';
import '../models/invitation_link.dart';
import '../services/backup_service.dart';
import '../services/invitation_service.dart';
import '../providers/lockbox_provider.dart';
import '../widgets/row_button_stack.dart';

/// Recovery plan screen for setting up distributed backup
///
/// This screen allows users to set up their recovery plan including:
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
  final List<KeyHolder> _keyHolders = [];
  final List<String> _relays = ['wss://dev.keydex.app'];
  bool _isCreating = false;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;

  // Invitation link generation state
  final TextEditingController _inviteeNameController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
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
    _instructionsController.dispose();
    super.dispose();
  }

  /// Load existing recovery plan if one exists
  Future<void> _loadExistingConfig() async {
    try {
      final repository = ref.read(lockboxRepositoryProvider);
      final existingConfig = await repository.getBackupConfig(widget.lockboxId);

      if (existingConfig != null && mounted) {
        setState(() {
          _threshold = existingConfig.threshold;
          _keyHolders.clear();
          _keyHolders.addAll(existingConfig.keyHolders);
          _relays.clear();
          _relays.addAll(existingConfig.relays);
          _instructionsController.text = existingConfig.instructions ?? '';
          _isLoading = false;
          _hasUnsavedChanges = false;
        });

        // Load existing invitations and match them to key holders
        await _loadExistingInvitations();
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
          title: const Text('Recovery Plan'),
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );

        if (!context.mounted) return;
        if (shouldDiscard == true) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recovery Plan'),
          centerTitle: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: ScrollConfiguration(
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
                                Text('Recovery Settings',
                                    style: Theme.of(context).textTheme.headlineSmall),
                                const SizedBox(height: 16),
                                Text('Threshold: $_threshold (minimum keys needed)'),
                                Slider(
                                  value: _threshold.toDouble().clamp(
                                        LockboxBackupConstraints.minThreshold.toDouble(),
                                        (_keyHolders.isEmpty
                                            ? LockboxBackupConstraints.maxTotalKeys.toDouble()
                                            : _keyHolders.length.toDouble()),
                                      ),
                                  min: LockboxBackupConstraints.minThreshold.toDouble(),
                                  max: _keyHolders.isEmpty
                                      ? LockboxBackupConstraints.maxTotalKeys.toDouble()
                                      : _keyHolders.length.toDouble(),
                                  divisions: (_keyHolders.isEmpty
                                                  ? LockboxBackupConstraints.maxTotalKeys
                                                  : _keyHolders.length) -
                                              LockboxBackupConstraints.minThreshold >
                                          0
                                      ? (_keyHolders.isEmpty
                                              ? LockboxBackupConstraints.maxTotalKeys
                                              : _keyHolders.length) -
                                          LockboxBackupConstraints.minThreshold
                                      : null,
                                  onChanged: _keyHolders.isEmpty
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _threshold = value.round();
                                            _hasUnsavedChanges = true;
                                          });
                                        },
                                ),
                                if (_keyHolders.isEmpty)
                                  Text(
                                    'Add stewards to set up recovery',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  )
                                else
                                  Text(
                                    'Total Keys: ${_keyHolders.length} (automatically set)',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Unified Stewards Section
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
                                      'Stewards (${_keyHolders.length})',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Add Steward Input Section
                                TextField(
                                  controller: _inviteeNameController,
                                  decoration: const InputDecoration(
                                    labelText: "Enter steward's name",
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

                                // Stewards List
                                if (_keyHolders.isEmpty)
                                  const Text(
                                    'No stewards added yet. Add trusted contacts to distribute backup keys.',
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

                        // Instructions Section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recovery Instructions',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _instructionsController,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Write recovery instructions for stewards e.g. under what circumstances they should help you recover access?',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                  maxLines: null,
                                  minLines: 3,
                                  onChanged: (_) {
                                    setState(() {
                                      _hasUnsavedChanges = true;
                                    });
                                  },
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
                                Text('Nostr Relays',
                                    style: Theme.of(context).textTheme.headlineSmall),
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
                                            _hasUnsavedChanges = true;
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

                        const SizedBox(height: 16), // Bottom padding inside scroll view
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Fixed action buttons at bottom
            RowButtonStack(
              buttons: [
                RowButtonConfig(
                  onPressed: _handleCancel,
                  icon: Icons.close,
                  text: 'Cancel',
                ),
                RowButtonConfig(
                  onPressed: _canCreateBackup() && !_isCreating ? _saveBackup : () {},
                  icon: _isCreating ? Icons.hourglass_empty : Icons.save,
                  text: _isCreating ? 'Saving...' : 'Save',
                ),
              ],
            ),
          ],
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
          _hasUnsavedChanges = true;
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

    // Check if steward with this name already exists
    if (_keyHolders.any((holder) => holder.name == inviteeName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A steward with the name "$inviteeName" already exists'),
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
        // Create invited steward and add to list
        final invitedKeyHolder = createInvitedKeyHolder(
          name: inviteeName,
          inviteCode: invitation.inviteCode,
        );

        setState(() {
          _keyHolders.add(invitedKeyHolder);
          _invitationLinksByInviteeName[inviteeName] = invitation;
          _inviteeNameController.clear();
          // Ensure threshold doesn't exceed the number of stewards
          if (_threshold > _keyHolders.length) {
            _threshold = _keyHolders.length;
          }
          _hasUnsavedChanges = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation link generated and steward added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to generate invitation link';
        if (e is ArgumentError) {
          errorMessage = e.message ?? errorMessage;
        } else {
          errorMessage = '$errorMessage: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
        title: const Text('Add Steward Manually'),
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
      if (!mounted) return;
      try {
        // Convert bech32 npub to hex pubkey
        final npub = npubController.text.trim();
        final decoded = Helpers.decodeBech32(npub);
        if (decoded[0].isEmpty) {
          throw Exception('Invalid npub format: $npub');
        }

        // Check if steward with this pubkey already exists
        if (_keyHolders.any((holder) => holder.pubkey == decoded[0])) {
          throw Exception('A steward with this public key already exists');
        }

        final keyHolder = createKeyHolder(
          pubkey: decoded[0], // Hex format
          name: inviteeName,
        );

        if (!mounted) return;
        setState(() {
          _keyHolders.add(keyHolder);
          _inviteeNameController.clear();
          // Ensure threshold doesn't exceed the number of stewards
          if (_threshold > _keyHolders.length) {
            _threshold = _keyHolders.length;
          }
          _hasUnsavedChanges = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Steward added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid steward: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildKeyHolderListItem(KeyHolder holder) {
    final invitation = holder.name != null ? _invitationLinksByInviteeName[holder.name] : null;
    final isInvited = holder.status == KeyHolderStatus.invited;
    final isMostRecentInvitation = invitation != null &&
        _invitationLinksByInviteeName.values
            .where((inv) => inv.createdAt.isAfter(invitation.createdAt))
            .isEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              isInvited ? Icons.mail_outline : Icons.person,
            ),
            title: Text(holder.displayName),
            subtitle: Text(holder.displaySubtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isInvited && invitation != null) ...[
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'copy') {
                        _copyInvitationLinkForHolder(invitation);
                      } else if (value == 'regenerate') {
                        _regenerateInvitationLink(holder, invitation);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 20),
                            SizedBox(width: 8),
                            Text('Copy Link'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'regenerate',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 20),
                            SizedBox(width: 8),
                            Text('Regenerate Link'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: () => _removeKeyHolder(holder),
                  tooltip: 'Remove steward',
                ),
              ],
            ),
          ),
          // Show invitation link preview for invited stewards
          if (isInvited && invitation != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMostRecentInvitation)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Most Recent',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _truncateUrl(invitation.toUrl()),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () => _copyInvitationLinkForHolder(invitation),
                        tooltip: 'Copy invitation link',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _truncateUrl(String url) {
    if (url.length <= 60) return url;
    return '${url.substring(0, 30)}...${url.substring(url.length - 27)}';
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

  Future<void> _loadExistingInvitations() async {
    try {
      final invitationService = ref.read(invitationServiceProvider);
      final pendingInvitations = await invitationService.getPendingInvitations(widget.lockboxId);

      // Match invitations to stewards by inviteeName
      final updatedInvitations = <String, InvitationLink>{};
      for (final invitation in pendingInvitations) {
        if (invitation.inviteeName != null &&
            _keyHolders.any((kh) => kh.name == invitation.inviteeName)) {
          updatedInvitations[invitation.inviteeName!] = invitation;
        }
      }

      if (mounted) {
        setState(() {
          _invitationLinksByInviteeName.clear();
          _invitationLinksByInviteeName.addAll(updatedInvitations);
        });
      }
    } catch (e) {
      // Log error but don't fail loading
      debugPrint('Error loading existing invitations: $e');
    }
  }

  Future<void> _removeKeyHolder(KeyHolder holder) async {
    // If this is an invited steward, invalidate their invitation
    if (holder.status == KeyHolderStatus.invited && holder.name != null) {
      final invitation = _invitationLinksByInviteeName[holder.name];
      if (invitation != null) {
        try {
          final invitationService = ref.read(invitationServiceProvider);
          await invitationService.invalidateInvitation(
            inviteCode: invitation.inviteCode,
            reason: 'Steward removed from recovery plan',
          );
        } catch (e) {
          debugPrint('Error invalidating invitation: $e');
          // Continue with removal even if invalidation fails
        }
      }
    }

    setState(() {
      _keyHolders.remove(holder);
      if (holder.name != null) {
        _invitationLinksByInviteeName.remove(holder.name);
      }

      // Ensure threshold doesn't exceed the number of stewards
      if (_keyHolders.isEmpty) {
        _threshold = LockboxBackupConstraints.minThreshold;
      } else if (_threshold > _keyHolders.length) {
        _threshold = _keyHolders.length;
      }

      _hasUnsavedChanges = true;
    });
  }

  Future<void> _regenerateInvitationLink(KeyHolder holder, InvitationLink oldInvitation) async {
    if (holder.name == null) return;

    setState(() {
      _isGeneratingInvitation = true;
    });

    try {
      final invitationService = ref.read(invitationServiceProvider);

      // Invalidate old invitation
      await invitationService.invalidateInvitation(
        inviteCode: oldInvitation.inviteCode,
        reason: 'Invitation link regenerated',
      );

      // Generate new invitation link
      final relayUrls = oldInvitation.relayUrls;
      final newInvitation = await invitationService.generateInvitationLink(
        lockboxId: widget.lockboxId,
        inviteeName: holder.name!,
        relayUrls: relayUrls,
      );

      if (mounted) {
        setState(() {
          _invitationLinksByInviteeName[holder.name!] = newInvitation;
          _hasUnsavedChanges = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation link regenerated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate invitation link: $e'),
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

  Future<void> _handleCancel() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );

      if (shouldDiscard == true && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _hasDistributedShards() async {
    try {
      final repository = ref.read(lockboxRepositoryProvider);
      final lockbox = await repository.getLockbox(widget.lockboxId);
      if (lockbox == null) return false;

      final backupConfig = lockbox.backupConfig;
      if (backupConfig == null) return false;

      // Check if backup status is active (shards distributed)
      if (backupConfig.status == BackupStatus.active) {
        return true;
      }

      // Check if any key holder has a giftWrapEventId (shard distributed)
      return backupConfig.keyHolders.any((kh) => kh.giftWrapEventId != null);
    } catch (e) {
      debugPrint('Error checking distributed shards: $e');
      return false;
    }
  }

  Future<void> _saveBackup() async {
    if (!_canCreateBackup()) return;

    // Check if shards have been distributed and show warning
    final hasDistributed = await _hasDistributedShards();
    if (!mounted) return;
    if (hasDistributed) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Warning: Shards Already Distributed'),
          content: const Text(
            'Saving these changes will invalidate the distributed shards and require redistribution. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

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
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });

        if (mounted) {
          Navigator.pop(context, true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recovery plan saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save recovery plan: $e'), backgroundColor: Colors.red),
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

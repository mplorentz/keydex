import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/relay_configuration.dart';
import '../providers/relay_provider.dart';
import '../services/relay_scan_service.dart';
import '../services/logger.dart';

/// Screen for managing Nostr relay configurations
class RelayManagementScreen extends ConsumerWidget {
  const RelayManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the relay providers
    final relaysAsync = ref.watch(relayListProvider);
    final scanningStatusAsync = ref.watch(scanningStatusProvider);
    final isScanningAsync = ref.watch(isScanningActiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relay Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(relayListProvider);
              ref.invalidate(scanningStatusProvider);
              ref.invalidate(isScanningActiveProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: relaysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading relays: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(relayListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (relays) => _RelayManagementContent(
          relays: relays,
          scanningStatusAsync: scanningStatusAsync,
          isScanningAsync: isScanningAsync,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addRelay(context, ref),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addRelay(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddRelayDialog(),
    );

    if (result != null && context.mounted) {
      try {
        final relay = RelayConfiguration(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          url: result['url'] as String,
          name: result['name'] as String,
          isEnabled: true,
          isTrusted: result['isTrusted'] as bool? ?? false,
        );

        await ref.read(relayRepositoryProvider).addRelay(relay);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added relay: ${relay.name}')),
          );
        }
      } catch (e) {
        Log.error('Error adding relay', e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding relay: $e')),
          );
        }
      }
    }
  }
}

/// Extracted content widget for relay management
class _RelayManagementContent extends ConsumerWidget {
  final List<RelayConfiguration> relays;
  final AsyncValue<ScanningStatus> scanningStatusAsync;
  final AsyncValue<bool> isScanningAsync;

  const _RelayManagementContent({
    required this.relays,
    required this.scanningStatusAsync,
    required this.isScanningAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isScanning = isScanningAsync.value ?? false;

    return Column(
      children: [
        // Scanning status card
        scanningStatusAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (status) => _ScanningStatusCard(
            status: status,
            isScanning: isScanning,
          ),
        ),

        // Scanning controls
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleScanning(context, ref, isScanning),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isScanning
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(isScanning ? Icons.stop : Icons.play_arrow),
                  label: Text(isScanning ? 'Stop Scanning' : 'Start Scanning'),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _scanNow(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.search),
                label: const Text('Scan Now'),
              ),
            ],
          ),
        ),

        // Relay list
        Expanded(
          child: relays.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.dns_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No relays configured',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first relay',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: relays.length,
                  itemBuilder: (context, index) {
                    final relay = relays[index];
                    return _RelayCard(relay: relay);
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _toggleScanning(BuildContext context, WidgetRef ref, bool isScanning) async {
    try {
      final repository = ref.read(relayRepositoryProvider);
      if (isScanning) {
        await repository.stopScanning();
      } else {
        await repository.startScanning();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isScanning ? 'Scanning stopped' : 'Scanning started'),
          ),
        );
      }
    } catch (e) {
      Log.error('Error toggling scanning', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _scanNow(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(relayRepositoryProvider).scanNow();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manual scan completed')),
        );
      }
    } catch (e) {
      Log.error('Error scanning relays', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
    }
  }
}

/// Extracted widget for scanning status card
class _ScanningStatusCard extends StatelessWidget {
  final ScanningStatus status;
  final bool isScanning;

  const _ScanningStatusCard({
    required this.status,
    required this.isScanning,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isScanning ? Icons.sync : Icons.sync_disabled,
                  color: isScanning ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  'Scanning Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Total Relays', '${status.totalRelays}'),
            _buildStatusRow('Active Relays', '${status.activeRelays}'),
            _buildStatusRow('Shares Found', '${status.sharesFound}'),
            _buildStatusRow('Requests Found', '${status.requestsFound}'),
            if (status.lastScan != null)
              _buildStatusRow(
                'Last Scan',
                _formatDateTime(status.lastScan!),
              ),
            if (status.lastError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Error: ${status.lastError}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Extracted widget for relay card
class _RelayCard extends ConsumerWidget {
  final RelayConfiguration relay;

  const _RelayCard({required this.relay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: relay.isEnabled
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[300],
          child: Icon(
            Icons.dns,
            color: relay.isEnabled ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ),
        title: Text(
          relay.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(relay.url, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                if (relay.isTrusted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Trusted',
                      style: TextStyle(fontSize: 10, color: Colors.green),
                    ),
                  ),
                if (!relay.isEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Disabled',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                if (relay.lastScanned != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'Last scanned: ${_formatDateTime(relay.lastScanned!)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(relay.isEnabled ? Icons.pause : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(relay.isEnabled ? 'Disable' : 'Enable'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'toggle') {
              _toggleRelay(context, ref);
            } else if (value == 'delete') {
              _deleteRelay(context, ref);
            }
          },
        ),
      ),
    );
  }

  Future<void> _toggleRelay(BuildContext context, WidgetRef ref) async {
    try {
      final updatedRelay = relay.copyWith(isEnabled: !relay.isEnabled);
      await ref.read(relayRepositoryProvider).updateRelay(updatedRelay);
    } catch (e) {
      Log.error('Error toggling relay', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling relay: $e')),
        );
      }
    }
  }

  Future<void> _deleteRelay(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Relay'),
        content: Text('Are you sure you want to delete "${relay.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(relayRepositoryProvider).removeRelay(relay.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted relay: ${relay.name}')),
          );
        }
      } catch (e) {
        Log.error('Error deleting relay', e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting relay: $e')),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Dialog for adding a new relay
class _AddRelayDialog extends StatefulWidget {
  const _AddRelayDialog();

  @override
  _AddRelayDialogState createState() => _AddRelayDialogState();
}

class _AddRelayDialogState extends State<_AddRelayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isTrusted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Relay'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Relay Name',
                hintText: 'e.g., My Trusted Relay',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Relay URL',
                hintText: 'wss://relay.example.com',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a URL';
                }
                if (!value.startsWith('ws://') && !value.startsWith('wss://')) {
                  return 'URL must start with ws:// or wss://';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Trusted Relay'),
              subtitle: const Text('Use for sensitive operations'),
              value: _isTrusted,
              onChanged: (value) {
                setState(() {
                  _isTrusted = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'url': _urlController.text,
                'isTrusted': _isTrusted,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

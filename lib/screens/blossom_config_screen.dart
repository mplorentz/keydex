import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/row_button.dart';
import '../providers/blossom_config_provider.dart';
import '../models/blossom_server_config.dart';

/// Screen for managing Blossom server configurations
class BlossomConfigScreen extends ConsumerStatefulWidget {
  const BlossomConfigScreen({super.key});

  @override
  ConsumerState<BlossomConfigScreen> createState() => _BlossomConfigScreenState();
}

class _BlossomConfigScreenState extends ConsumerState<BlossomConfigScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize defaults if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDefaults();
    });
  }

  Future<void> _initializeDefaults() async {
    final service = ref.read(blossomConfigServiceProvider);
    final configs = await service.getAllConfigs();
    if (configs.isEmpty) {
      await service.initializeDefaults();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(blossomConfigServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blossom Servers'),
        centerTitle: false,
      ),
      body: FutureBuilder<List<BlossomServerConfig>>(
        future: service.getAllConfigs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading servers: ${snapshot.error}'),
            );
          }

          final configs = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                child: configs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No Blossom servers configured.\nTap "Add Server" to add one.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: configs.length,
                        itemBuilder: (context, index) {
                          final config = configs[index];
                          return ListTile(
                            leading: Icon(
                              config.isEnabled ? Icons.cloud : Icons.cloud_off,
                              color: config.isDefault ? Colors.orange : null,
                            ),
                            title: Text(config.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(config.url),
                                if (config.isDefault)
                                  const Text(
                                    'Default Server',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                if (!config.isEnabled)
                                  const Text(
                                    'Disabled',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editServer(context, config),
                                  tooltip: 'Edit server',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteServer(context, config),
                                  tooltip: 'Delete server',
                                ),
                              ],
                            ),
                            onTap: () => _editServer(context, config),
                          );
                        },
                      ),
              ),
              RowButton(
                onPressed: () => _addServer(context),
                icon: Icons.add,
                text: 'Add Server',
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addServer(BuildContext context) async {
    final result = await showDialog<BlossomServerConfig>(
      context: context,
      builder: (context) => _ServerEditDialog(),
    );

    if (result != null && mounted) {
      final service = ref.read(blossomConfigServiceProvider);
      try {
        await service.addServer(
          url: result.url,
          name: result.name,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Server added successfully')),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding server: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editServer(BuildContext context, BlossomServerConfig config) async {
    final result = await showDialog<BlossomServerConfig>(
      context: context,
      builder: (context) => _ServerEditDialog(initialConfig: config),
    );

    if (result != null && mounted) {
      final service = ref.read(blossomConfigServiceProvider);
      try {
        await service.updateServer(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Server updated successfully')),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating server: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteServer(BuildContext context, BlossomServerConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Server?'),
        content: Text('Are you sure you want to delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final service = ref.read(blossomConfigServiceProvider);
      try {
        await service.deleteServer(config.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Server deleted')),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting server: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _ServerEditDialog extends StatefulWidget {
  final BlossomServerConfig? initialConfig;

  const _ServerEditDialog({this.initialConfig});

  @override
  State<_ServerEditDialog> createState() => _ServerEditDialogState();
}

class _ServerEditDialogState extends State<_ServerEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isEnabled = true;
  bool _isDefault = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null) {
      _nameController.text = widget.initialConfig!.name;
      _urlController.text = widget.initialConfig!.url;
      _isEnabled = widget.initialConfig!.isEnabled;
      _isDefault = widget.initialConfig!.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialConfig == null ? 'Add Server' : 'Edit Server'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Server Name',
                  hintText: 'e.g., Local Blossom Server',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'e.g., http://localhost:10548',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a URL';
                  }
                  try {
                    final uri = Uri.parse(value.trim());
                    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
                      return 'URL must be HTTP or HTTPS';
                    }
                  } catch (_) {
                    return 'Invalid URL format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Enabled'),
                value: _isEnabled,
                onChanged: (value) => setState(() => _isEnabled = value ?? true),
              ),
              CheckboxListTile(
                title: const Text('Set as Default'),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value ?? false),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check),
                label: const Text('Test Connection'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      final service = ProviderScope.containerOf(context).read(blossomConfigServiceProvider);
      final success = await service.testConnection(_urlController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Connection successful!' : 'Connection failed'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing connection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final config = widget.initialConfig != null
        ? widget.initialConfig!.copyWith(
            name: _nameController.text.trim(),
            url: _urlController.text.trim(),
            isEnabled: _isEnabled,
            isDefault: _isDefault,
          )
        : BlossomServerConfig.create(
            name: _nameController.text.trim(),
            url: _urlController.text.trim(),
            isEnabled: _isEnabled,
            isDefault: _isDefault,
          );

    Navigator.of(context).pop(config);
  }
}

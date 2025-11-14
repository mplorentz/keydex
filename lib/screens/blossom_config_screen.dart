import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/row_button.dart';

/// Stub screen for Blossom server configuration
/// TODO: Implement Blossom server CRUD operations
class BlossomConfigScreen extends ConsumerStatefulWidget {
  const BlossomConfigScreen({super.key});

  @override
  ConsumerState<BlossomConfigScreen> createState() => _BlossomConfigScreenState();
}

class _BlossomConfigScreenState extends ConsumerState<BlossomConfigScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blossom Servers'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Blossom server configuration\n(Stub - TODO: Implement)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          RowButton(
            onPressed: () {
              // TODO: Implement add server dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add server (stub)')),
              );
            },
            icon: Icons.add,
            text: 'Add Server',
          ),
        ],
      ),
    );
  }
}


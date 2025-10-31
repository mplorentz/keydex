import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for accepting or denying an invitation link
///
/// This is a stub screen that will be connected to deep linking
/// and invitation service in later phases.
class InvitationAcceptanceScreen extends ConsumerStatefulWidget {
  final String inviteCode;

  const InvitationAcceptanceScreen({
    super.key,
    required this.inviteCode,
  });

  @override
  ConsumerState<InvitationAcceptanceScreen> createState() => _InvitationAcceptanceScreenState();
}

class _InvitationAcceptanceScreenState extends ConsumerState<InvitationAcceptanceScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitation'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invitation Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You\'ve been invited',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Text('Invitation Code:'),
                    const SizedBox(height: 4),
                    SelectableText(
                      widget.inviteCode,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            backgroundColor: Colors.grey[200],
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Stub: Will show actual invitation details in later phase
                    const Text(
                      'Lockbox details will be displayed here',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Owner: (will be loaded)',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Invitee Name: (will be loaded)',
                      style: TextStyle(color: Colors.grey),
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
                    onPressed: _isProcessing
                        ? null
                        : () {
                            // Stub: Non-functional for now
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Deny invitation coming soon'),
                              ),
                            );
                          },
                    child: const Text('Deny'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            // Stub: Non-functional for now
                            setState(() {
                              _isProcessing = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Accept invitation coming soon'),
                              ),
                            );
                            Future.delayed(const Duration(seconds: 1), () {
                              if (mounted) {
                                setState(() {
                                  _isProcessing = false;
                                });
                              }
                            });
                          },
                    child: _isProcessing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Processing...'),
                            ],
                          )
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

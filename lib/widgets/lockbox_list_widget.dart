import 'package:flutter/material.dart';
import '../contracts/lockbox_service.dart';
import 'lockbox_card_widget.dart';
import '../screens/lockbox_detail_screen.dart';

class LockboxListWidget extends StatelessWidget {
  final List<LockboxMetadata> lockboxes;
  final VoidCallback onRefresh;

  const LockboxListWidget({
    super.key,
    required this.lockboxes,
    required this.onRefresh,
  });

  void _navigateToLockboxDetail(BuildContext context, LockboxMetadata lockbox) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LockboxDetailScreen(
          lockboxId: lockbox.id,
          lockboxName: lockbox.name,
        ),
      ),
    ).then((result) {
      // If the lockbox was deleted or modified, refresh the list
      if (result == true) {
        onRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (lockboxes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_open,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No lockboxes yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to create your first lockbox',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: lockboxes.length,
      itemBuilder: (context, index) {
        final lockbox = lockboxes[index];
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: LockboxCardWidget(
            lockbox: lockbox,
            onTap: () => _navigateToLockboxDetail(context, lockbox),
          ),
        );
      },
    );
  }
}
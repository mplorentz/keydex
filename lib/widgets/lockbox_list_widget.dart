// Lockbox List Widget - Displays a list of lockboxes with pull-to-refresh

import 'package:flutter/material.dart';
import '../contracts/lockbox_service.dart' as contracts;
import '../models/lockbox.dart';
import 'lockbox_card_widget.dart';

class LockboxListWidget extends StatelessWidget {
  const LockboxListWidget({
    super.key,
    required this.lockboxes,
    required this.onTap,
    required this.onDelete,
    required this.onRefresh,
    this.showEmptyState = true,
    this.physics,
  });

  final List<LockboxMetadata> lockboxes;
  final ValueChanged<LockboxMetadata> onTap;
  final ValueChanged<String> onDelete;
  final VoidCallback onRefresh;
  final bool showEmptyState;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    if (lockboxes.isEmpty && showEmptyState) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView.builder(
        physics: physics ?? const AlwaysScrollableScrollPhysics(),
        itemCount: lockboxes.length,
        padding: const EdgeInsets.only(bottom: 80), // Space for FAB
        itemBuilder: (context, index) {
          final lockbox = lockboxes[index];
          
          return LockboxCardWidget(
            lockbox: lockbox,
            onTap: () => onTap(lockbox),
            onDelete: () => onDelete(lockbox.id),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 60,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Empty state text
            Text(
              'No Lockboxes Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Create your first encrypted lockbox to securely store sensitive text, passwords, or private notes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Features list
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What you can store:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildFeatureItem(
                    context,
                    Icons.password,
                    'Passwords & Login Credentials',
                  ),
                  
                  _buildFeatureItem(
                    context,
                    Icons.note_alt,
                    'Private Notes & Ideas',
                  ),
                  
                  _buildFeatureItem(
                    context,
                    Icons.credit_card,
                    'Financial Information',
                  ),
                  
                  _buildFeatureItem(
                    context,
                    Icons.vpn_key,
                    'API Keys & Secrets',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Security notice
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure by Design',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All data is encrypted using NIP-44 encryption and stored locally on your device.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 100), // Extra space for pull-to-refresh
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
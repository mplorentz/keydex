import 'package:flutter/material.dart';

/// Widget for displaying recovery progress and key holder status
///
/// This widget shows the current progress of a recovery request,
/// including how many key holders have responded and their decisions.
class RecoveryProgressWidget extends StatelessWidget {
  final int totalKeyHolders;
  final int respondedCount;
  final int approvedCount;
  final int deniedCount;
  final int threshold;
  final bool isCompleted;
  final VoidCallback? onTap;

  const RecoveryProgressWidget({
    super.key,
    required this.totalKeyHolders,
    required this.respondedCount,
    required this.approvedCount,
    required this.deniedCount,
    required this.threshold,
    this.isCompleted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalKeyHolders > 0 ? approvedCount / totalKeyHolders : 0.0;
    final canRecover = approvedCount >= threshold;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle
                        : canRecover
                            ? Icons.warning
                            : Icons.schedule,
                    color: isCompleted
                        ? Colors.green
                        : canRecover
                            ? Colors.orange
                            : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCompleted
                          ? 'Recovery Completed'
                          : canRecover
                              ? 'Ready to Recover'
                              : 'Recovery in Progress',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted
                      ? Colors.green
                      : canRecover
                          ? Colors.orange
                          : Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),

              // Progress text
              Text(
                _getProgressText(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              // Status chips
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildStatusChip(
                    'Approved',
                    approvedCount,
                    Colors.green,
                  ),
                  _buildStatusChip(
                    'Pending',
                    totalKeyHolders - respondedCount,
                    Colors.orange,
                  ),
                  if (deniedCount > 0)
                    _buildStatusChip(
                      'Denied',
                      deniedCount,
                      Colors.red,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getProgressText() {
    if (isCompleted) {
      return 'Recovery completed successfully';
    } else if (approvedCount >= threshold) {
      return 'Threshold met ($approvedCount/$threshold). Ready to recover.';
    } else {
      return '$approvedCount of $threshold shares collected';
    }
  }
}

/// Extension for creating sample data
extension RecoveryProgressWidgetSample on RecoveryProgressWidget {
  static RecoveryProgressWidget createSample({
    bool isCompleted = false,
    bool canRecover = false,
  }) {
    return RecoveryProgressWidget(
      totalKeyHolders: 3,
      respondedCount: isCompleted ? 3 : 2,
      approvedCount: isCompleted ? 3 : (canRecover ? 2 : 1),
      deniedCount: 0,
      threshold: 2,
      isCompleted: isCompleted,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_distribution_service.dart';
import '../models/file_distribution_status.dart';

/// Provider for FileDistributionService
final fileDistributionServiceProvider = Provider<FileDistributionService>((ref) {
  return FileDistributionService();
});

/// Provider for distribution status of a specific lockbox
final distributionStatusProvider =
    FutureProvider.family<List<FileDistributionStatus>, String>((ref, lockboxId) async {
  final service = ref.watch(fileDistributionServiceProvider);
  return await service.getDistributionStatus(lockboxId);
});

/// Provider to check if distribution is complete for a lockbox
final isDistributionCompleteProvider = FutureProvider.family<bool, String>((ref, lockboxId) async {
  final service = ref.watch(fileDistributionServiceProvider);
  return await service.isDistributionComplete(lockboxId);
});


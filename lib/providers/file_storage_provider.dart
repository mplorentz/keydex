import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_storage_service.dart';
import '../models/cached_file.dart';

/// Provider for FileStorageService
final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

/// Provider for all cached files
final cachedFilesProvider = FutureProvider<List<CachedFile>>((ref) async {
  final service = ref.watch(fileStorageServiceProvider);
  return await service.getAllCachedFiles();
});

/// Provider for cached files of a specific lockbox
final lockboxCachedFilesProvider = FutureProvider.family<List<CachedFile>, String>((ref, lockboxId) async {
  final allCached = await ref.watch(cachedFilesProvider.future);
  return allCached.where((f) => f.lockboxId == lockboxId).toList();
});


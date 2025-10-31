// lib/presentation/providers/storage_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/hive_storage_service.dart';
import '../../data/services/cache_manager_service.dart';

// Hive 存储服务 Provider
final hiveStorageServiceProvider = Provider<HiveStorageService>((ref) {
  return HiveStorageService();
});

// 缓存管理服务 Provider
final cacheManagerServiceProvider = Provider<CacheManagerService>((ref) {
  final storageService = ref.watch(hiveStorageServiceProvider);
  return CacheManagerService(storageService);
});

// 初始化状态 Provider
final storageInitializedProvider = StateProvider<bool>((ref) => false);

// 缓存统计 Provider
final cacheStatisticsProvider = FutureProvider<CacheStatistics>((ref) async {
  final cacheService = ref.watch(cacheManagerServiceProvider);
  return await cacheService.getCacheStatistics();
});

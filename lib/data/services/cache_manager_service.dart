// lib/data/services/cache_manager_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../services/hive_storage_service.dart';
import '../../domain/models/audio_info.dart';

class CacheManagerService {
  final HiveStorageService _storageService;
  Directory? _cacheDirectory;

  CacheManagerService(this._storageService);

  // 初始化缓存目录
  Future<void> init() async {
    final baseDir = _storageService.storageRoot;
    _cacheDirectory = Directory(path.join(baseDir.path, 'audio_cache'));
    if (!_cacheDirectory!.existsSync()) {
      await _cacheDirectory!.create(recursive: true);
    }
  }

  // 下载音频文件
  Future<String?> downloadAudio(AudioInfo audio) async {
    try {
      if (_cacheDirectory == null) await init();

      final fileName =
          '${audio.id}_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final filePath = path.join(_cacheDirectory!.path, fileName);
      final file = File(filePath);

      // 开始下载
      final response = await http.get(Uri.parse(audio.audioUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);

        // 更新缓存信息
        final fileSize = await file.length();
        await _storageService.updateCacheInfo(audio.id, filePath, fileSize);

        return filePath;
      } else {
        throw Exception('下载失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      print('下载音频失败: $e');
      return null;
    }
  }

  // 获取音频的缓存文件路径
  String? getCachedFilePath(String audioId) {
    final cacheInfo = _storageService.getCacheInfo(audioId);
    return cacheInfo?['filePath'];
  }

  // 检查音频是否已缓存
  bool isAudioCached(String audioId) {
    final filePath = getCachedFilePath(audioId);
    if (filePath != null) {
      final file = File(filePath);
      return file.existsSync();
    }
    return false;
  }

  // 获取缓存文件大小
  Future<int> getCacheFileSize(String audioId) async {
    final filePath = getCachedFilePath(audioId);
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    }
    return 0;
  }

  // 删除单个缓存文件
  Future<bool> deleteCacheFile(String audioId) async {
    try {
      final filePath = getCachedFilePath(audioId);
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        await _storageService.removeCacheInfo(audioId);
        return true;
      }
      return false;
    } catch (e) {
      print('删除缓存文件失败: $e');
      return false;
    }
  }

  // 清理所有缓存
  Future<void> clearAllCache() async {
    try {
      if (_cacheDirectory == null) await init();

      if (await _cacheDirectory!.exists()) {
        // 删除所有缓存文件
        final files = _cacheDirectory!.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }

      // 清空缓存信息
      final allCacheInfo = _storageService.getAllCacheInfo();
      for (final audioId in allCacheInfo.keys) {
        await _storageService.removeCacheInfo(audioId);
      }
    } catch (e) {
      print('清理所有缓存失败: $e');
      rethrow;
    }
  }

  // 清理过期缓存（按时间）
  Future<void> clearExpiredCache({int days = 30}) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(days: days));
      final allCacheInfo = _storageService.getAllCacheInfo();

      for (final entry in allCacheInfo.entries) {
        final audioId = entry.key;
        final cacheInfo = entry.value;
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(
          cacheInfo['cachedAt'],
        );

        if (cachedAt.isBefore(cutoffTime)) {
          await deleteCacheFile(audioId);
        }
      }
    } catch (e) {
      print('清理过期缓存失败: $e');
    }
  }

  // 按大小清理缓存
  Future<void> clearCacheBySize({int maxSizeMB = 500}) async {
    try {
      final maxSizeBytes = maxSizeMB * 1024 * 1024;
      final allCacheInfo = _storageService.getAllCacheInfo();

      // 按缓存时间排序（最旧的在前）
      final sortedEntries = allCacheInfo.entries.toList()
        ..sort(
          (a, b) => (a.value['cachedAt'] as int).compareTo(
            b.value['cachedAt'] as int,
          ),
        );

      int currentSize = _storageService.getTotalCacheSize();

      // 如果当前大小超过限制，删除最旧的缓存
      for (final entry in sortedEntries) {
        if (currentSize <= maxSizeBytes) break;

        final audioId = entry.key;
        final cacheInfo = entry.value;
        final fileSize = cacheInfo['fileSize'] as int;

        await deleteCacheFile(audioId);
        currentSize -= fileSize;
      }
    } catch (e) {
      print('按大小清理缓存失败: $e');
    }
  }

  // 获取缓存统计信息
  Future<CacheStatistics> getCacheStatistics() async {
    final allCacheInfo = _storageService.getAllCacheInfo();
    int totalSize = 0;
    int fileCount = 0;

    for (final entry in allCacheInfo.entries) {
      final filePath = entry.value['filePath'];
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          totalSize += await file.length();
          fileCount++;
        }
      }
    }

    return CacheStatistics(totalSize: totalSize, fileCount: fileCount);
  }

  // 获取缓存目录路径
  String? get cacheDirectoryPath => _cacheDirectory?.path;
}

class CacheStatistics {
  final int totalSize;
  final int fileCount;

  CacheStatistics({required this.totalSize, required this.fileCount});

  String get formattedSize {
    if (totalSize < 1024) {
      return '$totalSize B';
    } else if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}

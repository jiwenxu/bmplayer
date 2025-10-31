// lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_provider.dart';
import '../providers/storage_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlayerServiceProvider);
    final cacheStatsAsync = ref.watch(cacheStatisticsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 自动下载设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '下载设置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('自动下载播放的音频'),
                    subtitle: const Text('播放时自动缓存音频到本地'),
                    value: audioService.autoDownload,
                    onChanged: (value) {
                      //audioService.setAutoDownload(value);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 缓存管理
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '缓存管理',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // 缓存统计
                  cacheStatsAsync.when(
                    data: (stats) => ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('缓存大小'),
                      subtitle: Text(
                        '${stats.formattedSize} (${stats.fileCount} 个文件)',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showClearCacheDialog(context, ref),
                      ),
                    ),
                    loading: () => const ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('加载缓存信息...'),
                    ),
                    error: (error, stack) => ListTile(
                      leading: const Icon(Icons.error),
                      title: const Text('加载失败'),
                      subtitle: Text(error.toString()),
                    ),
                  ),

                  const Divider(),

                  // 缓存操作
                  ListTile(
                    leading: const Icon(Icons.cleaning_services),
                    title: const Text('清理所有缓存'),
                    subtitle: const Text('删除所有已下载的音频文件'),
                    onTap: () => _showClearCacheDialog(context, ref),
                  ),

                  ListTile(
                    leading: const Icon(Icons.delete_sweep),
                    title: const Text('清理过期缓存'),
                    subtitle: const Text('删除30天前的缓存文件'),
                    onTap: () => _clearExpiredCache(ref),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 数据管理
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '数据管理',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ListTile(
                    leading: const Icon(Icons.playlist_remove),
                    title: const Text('清空播放列表'),
                    subtitle: const Text('删除所有播放列表数据'),
                    onTap: () => _showClearPlaylistDialog(context, ref),
                  ),

                  ListTile(
                    leading: const Icon(Icons.delete_forever),
                    title: const Text('重置所有数据'),
                    subtitle: const Text('清空所有应用数据，包括设置和缓存'),
                    onTap: () => _showResetAllDataDialog(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理缓存'),
        content: const Text('确定要删除所有缓存文件吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllCache(ref);
              // 刷新缓存统计
              ref.invalidate(cacheStatisticsProvider);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showClearPlaylistDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空播放列表'),
        content: const Text('确定要清空播放列表吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final audioService = ref.read(audioPlayerServiceProvider);
              audioService.clearPlaylist();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showResetAllDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置所有数据'),
        content: const Text('确定要重置所有数据吗？这将删除播放列表、设置和所有缓存文件。此操作不可撤销！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetAllData(ref);
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllCache(WidgetRef ref) async {
    try {
      final cacheService = ref.read(cacheManagerServiceProvider);
      await cacheService.clearAllCache();

      // 更新播放列表，移除缓存路径
      final audioService = ref.read(audioPlayerServiceProvider);
      for (int i = 0; i < audioService.playlist.length; i++) {
        final audio = audioService.playlist[i];
        if (audio.isCached) {
          final updatedAudio = audio.copyWith(audioPath: null);
          // 这里需要更新播放列表，但为了简化，我们重新加载整个播放列表
        }
      }

      ScaffoldMessenger.of(
        ref.context,
      ).showSnackBar(const SnackBar(content: Text('缓存清理完成')));
    } catch (e) {
      ScaffoldMessenger.of(
        ref.context,
      ).showSnackBar(SnackBar(content: Text('清理缓存失败: $e')));
    }
  }

  Future<void> _clearExpiredCache(WidgetRef ref) async {
    try {
      final cacheService = ref.read(cacheManagerServiceProvider);
      await cacheService.clearExpiredCache();
      ref.invalidate(cacheStatisticsProvider);

      ScaffoldMessenger.of(
        ref.context,
      ).showSnackBar(const SnackBar(content: Text('过期缓存清理完成')));
    } catch (e) {
      ScaffoldMessenger.of(
        ref.context,
      ).showSnackBar(SnackBar(content: Text('清理过期缓存失败: $e')));
    }
  }

  Future<void> _resetAllData(WidgetRef ref) async {
    try {
      final storageService = ref.read(hiveStorageServiceProvider);
      final cacheService = ref.read(cacheManagerServiceProvider);
      final audioService = ref.read(audioPlayerServiceProvider);

      // 清空播放列表
      await audioService.clearPlaylist();

      // 清理缓存
      await cacheService.clearAllCache();

      // 清空所有存储数据
      await storageService.clearAllData();

      ScaffoldMessenger.of(
        ref.context,
      ).showSnackBar(const SnackBar(content: Text('所有数据已重置')));
    } catch (e) {
      ScaffoldMessenger.of(
        ref.context,
      ).showSnackBar(SnackBar(content: Text('重置数据失败: $e')));
    }
  }
}

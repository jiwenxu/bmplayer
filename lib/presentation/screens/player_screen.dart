// lib/presentation/screens/player_screen.dart
import 'package:bmplayer/domain/models/audio_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/test_data.dart';
import '../providers/audio_provider.dart';
import '../widgets/audio_controls.dart';
import '../widgets/progress_bar.dart';
import '../widgets/playlist_widget.dart';
import 'import_screen.dart';
import 'settings_screen.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 使用延迟初始化，确保 Widget 已挂载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlaylist();
    });
  }

  void _initializePlaylist() async {
    if (_isInitialized) return;

    final service = ref.read(audioPlayerServiceProvider);
    await service.setPlaylist(TestData.testAudios);

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentAudio = ref.watch(currentAudioProvider);
    final playlist = ref.watch(playlistProvider);

    // 如果播放列表为空且未初始化，显示加载状态
    if (playlist.isEmpty && !_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('音乐播放器'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐播放器'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImportScreen()),
              );
            },
            tooltip: '导入音频',
          ),
          // 添加清空播放列表按钮
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              final service = ref.read(audioPlayerServiceProvider);
              service.clearPlaylist();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: '设置',
          ),
        ],
      ),
      body: Column(
        children: [
          // 当前播放信息
          Expanded(flex: 2, child: _buildNowPlaying(currentAudio)),
          // 进度条
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: ProgressBar(),
          ),
          // 控制按钮
          const Padding(padding: EdgeInsets.all(16.0), child: AudioControls()),
          // 播放列表
          Expanded(flex: 3, child: PlaylistWidget()),
        ],
      ),
      // 添加浮动按钮用于调试，可以重新加载测试数据
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final service = ref.read(audioPlayerServiceProvider);
          service.setPlaylist(TestData.testAudios);
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildNowPlaying(AudioInfo? currentAudio) {
    if (currentAudio == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无播放内容'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 专辑封面
          Expanded(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: currentAudio.coverUrl != null
                    ? Image.network(
                        currentAudio.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.music_note, size: 60),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, size: 60),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 歌曲信息
          Text(
            currentAudio.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            currentAudio.artist ?? '未知艺术家',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

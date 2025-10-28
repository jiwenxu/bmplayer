// lib/presentation/widgets/playlist_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_provider.dart';

class PlaylistWidget extends ConsumerWidget {
  const PlaylistWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(audioPlayerServiceProvider);
    final currentIndex = ref.watch(currentIndexProvider);
    final playlist = ref.watch(playlistProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '播放列表 (${playlist.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (playlist.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      service.clearPlaylist();
                    },
                    tooltip: '清空播放列表',
                  ),
              ],
            ),
          ),
          Expanded(
            child: playlist.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.queue_music, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('播放列表为空'),
                        SizedBox(height: 8),
                        Text(
                          '点击右下角刷新按钮加载示例音乐',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: playlist.length,
                    itemBuilder: (context, index) {
                      final audio = playlist[index];
                      final isCurrent = index == currentIndex;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isCurrent
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                          ),
                          child: isCurrent
                              ? const Icon(Icons.equalizer, color: Colors.white)
                              : Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        title: Text(
                          audio.title,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                        ),
                        subtitle: Text(audio.artist ?? '未知艺术家'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_formatDuration(audio.duration)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                service.removeFromPlaylist(index);
                              },
                            ),
                          ],
                        ),
                        onTap: () => service.jumpToIndex(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

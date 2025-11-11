// lib/presentation/widgets/notification_controls.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../providers/audio_provider.dart';

class NotificationControls extends ConsumerWidget {
  const NotificationControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final isPlaying = isPlayingAsync.value ?? false;
    final service = ref.read(audioPlayerServiceProvider);

    return StreamBuilder<MediaItem?>(
      stream: AudioService.currentMediaItemStream,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        return mediaItem == null
            ? const SizedBox()
            : Column(
                children: [
                  ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: mediaItem.artUri != null
                          ? Image.network(mediaItem.artUri!.toString())
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: const Icon(Icons.music_note),
                            ),
                    ),
                    title: Text(
                      mediaItem.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      mediaItem.artist ?? '未知艺术家',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: service.previous,
                      ),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: isPlaying ? service.pause : service.play,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: service.next,
                      ),
                    ],
                  ),
                ],
              );
      },
    );
  }
}

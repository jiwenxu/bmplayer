// lib/presentation/widgets/audio_controls.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_provider.dart';

class AudioControls extends ConsumerWidget {
  const AudioControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlayingAsync = ref.watch(isPlayingProvider);
    final isPlaying = isPlayingAsync.value ?? false;
    final service = ref.read(audioPlayerServiceProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 上一首
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 36),
          onPressed: service.previous,
        ),
        const SizedBox(width: 16),
        // 播放/暂停
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: 36,
              color: Colors.white,
            ),
            onPressed: isPlaying ? service.pause : service.play,
          ),
        ),
        const SizedBox(width: 16),
        // 下一首
        IconButton(
          icon: const Icon(Icons.skip_next, size: 36),
          onPressed: service.next,
        ),
      ],
    );
  }
}

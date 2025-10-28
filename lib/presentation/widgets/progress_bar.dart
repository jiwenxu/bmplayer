// lib/presentation/widgets/progress_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_provider.dart';

class ProgressBar extends ConsumerWidget {
  const ProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionAsync = ref.watch(positionProvider);
    final durationAsync = ref.watch(durationProvider);

    final position = positionAsync.value ?? Duration.zero;
    final duration = durationAsync.value ?? Duration.zero;
    final service = ref.read(audioPlayerServiceProvider);

    final positionText = _formatDuration(position);
    final durationText = _formatDuration(duration);

    return Column(
      children: [
        Slider(
          value: position.inSeconds.toDouble(),
          min: 0,
          max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
          onChanged: duration.inSeconds > 0
              ? (value) {
                  service.seek(Duration(seconds: value.toInt()));
                }
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(positionText), Text(durationText)],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

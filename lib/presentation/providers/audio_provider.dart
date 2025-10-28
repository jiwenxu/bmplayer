// lib/presentation/providers/audio_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/services/audio_player_service.dart';
import '../../domain/models/audio_info.dart';

// 使用 ChangeNotifierProvider
final audioPlayerServiceProvider = ChangeNotifierProvider<AudioPlayerService>((
  ref,
) {
  final service = AudioPlayerService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// 简化其他 Provider
final currentAudioProvider = Provider<AudioInfo?>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.currentAudio;
});

final isPlayingProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.playerStateStream.map((state) => state.playing);
});

final playerStateProvider = StreamProvider<PlayerState>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.playerStateStream;
});

final positionProvider = StreamProvider<Duration>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.positionStream;
});

final durationProvider = StreamProvider<Duration?>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.durationStream;
});

// 直接监听 AudioPlayerService 的变化
final playlistProvider = Provider<List<AudioInfo>>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.playlist;
});

final currentIndexProvider = Provider<int>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.currentIndex;
});

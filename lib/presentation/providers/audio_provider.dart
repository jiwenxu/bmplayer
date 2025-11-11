// lib/presentation/providers/audio_provider.dart
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/services/android_audio_service.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/file_import_service.dart';
import '../../domain/models/audio_info.dart';
import '../../data/services/bilibili_parser_service.dart';
import '../../domain/models/bilibili_audio_info.dart';
import 'storage_provider.dart';

// 使用 ChangeNotifierProvider
final audioPlayerServiceProvider = ChangeNotifierProvider<AudioPlayerService>((
  ref,
) {
  final storageService = ref.watch(hiveStorageServiceProvider);
  final handler = ref.watch(audioHandlerProvider) as AndroidAudioHandler;
  final service = AudioPlayerService(handler, storageService);
  // 初始化时加载播放列表
  WidgetsBinding.instance.addPostFrameCallback((_) {
    service.loadPlaylistFromStorage();
  });

  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final audioHandlerProvider = Provider<AudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider 必须在应用入口处覆盖');
});

final bilibiliParserServiceProvider = Provider<BilibiliParserService>((ref) {
  return BilibiliParserService();
});

// 解析状态 Provider
final parsingStateProvider = StateProvider<bool>((ref) => false);

// 解析结果 Provider
final parsingResultsProvider = StateProvider<List<BilibiliAudioInfo>>(
  (ref) => [],
);

// 剪贴板内容 Provider
final clipboardContentProvider = StateProvider<String?>((ref) => null);

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

// 批量导入功能
class BatchImportNotifier extends StateNotifier<AsyncValue<List<AudioInfo>>> {
  final BilibiliParserService _parserService;
  final AudioPlayerService _audioService;

  BatchImportNotifier(this._parserService, this._audioService)
    : super(const AsyncValue.data([]));

  // 解析单个链接
  Future<void> parseSingleUrl(String url) async {
    state = const AsyncValue.loading();
    try {
      final result = await _parserService.parseUrl(url);
      if (result != null) {
        state = AsyncValue.data([result]);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // 解析多个链接
  Future<void> parseMultipleUrls(String text) async {
    state = const AsyncValue.loading();
    try {
      final results = await _parserService.parseMultiple(text);
      state = AsyncValue.data(results);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // 导入 TXT 文件并解析
  Future<void> importFromTxt() async {
    state = const AsyncValue.loading();
    try {
      final lines = await FileImportService.importFromTxt();
      if (lines.isNotEmpty) {
        final results = await _parserService.parseMultiple(lines.join('\n'));
        state = AsyncValue.data(results);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // 添加到播放列表
  Future<void> addToPlaylist(List<AudioInfo> audios) async {
    if (audios.isNotEmpty) {
      final currentPlaylist = _audioService.playlist;
      final newPlaylist = [...currentPlaylist, ...audios];
      await _audioService.setPlaylist(newPlaylist);
    }
  }

  // 清空解析结果
  void clearResults() {
    state = const AsyncValue.data([]);
  }
}

final batchImportProvider =
    StateNotifierProvider<BatchImportNotifier, AsyncValue<List<AudioInfo>>>((
      ref,
    ) {
      final parserService = ref.watch(bilibiliParserServiceProvider);
      final audioService = ref.watch(audioPlayerServiceProvider);
      return BatchImportNotifier(parserService, audioService);
    });

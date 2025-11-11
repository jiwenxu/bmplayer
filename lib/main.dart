// lib/main.dart
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/services/android_audio_service.dart';
import 'data/services/audio_focus_service.dart';
import 'data/services/cache_manager_service.dart';
import 'data/services/hive_storage_service.dart';
import 'presentation/providers/audio_provider.dart';
import 'presentation/providers/storage_provider.dart';
import 'presentation/screens/player_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioFocusService.setupAudioSession();
  final audioHandler = await AudioService.init(
    builder: AndroidAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'bmplayer_audio_channel',
      androidNotificationChannelName: 'BMPlayer 播放控制',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_stat_music',
      androidNotificationChannelDescription: 'BMPlayer 播放状态与控制',
      androidResumeOnClick: true,
      androidNotificationClickStartsActivity: true,
    ),
  );
  // 初始化存储服务
  final storageService = HiveStorageService();
  await storageService.init();
  // 初始化缓存服务
  final cacheService = CacheManagerService(storageService);
  await cacheService.init();

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
        hiveStorageServiceProvider.overrideWithValue(storageService),
        cacheManagerServiceProvider.overrideWithValue(cacheService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '音乐播放器',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const PlayerScreen(),
    );
  }
}

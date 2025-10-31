// lib/main.dart
import 'package:bmplayer/data/services/cache_manager_service.dart';
import 'package:bmplayer/data/services/hive_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/providers/storage_provider.dart';
import 'presentation/screens/player_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化存储服务
  final storageService = HiveStorageService();
  await storageService.init();
  // 初始化缓存服务
  final cacheService = CacheManagerService(storageService);
  await cacheService.init();

  runApp(ProviderScope(
    overrides: [
      hiveStorageServiceProvider.overrideWithValue(storageService),
      cacheManagerServiceProvider.overrideWithValue(cacheService),
    ],
  child: MyApp()));
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

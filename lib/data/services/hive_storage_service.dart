// lib/data/services/hive_storage_service.dart
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/audio_info.dart';

class HiveStorageService {
  static const String _playlistBoxName = 'playlist';
  static const String _settingsBoxName = 'settings';
  static const String _cacheInfoBoxName = 'cache_info';

  late Box<AudioInfo> _playlistBox;
  late Box<dynamic> _settingsBox;
  late Box<dynamic> _cacheInfoBox;
  late Directory _storageRoot;

  // 初始化 Hive
  Future<void> init() async {
    if (Platform.isWindows) {
      final exeFile = File(Platform.resolvedExecutable);
      Directory baseDir = exeFile.parent.absolute;
      final exeName = path.basename(exeFile.path).toLowerCase();
      if (exeName == 'flutter_tester.exe' || exeName == 'dart.exe') {
        baseDir = Directory.current.absolute;
      }
      _storageRoot = Directory(path.join(baseDir.path, 'bmplayer_data'));
    } else {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      _storageRoot = Directory(path.join(appDocumentDir.path, 'bmplayer_data'));
    }

    if (!_storageRoot.existsSync()) {
      await _storageRoot.create(recursive: true);
    }

    Hive.init(_storageRoot.path);

    // 注册适配器
    if (!Hive.isAdapterRegistered(AudioInfoAdapter().typeId)) {
      Hive.registerAdapter(AudioInfoAdapter());
    }

    // 打开 Boxes
    _playlistBox = await Hive.openBox<AudioInfo>(_playlistBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _cacheInfoBox = await Hive.openBox(_cacheInfoBoxName);
  }

  // 播放列表相关操作
  Future<void> savePlaylist(List<AudioInfo> playlist) async {
    await _playlistBox.clear();
    for (final audio in playlist) {
      await _playlistBox.add(_cloneAudio(audio));
    }
  }

  List<AudioInfo> getPlaylist() {
    return _playlistBox.values.map(_cloneAudio).toList();
  }

  Future<void> addToPlaylist(AudioInfo audio) async {
    await _playlistBox.add(_cloneAudio(audio));
  }

  Future<void> removeFromPlaylist(int index) async {
    await _playlistBox.deleteAt(index);
  }

  Future<void> updateAudioInfo(int index, AudioInfo audio) async {
    await _playlistBox.putAt(index, _cloneAudio(audio));
  }

  Future<void> clearPlaylist() async {
    await _playlistBox.clear();
  }

  // 设置相关操作
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  // 缓存信息管理
  Future<void> updateCacheInfo(
    String audioId,
    String filePath,
    int fileSize,
  ) async {
    await _cacheInfoBox.put(audioId, {
      'filePath': filePath,
      'fileSize': fileSize,
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeCacheInfo(String audioId) async {
    await _cacheInfoBox.delete(audioId);
  }

  Map<dynamic, dynamic>? getCacheInfo(String audioId) {
    return _cacheInfoBox.get(audioId);
  }

  Map<String, Map<dynamic, dynamic>> getAllCacheInfo() {
    final allCache = <String, Map<dynamic, dynamic>>{};
    for (final key in _cacheInfoBox.keys) {
      allCache[key.toString()] = _cacheInfoBox.get(key);
    }
    return allCache;
  }

  // 获取缓存总大小
  int getTotalCacheSize() {
    int totalSize = 0;
    for (final key in _cacheInfoBox.keys) {
      final info = _cacheInfoBox.get(key);
      if (info != null && info['fileSize'] != null) {
        totalSize += info['fileSize'] as int;
      }
    }
    return totalSize;
  }

  // 清理所有数据
  Future<void> clearAllData() async {
    await _playlistBox.clear();
    await _settingsBox.clear();
    await _cacheInfoBox.clear();
  }

  Directory get storageRoot => _storageRoot;

  AudioInfo _cloneAudio(AudioInfo audio) {
    return AudioInfo(
      id: audio.id,
      title: audio.title,
      audioUrl: audio.audioUrl,
      coverUrl: audio.coverUrl,
      audioPath: audio.audioPath,
      duration: audio.duration,
      artist: audio.artist,
      addedTime: audio.addedTime,
    );
  }

  // 关闭 Hive
  Future<void> close() async {
    await _playlistBox.close();
    await _settingsBox.close();
    await _cacheInfoBox.close();
  }
}

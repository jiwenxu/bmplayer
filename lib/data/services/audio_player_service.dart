// lib/data/services/audio_player_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../domain/models/audio_info.dart';
import 'cache_manager_service.dart';
import 'hive_storage_service.dart';

class AudioPlayerService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final HiveStorageService _storageService;
  final CacheManagerService _cacheService;

  final List<AudioInfo> _playlist = [];
  int _currentIndex = 0;
  bool _autoDownload = true;

  // 播放状态流
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  List<AudioInfo> get playlist => List.unmodifiable(_playlist);
  bool get autoDownload => _autoDownload;
  int get currentIndex => _currentIndex;
  AudioInfo? get currentAudio =>
      _playlist.isEmpty ? null : _playlist[_currentIndex];

  AudioPlayerService(this._storageService, this._cacheService) {
    // 监听播放完成事件，自动播放下一首
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        next();
      }
    });
    // 加载设置
    _loadSettings();
  }

  // 从存储加载播放列表
  Future<void> loadPlaylistFromStorage() async {
    final storedPlaylist = _storageService.getPlaylist();
    if (storedPlaylist.isNotEmpty) {
      await setPlaylist(storedPlaylist);
    }
  }

  // 加载设置
  void _loadSettings() {
    _autoDownload = _storageService.getSetting(
      'auto_download',
      defaultValue: false,
    );
  }

  // 保存设置
  // Future<void> _saveSettings() async {
  //   await _storageService.saveSetting('auto_download', _autoDownload);
  // }

  // 初始化播放列表
  Future<void> setPlaylist(List<AudioInfo> audios, {int startIndex = 0}) async {
    _playlist.clear();
    _playlist.addAll(audios);
    _currentIndex = audios.isEmpty ? 0 : startIndex.clamp(0, audios.length - 1);

    // 保存到存储
    await _storageService.savePlaylist(_playlist);

    notifyListeners(); // 通知监听者状态已更新

    if (audios.isNotEmpty) {
      await _loadCurrentAudio();
    }
  }

  // 播放/暂停
  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  // 上一首/下一首
  Future<void> next() async {
    if (_playlist.isEmpty) return;

    _currentIndex = (_currentIndex + 1) % _playlist.length;
    notifyListeners(); // 通知监听者当前索引已更新
    await _loadCurrentAudio();
    await play();
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;

    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    notifyListeners(); // 通知监听者当前索引已更新
    await _loadCurrentAudio();
    await play();
  }

  // 跳转到指定位置
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // 跳转到指定音频
  Future<void> jumpToIndex(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      notifyListeners(); // 通知监听者当前索引已更新
      await _loadCurrentAudio();
      await play();
    }
  }

  // 添加单首音频到播放列表
  Future<void> addToPlaylist(AudioInfo audio) async {
    _playlist.add(audio);
    await _storageService.savePlaylist(_playlist);
    notifyListeners(); // 通知监听者播放列表已更新
  }

  // 从播放列表移除音频
  Future<void> removeFromPlaylist(int index) async {
    if (index >= 0 && index < _playlist.length) {
      // 如果移除的是已缓存的音频，可以选择删除缓存文件
      final removedAudio = _playlist[index];
      if (removedAudio.isCached) {
        await File(removedAudio.audioPath!).delete();
      }
      _playlist.removeAt(index);
      // 如果移除的是当前播放的音频，需要调整当前索引
      if (index == _currentIndex) {
        _currentIndex = _currentIndex.clamp(0, _playlist.length - 1);
        if (_playlist.isNotEmpty) {
          await _loadCurrentAudio();
        }
      } else if (index < _currentIndex) {
        _currentIndex--;
      }
      await _storageService.savePlaylist(_playlist);
      notifyListeners(); // 通知监听者播放列表已更新
    }
  }

  // 清空播放列表
  Future<void> clearPlaylist() async {
    _playlist.forEach((audio) {
      if (audio.isCached) {
        File(audio.audioPath!).delete();
      }
    });
    _playlist.clear();
    _currentIndex = 0;
    await _audioPlayer.stop();
    await _storageService.savePlaylist(_playlist);
    notifyListeners(); // 通知监听者播放列表已更新
  }

  // 加载当前音频
  Future<void> _loadCurrentAudio() async {
    if (_playlist.isEmpty) return;

    final current = _playlist[_currentIndex];
    try {
      final playSource = current.isCached ? current.audioPath! : current.audioUrl;
      await _audioPlayer.setUrl(playSource);
    } catch (e) {
      print('Error loading audio: $e');
      // 自动跳到下一首
      await next();
    }
  }

  // 释放资源
  @override
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    super.dispose();
  }
}

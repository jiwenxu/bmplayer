import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/models/audio_info.dart';
import 'android_audio_service.dart';
import 'hive_storage_service.dart';

class AudioPlayerService with ChangeNotifier {
  final AndroidAudioHandler _audioHandler;
  final HiveStorageService _storageService;

  final List<AudioInfo> _playlist = [];
  int _currentIndex = 0;
  bool _autoDownload = true;

  StreamSubscription<int?>? _indexSubscription;

  Stream<PlayerState> get playerStateStream => _audioHandler.playerStateStream;
  Stream<Duration?> get durationStream => _audioHandler.durationStream;
  Stream<Duration> get positionStream => _audioHandler.positionStream;

  List<AudioInfo> get playlist => List.unmodifiable(_playlist);
  bool get autoDownload => _autoDownload;
  int get currentIndex => _currentIndex;
  AudioInfo? get currentAudio =>
      _playlist.isEmpty ? null : _playlist[_currentIndex];

  AudioPlayerService(
    this._audioHandler,
    this._storageService,
  ) {
    _indexSubscription = _audioHandler.currentIndexStream.listen((index) {
      if (index == null || _playlist.isEmpty) return;
      final clamped = index.clamp(0, _playlist.length - 1);
      if (clamped != _currentIndex) {
        _currentIndex = clamped;
        notifyListeners();
      }
    });
    _loadSettings();
  }

  Future<void> loadPlaylistFromStorage() async {
    final storedPlaylist = _storageService.getPlaylist();
    if (storedPlaylist.isNotEmpty) {
      await setPlaylist(storedPlaylist);
    }
  }

  void _loadSettings() {
    _autoDownload = _storageService.getSetting(
      'auto_download',
      defaultValue: false,
    );
  }

  Future<void> setPlaylist(List<AudioInfo> audios, {int startIndex = 0}) async {
    _playlist
      ..clear()
      ..addAll(audios);
    _currentIndex =
        audios.isEmpty ? 0 : startIndex.clamp(0, audios.length - 1);

    await _storageService.savePlaylist(_playlist);
    notifyListeners();

    await _audioHandler.setPlaylist(
      _playlist,
      startIndex: _currentIndex,
    );
  }

  Future<void> play() => _audioHandler.play();

  Future<void> pause() => _audioHandler.pause();

  Future<void> next() async {
    if (_playlist.isEmpty) return;
    await _audioHandler.skipToNext();
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    await _audioHandler.skipToPrevious();
  }

  Future<void> seek(Duration position) => _audioHandler.seek(position);

  Future<void> jumpToIndex(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      notifyListeners();
      await _audioHandler.skipToQueueItem(index);
    }
  }

  Future<void> addToPlaylist(AudioInfo audio) async {
    _playlist.add(audio);
    await _storageService.savePlaylist(_playlist);
    await _audioHandler.setPlaylist(
      _playlist,
      startIndex: _currentIndex.clamp(0, _playlist.length - 1),
    );
    notifyListeners();
  }

  Future<void> removeFromPlaylist(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    final removedAudio = _playlist.removeAt(index);
    if (removedAudio.isCached && removedAudio.audioPath != null) {
      final file = File(removedAudio.audioPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (_playlist.isEmpty) {
      _currentIndex = 0;
      await _audioHandler.setPlaylist(const []);
    } else {
      if (index <= _currentIndex) {
        _currentIndex = (_currentIndex - 1).clamp(0, _playlist.length - 1);
      }
      await _audioHandler.setPlaylist(
        _playlist,
        startIndex: _currentIndex.clamp(0, _playlist.length - 1),
      );
    }

    await _storageService.savePlaylist(_playlist);
    notifyListeners();
  }

  Future<void> clearPlaylist() async {
    for (final audio in _playlist) {
      if (audio.isCached && audio.audioPath != null) {
        final file = File(audio.audioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    _playlist.clear();
    _currentIndex = 0;
    await _audioHandler.stop();
    await _audioHandler.setPlaylist(const []);
    await _storageService.savePlaylist(_playlist);
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _indexSubscription?.cancel();
    super.dispose();
  }
}

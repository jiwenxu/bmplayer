// lib/data/services/android_audio_service.dart

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/models/audio_info.dart';

class AndroidAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  AndroidAudioHandler() {
    _registerListeners();
  }

  final AudioPlayer _player = AudioPlayer();
  final List<AudioInfo> _playlist = [];
  final List<MediaItem> _mediaItems = [];

  ConcatenatingAudioSource? _audioSource;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  int? get currentIndex => _player.currentIndex;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  List<AudioInfo> get playlist => List.unmodifiable(_playlist);

  Future<void> setPlaylist(
    List<AudioInfo> playlist, {
    int startIndex = 0,
  }) async {
    _playlist
      ..clear()
      ..addAll(playlist);
    _mediaItems
      ..clear()
      ..addAll(_playlist.map(_audioInfoToMediaItem));
    queue.add(_mediaItems);

    if (_playlist.isEmpty) {
      await _player.stop();
      mediaItem.add(null);
      return;
    }

    _audioSource = ConcatenatingAudioSource(
      children: [
        for (var i = 0; i < _playlist.length; i++)
          _buildAudioSource(_playlist[i], _mediaItems[i]),
      ],
    );

    await _player.setAudioSource(
      _audioSource!,
      initialIndex: startIndex.clamp(0, _playlist.length - 1),
      initialPosition: Duration.zero,
    );

    await _updateCurrentQueueIndex(_player.currentIndex ?? startIndex);
    _broadcastState(_player.playbackEvent);
  }

  Future<void> playAt(int index) async {
    if (_playlist.isEmpty) return;

    final target = index.clamp(0, _playlist.length - 1);
    await _player.seek(Duration.zero, index: target);
    await play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      await play();
    } else {
      await _player.stop();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      await play();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await playAt(index);
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> fastForward() async {
    final newPosition = _player.position + const Duration(seconds: 15);
    await _player.seek(newPosition);
  }

  @override
  Future<void> rewind() async {
    final newPosition = _player.position - const Duration(seconds: 15);
    await _player.seek(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
  }

  AudioSource _buildAudioSource(AudioInfo info, MediaItem mediaItem) {
    final uri = info.isCached
        ? Uri.file(info.audioPath!)
        : Uri.parse(info.audioUrl);

    return AudioSource.uri(uri, tag: mediaItem);
  }

  MediaItem _audioInfoToMediaItem(AudioInfo info) {
    final extras = <String, dynamic>{
      'audioUrl': info.audioUrl,
      'audioPath': info.audioPath,
      'isCached': info.isCached,
    };

    return MediaItem(
      id: info.id,
      title: info.title,
      artist: info.artist ?? '未知艺术家',
      album: 'B站音频',
      duration: info.duration,
      artUri: info.coverUrl != null ? Uri.parse(info.coverUrl!) : null,
      extras: extras,
    );
  }

  void _registerListeners() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.currentIndexStream.listen((index) {
      if (index == null) return;
      _updateCurrentQueueIndex(index);
    });
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  Future<void> _updateCurrentQueueIndex(int index) async {
    if (index < 0 || index >= _mediaItems.length) return;
    mediaItem.add(_mediaItems[index]);
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final processingState = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState]!;

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
}

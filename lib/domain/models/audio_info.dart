// lib/domain/models/audio_info.dart
class AudioInfo {
  final String id;
  final String title;
  final String audioUrl;
  final String? coverUrl;
  final Duration duration;
  final String? artist;
  final DateTime addedTime;

  AudioInfo({
    required this.id,
    required this.title,
    required this.audioUrl,
    this.coverUrl,
    required this.duration,
    this.artist,
    DateTime? addedTime,
  }) : addedTime = addedTime ?? DateTime.now();

  AudioInfo copyWith({
    String? id,
    String? title,
    String? audioUrl,
    String? coverUrl,
    Duration? duration,
    String? artist,
    DateTime? addedTime,
  }) {
    return AudioInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      duration: duration ?? this.duration,
      artist: artist ?? this.artist,
      addedTime: addedTime ?? this.addedTime,
    );
  }
}
// lib/domain/models/audio_info.dart
import 'package:hive/hive.dart';

part 'audio_info.g.dart';

@HiveType(typeId: 0)
class AudioInfo extends HiveObject{
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String audioUrl;
  @HiveField(3)
  final String? coverUrl;
  @HiveField(4)
  final String? audioPath;
  @HiveField(5)
  final Duration duration;
  @HiveField(6)
  final String? artist;
  @HiveField(7)
  final DateTime addedTime;

  AudioInfo({
    required this.id,
    required this.title,
    required this.audioUrl,
    this.coverUrl,
    this.audioPath,
    required this.duration,
    this.artist,
    DateTime? addedTime,
  }) : addedTime = addedTime ?? DateTime.now();

  AudioInfo copyWith({
    String? id,
    String? title,
    String? audioUrl,
    String? coverUrl,
    String? audioPath,
    Duration? duration,
    String? artist,
    DateTime? addedTime,
  }) {
    return AudioInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      audioPath: audioPath ?? this.audioPath,
      duration: duration ?? this.duration,
      artist: artist ?? this.artist,
      addedTime: addedTime ?? this.addedTime,
    );
  }

  // 检查是否有本地缓存
  bool get isCached => audioPath != null && audioPath!.isNotEmpty;

  // 获取播放源：优先使用本地缓存
  String get playSource => isCached ? audioPath! : audioUrl;
}
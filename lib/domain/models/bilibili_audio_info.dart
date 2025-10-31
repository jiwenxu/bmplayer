// lib/data/models/bilibili_audio_info.dart
import 'package:hive/hive.dart';

import './audio_info.dart';

class BilibiliAudioInfo extends AudioInfo {

  final String originalUrl;

  final String? bvid;

  final String? aid;

  BilibiliAudioInfo({
    required super.id,
    required super.title,
    required super.audioUrl,
    super.coverUrl,
    super.audioPath,
    super.artist,
    required super.duration,
    required this.originalUrl,
    this.bvid,
    this.aid,
    super.addedTime,
  });

  @override
  BilibiliAudioInfo copyWith({
    String? id,
    String? title,
    String? audioUrl,
    String? coverUrl,
    String? audioPath,
    String? artist,
    Duration? duration,
    DateTime? addedTime,
    String? originalUrl,
    String? bvid,
    String? aid,
  }) {
    return BilibiliAudioInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      audioPath: audioPath ?? this.audioPath,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      addedTime: addedTime ?? this.addedTime,
      originalUrl: originalUrl ?? this.originalUrl,
      bvid: bvid ?? this.bvid,
      aid: aid ?? this.aid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'audioPath': audioPath,
      'artist': artist,
      'duration': duration.inSeconds,
      'addedTime': addedTime.toIso8601String(),
      'originalUrl': originalUrl,
      'bvid': bvid,
      'aid': aid,
    };
  }

  factory BilibiliAudioInfo.fromJson(Map<String, dynamic> json) {
    return BilibiliAudioInfo(
      id: json['id'],
      title: json['title'],
      audioUrl: json['audioUrl'],
      coverUrl: json['coverUrl'],
      audioPath: json['audioPath'],
      artist: json['artist'],
      duration: Duration(seconds: json['duration']),
      addedTime: DateTime.parse(json['addedTime']),
      originalUrl: json['originalUrl'],
      bvid: json['bvid'],
      aid: json['aid'],
    );
  }
}

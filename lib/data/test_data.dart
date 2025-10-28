// lib/data/test_data.dart
import '../domain/models/audio_info.dart';

class TestData {
  static List<AudioInfo> get testAudios => [
    AudioInfo(
      id: '1',
      title: '测试音乐 1',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      coverUrl: 'https://picsum.photos/200/200',
      duration: const Duration(minutes: 3, seconds: 45),
      artist: '测试艺术家',
    ),
    AudioInfo(
      id: '2',
      title: '测试音乐 2',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      coverUrl: 'https://picsum.photos/200/201',
      duration: const Duration(minutes: 4, seconds: 20),
      artist: '测试艺术家',
    ),
    AudioInfo(
      id: '3',
      title: '测试音乐 3',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      coverUrl: 'https://picsum.photos/200/202',
      duration: const Duration(minutes: 3, seconds: 15),
      artist: '测试艺术家',
    ),
  ];
}

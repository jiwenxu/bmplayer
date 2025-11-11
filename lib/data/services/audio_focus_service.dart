// lib/data/services/audio_focus_service.dart
import 'package:audio_session/audio_session.dart';

class AudioFocusService {
  static Future<void> setupAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    // 监听音频焦点变化
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // 降低音量
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            // 暂停播放
            break;
        }
      } else {
        // 恢复播放
      }
    });

    // 监听设备断开事件
    session.becomingNoisyEventStream.listen((_) {
      // 当耳机断开时暂停播放
    });
  }
}

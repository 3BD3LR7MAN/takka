import 'package:flutter/services.dart';
import 'audio_interface.dart';

export 'audio_interface.dart';

class NativeAudioBridge implements AudioPlatformBridge {
  @override
  void playEffect(String effect, String theme) {
    if (theme == 'muted') return;
    try {
      if (effect == 'task_done' || effect == 'event_saved') {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
      } else if (effect == 'click') {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  @override
  void playRingtone(String ringtoneId) {
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  @override
  void stopRingtone() {}

  @override
  void startAlarm(String ringtoneId) {
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  @override
  void stopAlarm() {}
}

AudioPlatformBridge getAudioBridge() => NativeAudioBridge();

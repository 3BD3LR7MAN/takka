import 'dart:js_interop';

import 'audio_interface.dart';

export 'audio_interface.dart';

@JS('takkaAudio.playEffect')
external void _jsPlayEffect(JSString effect, JSString theme);

@JS('takkaAudio.playRingtone')
external void _jsPlayRingtone(JSString ringtoneId);

@JS('takkaAudio.stopRingtone')
external void _jsStopRingtone();

@JS('takkaAudio.startAlarm')
external void _jsStartAlarm(JSString ringtoneId);

@JS('takkaAudio.stopAlarm')
external void _jsStopAlarm();

class WebAudioBridge implements AudioPlatformBridge {
  @override
  void playEffect(String effect, String theme) {
    try {
      _jsPlayEffect(effect.toJS, theme.toJS);
    } catch (_) {}
  }

  @override
  void playRingtone(String ringtoneId, {String? customPath}) {
    try {
      _jsPlayRingtone(ringtoneId.toJS);
    } catch (_) {}
  }

  @override
  void stopRingtone() {
    try {
      _jsStopRingtone();
    } catch (_) {}
  }

  @override
  void startAlarm(
    String ringtoneId, {
    String? customPath,
    required String eventId,
    required String title,
    String? location,
    required String importance,
    required int fireAtMillis,
  }) {
    try {
      _jsStartAlarm(ringtoneId.toJS);
    } catch (_) {}
  }

  @override
  void stopAlarm() {
    try {
      _jsStopAlarm();
    } catch (_) {}
  }

  @override
  Future<void> configureAlarm({
    required bool enabled,
    required String ringtoneId,
    String? customPath,
    required int snoozeMinutes,
  }) async {}

  @override
  Future<void> scheduleBackgroundAlarm({
    required int alarmId,
    required String eventId,
    required String title,
    String? location,
    required String importance,
    required int fireAtMillis,
  }) async {}

  @override
  Future<void> cancelBackgroundAlarm(int alarmId) async {}

  @override
  Future<Map<String, String>?> pickAlarmSound() async => null;

  @override
  Future<void> clearCustomAlarmSound() async {}
}

AudioPlatformBridge getAudioBridge() => WebAudioBridge();

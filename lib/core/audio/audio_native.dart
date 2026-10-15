import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_interface.dart';

export 'audio_interface.dart';

const _audioChannel = MethodChannel('com.example.takka/audio');
bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

class NativeAudioBridge implements AudioPlatformBridge {
  Future<void> _invoke(String method, [Map<String, Object?>? arguments]) async {
    try {
      await _audioChannel.invokeMethod<void>(method, arguments);
    } catch (error, stackTrace) {
      debugPrint('[Audio] $method failed: $error\n$stackTrace');
    }
  }

  @override
  void playEffect(String effect, String theme) {
    if (!_isAndroid) {
      try {
        HapticFeedback.selectionClick();
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
      return;
    }
    unawaited(_invoke('playEffect', {'effect': effect, 'theme': theme}));
  }

  @override
  void playRingtone(String ringtoneId, {String? customPath}) {
    if (!_isAndroid) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
      return;
    }
    unawaited(
      _invoke('playRingtone', {
        'ringtoneId': ringtoneId,
        if (customPath != null) 'customPath': customPath,
      }),
    );
  }

  @override
  void stopRingtone() {
    if (_isAndroid) unawaited(_invoke('stopRingtone'));
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
    if (!_isAndroid) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
      return;
    }
    unawaited(
      _invoke('startAlarm', {
        'ringtoneId': ringtoneId,
        'eventId': eventId,
        'title': title,
        'location': location,
        'importance': importance,
        'fireAtMillis': fireAtMillis,
        if (customPath != null) 'customPath': customPath,
      }),
    );
  }

  @override
  void stopAlarm() {
    if (_isAndroid) unawaited(_invoke('stopAlarm'));
  }

  @override
  Future<void> configureAlarm({
    required bool enabled,
    required String ringtoneId,
    String? customPath,
    required int snoozeMinutes,
  }) =>
      _isAndroid
          ? _invoke('configureAlarm', {
              'enabled': enabled,
              'ringtoneId': ringtoneId,
              'customPath': customPath,
              'snoozeMinutes': snoozeMinutes,
            })
          : Future<void>.value();

  @override
  Future<void> scheduleBackgroundAlarm({
    required int alarmId,
    required String eventId,
    required String title,
    String? location,
    required String importance,
    required int fireAtMillis,
  }) =>
      _isAndroid
          ? _invoke('scheduleBackgroundAlarm', {
              'alarmId': alarmId,
              'eventId': eventId,
              'title': title,
              'location': location,
              'importance': importance,
              'fireAtMillis': fireAtMillis,
            })
          : Future<void>.value();

  @override
  Future<void> cancelBackgroundAlarm(int alarmId) => _isAndroid
      ? _invoke('cancelBackgroundAlarm', {'alarmId': alarmId})
      : Future<void>.value();

  @override
  Future<Map<String, String>?> pickAlarmSound() async {
    if (!_isAndroid) return null;
    try {
      return await _audioChannel.invokeMapMethod<String, String>(
        'pickAlarmSound',
      );
    } catch (error, stackTrace) {
      debugPrint('[Audio] local alarm file picker failed: $error\n$stackTrace');
      return null;
    }
  }

  @override
  Future<void> clearCustomAlarmSound() async {
    if (_isAndroid) await _invoke('clearCustomAlarmSound');
  }
}

AudioPlatformBridge getAudioBridge() => NativeAudioBridge();

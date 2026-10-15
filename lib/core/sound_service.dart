import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'audio/audio_bridge.dart';

class AlarmState {
  final String eventId;
  final String title;
  final String? location;
  final DateTime time;
  final String importance;

  const AlarmState({
    required this.eventId,
    required this.title,
    this.location,
    required this.time,
    required this.importance,
  });
}

class SoundService {
  SoundService._();
  static final instance = SoundService._();

  static const _storage = FlutterSecureStorage();

  bool soundEffectsEnabled = true;
  String soundTheme = 'chimes'; // chimes, digital, pops, clicks, muted
  String ringtone = 'gentle_chime'; // gentle_chime, digital_pulse, zen_bell, radar, crystal_harp, classic_alarm
  bool alarmModeEnabled = true;
  int snoozeDurationMinutes = 5;

  final ValueNotifier<AlarmState?> activeAlarm = ValueNotifier<AlarmState?>(null);
  final ValueNotifier<String?> playingPreviewRingtone = ValueNotifier<String?>(null);
  Timer? _previewTimer;

  static const List<Map<String, String>> availableThemes = [
    {'id': 'chimes', 'nameEn': 'Melodic Chimes', 'nameAr': 'نغمات رنانة'},
    {'id': 'digital', 'nameEn': 'Digital Synth', 'nameAr': 'إلكتروني حديث'},
    {'id': 'pops', 'nameEn': 'Soft Bubble Pops', 'nameAr': 'فقاعات ناعمة'},
    {'id': 'clicks', 'nameEn': 'Tactile Clicks', 'nameAr': 'نقرات ميكانيكية'},
    {'id': 'muted', 'nameEn': 'Muted (Silent)', 'nameAr': 'صامت'},
  ];

  static const List<Map<String, String>> availableRingtones = [
    {'id': 'gentle_chime', 'nameEn': 'Gentle Chime', 'nameAr': 'رنين هادئ'},
    {'id': 'digital_pulse', 'nameEn': 'Digital Pulse', 'nameAr': 'نبض رقمي'},
    {'id': 'zen_bell', 'nameEn': 'Zen Bell', 'nameAr': 'جرس هادئ'},
    {'id': 'radar', 'nameEn': 'Radar Alert', 'nameAr': 'تنبيه رادار'},
    {'id': 'crystal_harp', 'nameEn': 'Crystal Harp', 'nameAr': 'قيثارة بلورية'},
    {'id': 'classic_alarm', 'nameEn': 'Classic Alarm', 'nameAr': 'منبه كلاسيكي'},
  ];

  Future<void> init() async {
    try {
      final sfx = await _storage.read(key: 'sound_effects_enabled');
      if (sfx != null) soundEffectsEnabled = sfx == 'true';

      final theme = await _storage.read(key: 'sound_theme');
      if (theme != null && theme.isNotEmpty) soundTheme = theme;

      final ring = await _storage.read(key: 'reminder_ringtone');
      if (ring != null && ring.isNotEmpty) ringtone = ring;

      final alarm = await _storage.read(key: 'alarm_mode_enabled');
      if (alarm != null) alarmModeEnabled = alarm == 'true';

      final snooze = await _storage.read(key: 'snooze_duration_minutes');
      if (snooze != null) snoozeDurationMinutes = int.tryParse(snooze) ?? 5;
    } catch (_) {}
  }

  Future<void> setSoundEffectsEnabled(bool value) async {
    soundEffectsEnabled = value;
    await _storage.write(key: 'sound_effects_enabled', value: value.toString());
  }

  Future<void> setSoundTheme(String theme) async {
    soundTheme = theme;
    await _storage.write(key: 'sound_theme', value: theme);
    if (soundEffectsEnabled) {
      playEffect('event_saved');
    }
  }

  Future<void> setRingtone(String ringtoneId) async {
    ringtone = ringtoneId;
    await _storage.write(key: 'reminder_ringtone', value: ringtoneId);
    previewRingtone(ringtoneId);
  }

  Future<void> setAlarmModeEnabled(bool value) async {
    alarmModeEnabled = value;
    await _storage.write(key: 'alarm_mode_enabled', value: value.toString());
  }

  Future<void> setSnoozeDuration(int minutes) async {
    snoozeDurationMinutes = minutes;
    await _storage.write(key: 'snooze_duration_minutes', value: minutes.toString());
  }

  void playEffect(String effect) {
    if (!soundEffectsEnabled || soundTheme == 'muted') return;
    audioBridge.playEffect(effect, soundTheme);
  }

  void playTaskDone() => playEffect('task_done');
  void playEventSaved() => playEffect('event_saved');
  void playMascotTap() => playEffect('mascot');
  void playClick() => playEffect('click');
  void playDelete() => playEffect('delete');

  void previewRingtone(String ringtoneId) {
    stopRingtonePreview();
    playingPreviewRingtone.value = ringtoneId;
    audioBridge.playRingtone(ringtoneId);
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(seconds: 4), () {
      stopRingtonePreview();
    });
  }

  void stopRingtonePreview() {
    _previewTimer?.cancel();
    _previewTimer = null;
    playingPreviewRingtone.value = null;
    audioBridge.stopRingtone();
  }

  void triggerAlarm({
    required String eventId,
    required String title,
    String? location,
    required DateTime time,
    required String importance,
  }) {
    activeAlarm.value = AlarmState(
      eventId: eventId,
      title: title,
      location: location,
      time: time,
      importance: importance,
    );
    audioBridge.startAlarm(ringtone);
  }

  void dismissAlarm() {
    audioBridge.stopAlarm();
    activeAlarm.value = null;
  }

  void snoozeAlarm({int? minutes}) {
    audioBridge.stopAlarm();
    activeAlarm.value = null;
    playEffect('click');
  }
}

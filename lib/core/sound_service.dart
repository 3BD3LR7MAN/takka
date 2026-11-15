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
  String ringtone =
      'gentle_chime'; // gentle_chime, digital_pulse, zen_bell, radar, crystal_harp, classic_alarm
  String? customRingtonePath;
  String? customRingtoneName;
  bool alarmModeEnabled = true;
  int snoozeDurationMinutes = 5;

  final ValueNotifier<AlarmState?> activeAlarm = ValueNotifier<AlarmState?>(
    null,
  );
  final ValueNotifier<String?> playingPreviewRingtone = ValueNotifier<String?>(
    null,
  );
  Timer? _previewTimer;
  Timer? _snoozeTimer;

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
    {
      'id': 'classic_alarm',
      'nameEn': 'Classic Alarm',
      'nameAr': 'منبه كلاسيكي',
    },
  ];

  Future<void> init() async {
    try {
      final sfx = await _storage.read(key: 'sound_effects_enabled');
      if (sfx != null) soundEffectsEnabled = sfx == 'true';

      final theme = await _storage.read(key: 'sound_theme');
      if (theme != null && theme.isNotEmpty) soundTheme = theme;

      final ring = await _storage.read(key: 'reminder_ringtone');
      if (ring != null && ring.isNotEmpty) ringtone = ring;

      customRingtonePath = await _storage.read(key: 'custom_alarm_sound_path');
      customRingtoneName = await _storage.read(key: 'custom_alarm_sound_name');

      final alarm = await _storage.read(key: 'alarm_mode_enabled');
      if (alarm != null) alarmModeEnabled = alarm == 'true';

      final snooze = await _storage.read(key: 'snooze_duration_minutes');
      if (snooze != null) {
        final parsed = int.tryParse(snooze) ?? 5;
        snoozeDurationMinutes = [5, 10, 15].contains(parsed) ? parsed : 5;
      }
    } catch (_) {}
    await _syncNativeAlarmConfiguration();
  }

  Future<void> setSoundEffectsEnabled(bool value) async {
    soundEffectsEnabled = value;
    await _storage.write(key: 'sound_effects_enabled', value: value.toString());
  }

  Future<void> setSoundTheme(String theme) async {
    soundTheme = theme;
    await _storage.write(key: 'sound_theme', value: theme);
    if (soundEffectsEnabled) playEffect('event_saved');
  }

  Future<void> setRingtone(String ringtoneId) async {
    ringtone = ringtoneId;
    await _storage.write(key: 'reminder_ringtone', value: ringtoneId);
    await _syncNativeAlarmConfiguration();
    previewRingtone(ringtoneId);
  }

  Future<bool> pickLocalAlarmSound() async {
    final selected = await audioBridge.pickAlarmSound();
    final path = selected?['path'];
    if (path == null || path.isEmpty) return false;
    customRingtonePath = path;
    customRingtoneName = selected?['name'] ?? 'Custom alarm sound';
    await _storage.write(key: 'custom_alarm_sound_path', value: path);
    await _storage.write(
      key: 'custom_alarm_sound_name',
      value: customRingtoneName!,
    );
    await _syncNativeAlarmConfiguration();
    previewRingtone(ringtone);
    return true;
  }

  Future<void> clearCustomAlarmSound() async {
    stopRingtonePreview();
    await audioBridge.clearCustomAlarmSound();
    customRingtonePath = null;
    customRingtoneName = null;
    await _storage.delete(key: 'custom_alarm_sound_path');
    await _storage.delete(key: 'custom_alarm_sound_name');
    await _syncNativeAlarmConfiguration();
  }

  Future<void> setAlarmModeEnabled(bool value) async {
    alarmModeEnabled = value;
    await _storage.write(key: 'alarm_mode_enabled', value: value.toString());
    await _syncNativeAlarmConfiguration();
    if (!value) dismissAlarm();
  }

  Future<void> setSnoozeDuration(int minutes) async {
    snoozeDurationMinutes = [5, 10, 15].contains(minutes) ? minutes : 5;
    await _storage.write(
      key: 'snooze_duration_minutes',
      value: snoozeDurationMinutes.toString(),
    );
    await _syncNativeAlarmConfiguration();
  }

  Future<void> _syncNativeAlarmConfiguration() => audioBridge.configureAlarm(
        enabled: alarmModeEnabled,
        ringtoneId: ringtone,
        customPath: customRingtonePath,
        snoozeMinutes: snoozeDurationMinutes,
      );

  Future<void> scheduleBackgroundAlarm({
    required int alarmId,
    required String eventId,
    required String title,
    String? location,
    required String importance,
    required DateTime fireAt,
  }) async {
    if (!alarmModeEnabled) return;
    await audioBridge.scheduleBackgroundAlarm(
      alarmId: alarmId,
      eventId: eventId,
      title: title,
      location: location,
      importance: importance,
      fireAtMillis: fireAt.millisecondsSinceEpoch,
    );
  }

  Future<void> cancelBackgroundAlarm(int alarmId) =>
      audioBridge.cancelBackgroundAlarm(alarmId);

  Future<void> cancelBackgroundAlarmsForEvent(String eventId) =>
      audioBridge.cancelBackgroundAlarmsForEvent(eventId);

  Future<void> reconcileNativeAlarmState() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    Map<String, Object?>? nativeAlarm;
    try {
      nativeAlarm = await audioBridge.getActiveBackgroundAlarm();
    } catch (error, stackTrace) {
      debugPrint(
          '[Audio] active alarm reconciliation failed: $error\n$stackTrace');
      return;
    }
    final current = activeAlarm.value;
    if (nativeAlarm == null) {
      if (current != null) {
        _snoozeTimer?.cancel();
        _snoozeTimer = null;
        activeAlarm.value = null;
      }
      return;
    }
    final eventId = nativeAlarm['event_id'];
    final title = nativeAlarm['event_title'];
    final fireAt = nativeAlarm['fire_at_millis'];
    if (eventId is! String || title is! String || fireAt is! num) return;
    if (current?.eventId == eventId &&
        current?.time.millisecondsSinceEpoch == fireAt.toInt()) {
      return;
    }
    activeAlarm.value = AlarmState(
      eventId: eventId,
      title: title,
      location: nativeAlarm['event_location'] as String?,
      time: DateTime.fromMillisecondsSinceEpoch(fireAt.toInt()),
      importance: nativeAlarm['event_importance'] as String? ?? 'normal',
    );
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
    audioBridge.playRingtone(ringtoneId, customPath: customRingtonePath);
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(seconds: 4), stopRingtonePreview);
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
    _snoozeTimer?.cancel();
    _snoozeTimer = null;
    if (!alarmModeEnabled) return;
    activeAlarm.value = AlarmState(
      eventId: eventId,
      title: title,
      location: location,
      time: time,
      importance: importance,
    );
    audioBridge.startAlarm(
      ringtone,
      customPath: customRingtonePath,
      eventId: eventId,
      title: title,
      location: location,
      importance: importance,
      fireAtMillis: time.millisecondsSinceEpoch,
    );
  }

  void dismissAlarm() {
    _snoozeTimer?.cancel();
    _snoozeTimer = null;
    audioBridge.stopAlarm();
    activeAlarm.value = null;
  }

  void snoozeAlarm({int? minutes, bool backgroundScheduled = false}) {
    final alarm = activeAlarm.value;
    if (alarm == null) return;
    audioBridge.stopAlarm();
    activeAlarm.value = null;
    playEffect('click');
    _snoozeTimer?.cancel();
    final delay = minutes ?? snoozeDurationMinutes;
    final duration = Duration(minutes: delay > 0 ? delay : 1);
    if (backgroundScheduled) return;
    final nextFire = DateTime.now().add(duration);
    _snoozeTimer = Timer(duration, () {
      triggerAlarm(
        eventId: alarm.eventId,
        title: alarm.title,
        location: alarm.location,
        time: nextFire,
        importance: alarm.importance,
      );
    });
  }
}

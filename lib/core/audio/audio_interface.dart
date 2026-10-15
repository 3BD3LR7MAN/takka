abstract class AudioPlatformBridge {
  void playEffect(String effect, String theme);
  void playRingtone(String ringtoneId, {String? customPath});
  void stopRingtone();
  void startAlarm(
    String ringtoneId, {
    String? customPath,
    required String eventId,
    required String title,
    String? location,
    required String importance,
    required int fireAtMillis,
  });
  void stopAlarm();
  Future<void> configureAlarm({
    required bool enabled,
    required String ringtoneId,
    String? customPath,
    required int snoozeMinutes,
  });
  Future<void> scheduleBackgroundAlarm({
    required int alarmId,
    required String eventId,
    required String title,
    String? location,
    required String importance,
    required int fireAtMillis,
  });
  Future<void> cancelBackgroundAlarm(int alarmId);
  Future<Map<String, String>?> pickAlarmSound();
  Future<void> clearCustomAlarmSound();
}

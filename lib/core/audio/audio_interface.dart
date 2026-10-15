abstract class AudioPlatformBridge {
  void playEffect(String effect, String theme);
  void playRingtone(String ringtoneId);
  void stopRingtone();
  void startAlarm(String ringtoneId);
  void stopAlarm();
}

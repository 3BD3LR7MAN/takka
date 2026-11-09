import 'package:flutter_test/flutter_test.dart';
import 'package:takka/core/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('SoundService initial state and presets', () {
    final sound = SoundService.instance;
    expect(sound.soundEffectsEnabled, isTrue);
    expect(SoundService.availableThemes.isNotEmpty, isTrue);
    expect(SoundService.availableRingtones.isNotEmpty, isTrue);

    // Verify presence of all expected sound themes
    final themeIds = SoundService.availableThemes.map((t) => t['id']).toSet();
    expect(themeIds.contains('chimes'), isTrue);
    expect(themeIds.contains('digital'), isTrue);
    expect(themeIds.contains('pops'), isTrue);
    expect(themeIds.contains('clicks'), isTrue);
    expect(themeIds.contains('muted'), isTrue);

    // Verify presence of all expected ringtones
    final ringtoneIds =
        SoundService.availableRingtones.map((r) => r['id']).toSet();
    expect(ringtoneIds.contains('gentle_chime'), isTrue);
    expect(ringtoneIds.contains('digital_pulse'), isTrue);
    expect(ringtoneIds.contains('zen_bell'), isTrue);
    expect(ringtoneIds.contains('radar'), isTrue);
    expect(ringtoneIds.contains('crystal_harp'), isTrue);
    expect(ringtoneIds.contains('classic_alarm'), isTrue);
  });

  test('SoundService alarm trigger, dismiss and snooze', () {
    final sound = SoundService.instance;
    expect(sound.activeAlarm.value, isNull);

    sound.triggerAlarm(
      eventId: 'evt-123',
      title: 'Doctor Appointment',
      location: 'Clinic',
      time: DateTime(2026, 10, 12, 10, 30),
      importance: 'critical',
    );

    expect(sound.activeAlarm.value, isNotNull);
    expect(sound.activeAlarm.value?.title, 'Doctor Appointment');
    expect(sound.activeAlarm.value?.importance, 'critical');

    sound.snoozeAlarm(minutes: 1);
    expect(sound.activeAlarm.value, isNull);
    sound
        .dismissAlarm(); // cancel the pending in-process snooze timer in this test

    sound.triggerAlarm(
      eventId: 'evt-456',
      title: 'Team Standup',
      time: DateTime(2026, 10, 12, 11, 0),
      importance: 'important',
    );
    expect(sound.activeAlarm.value, isNotNull);

    sound.dismissAlarm();
    expect(sound.activeAlarm.value, isNull);
  });
}

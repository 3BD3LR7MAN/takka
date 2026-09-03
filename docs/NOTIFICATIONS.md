# Notification Reliability

## Scheduling path

Saving an event creates a mandatory offset-0 reminder and any user-selected offsets. Critical events also receive 60- and 15-minute offsets. `NotificationService` schedules each future reminder through `zonedSchedule()` and records the Android notification ID in Drift.

The Android manifest includes `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` from `flutter_local_notifications`, in addition to the app boot receiver. These receivers are required for scheduled AlarmManager notifications and reboot/timezone restoration.

## Permissions

The app requests `POST_NOTIFICATIONS` after the first Flutter frame and checks exact-alarm capability. Users should enable notifications and, on Android 12+, enable **Alarms & reminders** when exact timing is required. Battery optimization and OEM autostart policies can still delay or suppress alarms.

## Recovery paths

| Situation | Recovery |
|---|---|
| App startup | Reschedule all upcoming events |
| First visible frame | Request notification permission and reschedule |
| App resume | Reschedule and check timezone changes |
| Event edit | Cancel stored IDs, save new reminders, reschedule |
| Event delete | Cancel stored IDs before deleting the event |
| Device/package/timezone change | Android boot receiver restores pending alarms |

## Diagnostics

Settings provides exact-alarm status, battery optimization status, an autostart opener, pending alarm count, a reschedule-all button, and a 15-second scheduled test. The scheduled test is different from the immediate test notification: it exercises the AlarmManager receiver path.

## Troubleshooting checklist

1. Allow Takka notifications.
2. Enable **Alarms & reminders** for Takka.
3. Disable battery optimization for Takka.
4. Enable OEM autostart where applicable.
5. Do not force-stop the app during testing.
6. Use the 15-second scheduled test before testing an event reminder.
7. If an old version was installed, uninstall it and install the current APK to clear stale permission and alarm state.

## References

[1]: https://developer.android.com/develop/ui/views/notifications "Android notification documentation"
[2]: https://pub.dev/packages/flutter_local_notifications "flutter_local_notifications package"

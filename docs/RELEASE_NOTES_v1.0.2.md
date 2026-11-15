# Takka v1.0.2 — Android test APK

- **GitHub release tag:** `v1.0.2`
- **Android app version:** `1.0.2` (`versionName` 1.0.2)
- **Android build code:** `17` (`versionCode`; Android requires this to be an integer)
- **APK:** `takka-v1.0.2-app-1.0.2-debug-signed.apk`
- **Checksum:** provided in the accompanying `.sha256` asset

## What’s new

- **Recurring events:** repeat events daily, weekly, every two weeks, monthly, on weekdays, or on weekends, with an optional end date.
- **Weekly calendar:** view and navigate the schedule by week, alongside the day and month views.
- **More alarm control:** choose whether each event uses an alarm, set the default for new events in Settings, and stop or snooze a ringing alarm. Snooze options are 5, 10, or 15 minutes.
- **Your own alarm sound:** choose an audio file on the device, or preview one of the included ringtone presets.
- **Background alarms:** scheduled alarms can start native Android alarm audio through a foreground service even when the app is not open. Alarm cancellation, snooze handling, and recovery after restart or time changes are also improved.
- **Release update checks:** check for stable GitHub releases automatically or from Settings. The interface remains available in English and Arabic, including right-to-left layouts.

The v1.0.1 sound-effect themes, ringtone presets, Alarm Mode, and live Next Up widget remain included.

## Please read before installing

This APK is **debug-signed for testing**. Android can install it over an existing Takka app only if its signing certificate matches the installed app. If Android requires you to uninstall the existing app, that may erase schedules and settings stored on the device. **If that data matters, do not uninstall the current app to try this APK.** A data-preserving update requires an APK signed with the same production key as the installed app.

The GitHub release tag and Android app version both use `1.0.2`. Android's separate integer build code is `17`, so it remains greater than the previous build code `16`.

## Alarm delivery

Allow Takka to send notifications. On Android 12 and later, exact timing may require the **Alarms & reminders** permission. Battery management and device-manufacturer background restrictions may delay or suppress delivery. Android does not deliver scheduled alarms after an explicit force-stop until Takka is opened again.

## Validation

GitHub Actions must pass dependency resolution, Drift code generation, static analysis, Flutter tests, and the Android release build for this version. Physical-device testing is still needed for alarm timing, reboot recovery, permission denial, manufacturer battery restrictions, local sound playback, and overlapping alarms.

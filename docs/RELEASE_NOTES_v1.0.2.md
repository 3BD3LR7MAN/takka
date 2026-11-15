# Takka v1.0.2 — new-install-only test APK

- **GitHub release tag:** `v1.0.2`
- **Android app version:** `1.0.15+16` (`versionName` 1.0.15, `versionCode` 16)
- **APK:** `takka-v1.0.2-app-1.0.15+16-debug-signed.apk`
- **SHA-256:** `085a2776f9aa69b07823a37166fb888e6718fb223ea40929a4d75a973e56a6b1`

## What’s new

- **Recurring events:** repeat events daily, weekly, every two weeks, monthly, on weekdays, or on weekends, with an optional end date.
- **Weekly calendar:** view and navigate the schedule by week, alongside the day and month views.
- **More alarm control:** choose whether each event uses an alarm, set the default for new events in Settings, and stop or snooze a ringing alarm. Snooze options are 5, 10, or 15 minutes.
- **Your own alarm sound:** choose an audio file on the device, or preview one of the included ringtone presets.
- **Background alarms:** scheduled alarms can start native Android alarm audio through a foreground service even when the app is not open. Alarm cancellation, snooze handling, and recovery after restart or time changes are also improved.
- **Release update checks:** check for stable GitHub releases automatically or from Settings. The interface remains available in English and Arabic, including right-to-left layouts.

The v1.0.1 sound-effect themes, ringtone presets, Alarm Mode, and live Next Up widget remain included.

## Please read before installing

This APK is **debug-signed for testing**. Its signing certificate is different from the certificate on the public v1.0.1 APK, so Android cannot install it as an update over that app. Trying this build requires uninstalling the existing Takka app first. Uninstalling can erase schedules and settings stored on the device. **If that data matters, do not uninstall the current app to try this APK.** An in-place update requires an APK signed with the same production key as the installed app.

The GitHub tag is `v1.0.2`, but the Android app reports version `1.0.15+16`. Takka’s in-app updater compares these versions, so it may not offer this release to an installation that already reports `1.0.15`. Debug-signed and unsigned APKs are not offered as production updates; the updater directs users to the release page instead.

## Alarm delivery

Allow Takka to send notifications. On Android 12 and later, exact timing may require the **Alarms & reminders** permission. Battery management and device-manufacturer background restrictions may delay or suppress delivery. Android does not deliver scheduled alarms after an explicit force-stop until Takka is opened again.

## Validation

GitHub Actions passed dependency resolution, Drift code generation, static analysis, Flutter tests, and the Android release build for the source used in this release: [build run](https://github.com/3BD3LR7MAN/takka/actions/runs/43743899556). Physical-device testing is still needed for alarm timing, reboot recovery, permission denial, manufacturer battery restrictions, local sound playback, and overlapping alarms.

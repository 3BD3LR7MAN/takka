# Takka v1.0.2 — new-install-only test APK

- **GitHub release tag:** `v1.0.2`
- **Android app version:** `1.0.2` (`versionName` 1.0.2)
- **Android build code:** `17` (`versionCode`; Android requires an integer)
- **APK:** `takka-v1.0.2-app-1.0.2-debug-signed.apk`
- **APK SHA-256:** `ec6070cb92f40a6709fc610f1de92a98df7935a310a4f1f84eaeae194bac4f08` (also supplied as a `.sha256` asset)
- **Signing certificate SHA-256:** `6921408668C5303257C6DA672DB2F87B832B7932FB692028DBAD0B2B621AC004`

## What’s new

- **Recurring events:** repeat events daily, weekly, every two weeks, monthly, on weekdays, or on weekends, with an optional end date.
- **Weekly calendar:** view and navigate the schedule by week, alongside the day and month views.
- **More alarm control:** choose whether each event uses an alarm, set the default for new events in Settings, and stop or snooze a ringing alarm. Snooze options are 5, 10, or 15 minutes.
- **Your own alarm sound:** choose an audio file on the device, or preview one of the included ringtone presets.
- **Background alarms:** scheduled alarms can start native Android alarm audio through a foreground service even when the app is not open. Alarm cancellation, snooze handling, and recovery after restart or time changes are also improved.
- **Release update checks:** check for stable GitHub releases automatically or from Settings. The interface remains available in English and Arabic, including right-to-left layouts.

The v1.0.1 sound-effect themes, ringtone presets, Alarm Mode, and live Next Up widget remain included.

## Please read before installing

This APK is **debug-signed for testing**. Its signing certificate differs from the public v1.0.1 APK (`4F3F96536D722495EADB534121A0C982F605859289648940C0963044C8C818A0`) and the earlier 1.0.15+16 APK (`510226E106E613EAF6C27B87B73E10007ABE39F3AA0D0AD8B07736E9FBE54C3A`). Android cannot install it over either build; this is a **new-install-only** APK for those installations. Trying it requires uninstalling the existing app, which may erase schedules and settings stored on the device. **If that data matters, do not uninstall to try this APK.** A data-preserving update requires an APK signed with the same production key as the installed app.

The GitHub release tag and Android app version both use `1.0.2`. Android's separate integer build code is `17`, kept higher than the prior build code `16`. Takka's in-app updater compares app versions: it will not offer `1.0.2` as an update to an installation reporting `1.0.15`, because that would be a downgrade.

## Alarm delivery

Allow Takka to send notifications. On Android 12 and later, exact timing may require the **Alarms & reminders** permission. Battery management and device-manufacturer background restrictions may delay or suppress delivery. Android does not deliver scheduled alarms after an explicit force-stop until Takka is opened again.

## Validation

GitHub Actions [run 43747596903](https://github.com/3BD3LR7MAN/takka/actions/runs/43747596903) passed dependency resolution, Drift code generation, static analysis, Flutter tests, and the Android release build. The built APK manifest was verified as `com.example.takka`, `versionName` `1.0.2`, and `versionCode` `17`; its APK v2 signature was cryptographically verified. Physical-device testing is still needed for alarm timing, reboot recovery, permission denial, manufacturer battery restrictions, local sound playback, and overlapping alarms.

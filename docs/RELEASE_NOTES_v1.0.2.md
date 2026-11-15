# Takka v1.0.2 — new-install-only build

**GitHub release tag:** `v1.0.2`

**Android package version in the APK:** `1.0.15+16` (`versionName` 1.0.15, `versionCode` 16)

**APK asset:** `takka-v1.0.2-app-1.0.15+16-debug-signed.apk`

**SHA-256:** `085a2776f9aa69b07823a37166fb888e6718fb223ea40929a4d75a973e56a6b1`

This release packages the audited Takka app build with reliable native Android alarms, Stop/Snooze controls, local alarm sounds, per-event alarm settings, recurring events, week view, Arabic/English UI, and GitHub update checks.

## Important installation notice

The attached APK is **debug-signed for development/testing**. Its signing certificate does not match the APK attached to the previous public v1.0.1 release. Android will therefore reject it as an in-place update over an existing v1.0.1 installation. It is offered as a **new-install-only** build; installing it over the older app requires uninstalling the existing app first. Uninstalling may delete Takka's locally stored schedules, settings, and other app data, so users should save anything important before proceeding.

The in-app updater filters out APK assets explicitly marked `debug-signed` or `unsigned`, and will open this GitHub release page rather than treating the attached file as a normal production update. Also note that the GitHub tag `v1.0.2` is intentionally different from the APK's internal package version `1.0.15+16`; this build will not offer `v1.0.2` as a newer version when checking from an installation whose package version is already `1.0.15`.

## Alarm and reliability changes

- Scheduled event notifications use a silent channel while continuous native alarm audio is active, avoiding a second notification sound.
- Changing the global alarm setting refreshes existing schedules.
- Snooze avoids duplicate local/background playback; event deletion/editing cancels event-linked native and notification schedules.
- Native alarm state is synchronized with the app when it opens or resumes.
- Boot recovery delegates plugin notifications to the plugin's receiver and restores native AlarmManager alarms without starting an extra headless Flutter engine.

## Validation

The source was validated with `flutter analyze`, all 22 Flutter tests passed, and Flutter Web and Android release builds completed successfully. Testing on a physical Android device or emulator is still needed for real alarm delivery, reboot recovery, permission-denial behavior, OEM battery restrictions, local audio playback, and overlapping alarms. Android also prevents scheduled delivery after an explicit force-stop until the user opens the app again.

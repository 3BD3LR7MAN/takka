# Takka Release Guide

## Release flow

1. Update `version:` in `pubspec.yaml` and keep it aligned with the app version stated in the GitHub release notes. Git tags and Android package versions must normally follow the same SemVer sequence so the in-app updater behaves predictably.
2. Run `flutter pub get` and `dart run build_runner build --delete-conflicting-outputs` if dependencies or generated Drift code changed.
3. Run `flutter analyze`, `flutter test`, and `flutter build apk --release`.
4. Verify the APK version, archive integrity, and signing certificate. A debug-signed APK is for development or explicitly labeled new-install-only distribution, not a routine update.
5. Create a semantic-version tag, publish matching release notes, and attach the intended APK and its SHA-256 file.
6. Test update installation on a physical device with the same signing certificate as the prior release; test alarms, notifications, reboot recovery, Arabic RTL, and local sound playback.

## Current release: GitHub v1.0.2

The `v1.0.2` GitHub release tag matches the Android app `versionName` `1.0.2`. Android's integer `versionCode` is `17`, kept higher than the previous build code `16`; future releases should continue increasing the code while keeping the tag and visible app version aligned.

The attached APK is debug-signed with certificate SHA-256 `6921408668C5303257C6DA672DB2F87B832B7932FB692028DBAD0B2B621AC004`. It differs from the public v1.0.1 APK (`4F3F96536D722495EADB534121A0C982F605859289648940C0963044C8C818A0`) and the earlier 1.0.15+16 APK (`510226E106E613EAF6C27B87B73E10007ABE39F3AA0D0AD8B07736E9FBE54C3A`), so it cannot update either installation in place. It is new-install-only for those builds. Uninstalling may remove app-local data; users who need their data should not uninstall to try it and should wait for an APK signed with the installed production key.

The previous GitHub production-signing workflow failed because the repository lacked `KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_PASSWORD`, and `KEY_ALIAS`. The workflow remains available for manual use after the owner configures protected Actions secrets. Never commit a keystore, `key.properties`, passwords, or a Base64 export.

## CI configuration

The repository's GitHub Actions workflows use Flutter `3.47.7`, the version used to validate the current source. The general build workflow runs analyzer/tests and builds an APK. The production-signed workflow is manually dispatched, because the signing secrets are not configured in the repository.

## Project identity

The Dart package name is `takka`, the user-facing application name is **Takka**, and the Android application ID is `com.example.takka`.

## References

[1]: https://docs.github.com/en/actions "GitHub Actions documentation"
[2]: https://developer.android.com/studio/command-line/apksigner "Android apksigner documentation"
[3]: https://docs.flutter.dev/deployment/android "Flutter Android deployment"

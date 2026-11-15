# Takka Release Guide

## Release flow

1. Update `version:` in `pubspec.yaml` and keep it aligned with the app version stated in the GitHub release notes. Git tags and Android package versions must normally follow the same SemVer sequence so the in-app updater behaves predictably.
2. Run `flutter pub get` and `dart run build_runner build --delete-conflicting-outputs` if dependencies or generated Drift code changed.
3. Run `flutter analyze`, `flutter test`, and `flutter build apk --release`.
4. Verify the APK version, archive integrity, and signing certificate. A debug-signed APK is for development or explicitly labeled new-install-only distribution, not a routine update.
5. Create a semantic-version tag, publish matching release notes, and attach the intended APK and its SHA-256 file.
6. Test update installation on a physical device with the same signing certificate as the prior release; test alarms, notifications, reboot recovery, Arabic RTL, and local sound playback.

## Current release: GitHub v1.0.2

The `v1.0.2` GitHub release tag intentionally packages Android app build `1.0.15+16`. This tag/package mismatch is documented in the release notes; future releases should restore aligned versioning to keep Android's visible version and Takka's in-app update checks consistent.

The attached APK is debug-signed and its certificate differs from the previously published v1.0.1 APK. It is therefore **new-install-only**, not an in-place update. Installing over an existing Takka build requires uninstalling first; app-local data may be removed. The release notes should carry this notice wherever the APK is distributed.

The previous GitHub production-signing workflow failed because the repository lacked `KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_PASSWORD`, and `KEY_ALIAS`. The workflow remains available for manual use after the owner configures protected Actions secrets. Never commit a keystore, `key.properties`, passwords, or a Base64 export.

## CI configuration

The repository's GitHub Actions workflows use Flutter `3.47.7`, the version used to validate the current source. The general build workflow runs analyzer/tests and builds an APK. The production-signed workflow is manually dispatched, because the signing secrets are not configured in the repository.

## Project identity

The Dart package name is `takka`, the user-facing application name is **Takka**, and the Android application ID is `com.example.takka`.

## References

[1]: https://docs.github.com/en/actions "GitHub Actions documentation"
[2]: https://developer.android.com/studio/command-line/apksigner "Android apksigner documentation"
[3]: https://docs.flutter.dev/deployment/android "Flutter Android deployment"

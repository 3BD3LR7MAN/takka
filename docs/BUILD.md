# Build Guide

## Required tools

| Tool | Project expectation |
|---|---|
| Flutter | Stable channel compatible with Dart SDK `>=3.4.0` |
| Java | JDK 17 for Android Gradle |
| Android SDK | API 36 compile SDK; minimum API 23 |

## Local commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --release
```

The local release build uses the debug signing fallback when `android/key.properties` is absent. This is suitable for development validation, not store distribution.

## Generated files

Drift code is generated in `lib/data/db.g.dart`. Do not hand-edit it. Run build_runner after changing Drift table definitions.

## Verification expectations

A clean validation run must have no analyzer errors, all tests passing, and a successful Gradle APK task. Lint/info messages should be reviewed but do not block the build unless promoted to errors.

## Project identity

The Dart package name is `takka`, the user-facing Android and Flutter application name is `Takka`, and the Android application ID is `com.example.takka`.

## References

[1]: https://docs.flutter.dev/deployment/android "Flutter Android deployment"
[2]: https://docs.gradle.org/ "Gradle documentation"

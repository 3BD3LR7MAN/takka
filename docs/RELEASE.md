# Takka Release Guide

## Release flow

1. Run `flutter pub get` and `dart run build_runner build --delete-conflicting-outputs`.
2. Run `flutter analyze`, `flutter test`, and `flutter build apk --release`.
3. Confirm that the APK is signed with the intended production certificate.
4. Update `version:` in `pubspec.yaml` and keep the release notes aligned with it.
5. Create a version tag such as `v1.0.0` and publish the GitHub Release.
6. Verify the release asset checksum and install the APK on a physical Android device.

## Current release status

The first Takka release is version `1.0.0+1`. Dependency resolution, Drift code generation, and the automated test suite pass. A local release APK also builds successfully, but it uses the Android debug-signing fallback because no production keystore is present in the workspace. It is suitable for development validation only and must not be distributed as a production artifact.

The production-signed build is handled by `.github/workflows/android-release.yml`. It runs manually or when a `v*` tag is pushed and requires the four repository Actions secrets below. The workflow restores the keystore only on the ephemeral runner, builds the signed APK, uploads it as an artifact, and removes the temporary signing files during cleanup.

| Secret | Required value |
|---|---|
| `KEYSTORE_BASE64` | Base64 contents of the private `.jks` file |
| `STORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Signing key alias |

Never commit a keystore, `key.properties`, password, or Base64 export. See [GITHUB_SIGNING.md](GITHUB_SIGNING.md) for the secure setup procedure.

## Post-build checks

Verify the artifact exists, inspect its certificate with `apksigner verify --print-certs`, record the SHA-256 checksum, and test installation on a physical Android device. Exercise immediate and scheduled notifications, reboot recovery, Arabic RTL layout, AI proposal confirmation, the home-screen widget, and light/dark themes.

## Project identity

The Dart package name is `takka`, the user-facing application name is **Takka**, and the Android application ID is `com.example.takka`.

## References

[1]: https://docs.github.com/en/actions "GitHub Actions documentation"
[2]: https://developer.android.com/studio/command-line/apksigner "Android apksigner documentation"
[3]: https://docs.flutter.dev/deployment/android "Flutter Android deployment"

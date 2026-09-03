# Release Guide

## Release flow

1. Review source changes and update documentation.
2. Run `flutter analyze`, `flutter test`, and `flutter build apk --release`.
3. Confirm the APK is signed with the intended production certificate.
4. Create a version tag such as `v1.0.1`.
5. Push the tag to GitHub.
6. Download and verify the `takka-release-apk` artifact from the Android release workflow.

## GitHub workflows

`android-release.yml` is the production workflow. It requires `KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_PASSWORD`, and `KEY_ALIAS` repository Secrets. It runs manually or on `v*` tags.

`build-apk.yml` is a general CI workflow that builds and uploads an APK using the local fallback when no signing file exists. Do not treat its artifact as a production-signed release.

## Versioning

Update `version:` in `pubspec.yaml` using Flutter's `major.minor.patch+build` format. Keep the version in the Settings About row and release notes aligned with the package version.

## Post-build checks

Verify the artifact exists, inspect its certificate with `apksigner verify --print-certs`, record the SHA-256, and test notifications on a physical Android device. Test both immediate and scheduled notification paths.

## References

[1]: https://docs.github.com/en/actions "GitHub Actions documentation"
[2]: https://developer.android.com/studio/command-line/apksigner "Android apksigner documentation"

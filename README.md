# Takka

Takka is an Android-first Flutter application for managing a daily schedule through a local-first timeline, tasks, reliable reminders, and optional AI-assisted extraction from text or voice.

> **The AI proposes. Validation decides. The human approves. One repository save path persists data.**

## Features

- Manual event creation and editing with conflict detection.
- Daily timeline, calendar month view, and task checklist.
- AI extraction into editable event and task proposals.
- Seven OpenAI-compatible provider presets plus a custom endpoint.
- Arabic and English localization with RTL support.
- Scheduled Android reminders with exact-alarm fallback, reboot recovery, and diagnostics.
- Next Up home-screen widget.
- Takka vector mascot with state-specific moods.
- Light, dark, and system themes.

## Quick start

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --release
```

The local release build uses the debug signing configuration when no private keystore is configured. Use the GitHub Actions workflow for a production-signed artifact. Read [docs/BUILD.md](docs/BUILD.md), [docs/RELEASE.md](docs/RELEASE.md), and [docs/GITHUB_SIGNING.md](docs/GITHUB_SIGNING.md) before distributing an APK.

## Documentation

Read the complete engineering documentation in [docs/README.md](docs/README.md). The most useful starting points are:

- [File map](docs/FILE_MAP.md)
- [Architecture](docs/ARCHITECTURE.md)
- [AI layer](docs/AI.md)
- [Notifications](docs/NOTIFICATIONS.md)
- [Security](docs/SECURITY.md)

## Security

Never commit API keys, signing passwords, `key.properties`, `.jks` files, `.keystore` files, or Base64 keystore exports. The repository includes an ignore policy and a secret-backed GitHub Actions workflow. See [docs/SECURITY.md](docs/SECURITY.md).

## Project identity

The Dart package name is `takka`, the user-facing application name is **Takka**, and the Android application ID is `com.example.takka`.

## License

MIT.

## References

[1]: https://docs.flutter.dev/ "Flutter documentation"
[2]: https://docs.github.com/en/actions "GitHub Actions documentation"

# Takka

[![Build APK](https://github.com/3BD3LR7MAN/takka/actions/workflows/build-apk.yml/badge.svg)](https://github.com/3BD3LR7MAN/takka/actions/workflows/build-apk.yml)
[![Latest Release](https://img.shields.io/github/v/release/3BD3LR7MAN/takka?display_name=tag)](https://github.com/3BD3LR7MAN/takka/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Takka** is an Android-first Flutter application for managing a daily schedule through a local-first timeline, tasks, reliable reminders, and optional AI-assisted extraction from text or voice.

> **The AI proposes. Validation decides. The human approves. One repository save path persists data.**

## Latest release

[Takka v1.0.14](https://github.com/3BD3LR7MAN/takka/releases/tag/v1.0.14) — build `1.0.14+15`

This release adds GitHub Releases update checks, a weekly calendar view, and the native Android alarm reliability work introduced in the v1.0.13 line. Takka can now check for stable updates automatically at startup, no more than once every 24 hours, or on demand from Settings.

The update dialog shows release notes and opens an attached APK directly when one is available; otherwise it opens the GitHub release page.

> **Repository requirement:** update checks use the unauthenticated public GitHub Releases API for `3BD3LR7MAN/takka`. The repository must remain publicly accessible for end-user update checks to work. Never embed a GitHub personal access token in the Android application.

## Features

### Planning and organization

- Manual event creation and editing with conflict detection
- Daily timeline, weekly calendar, and monthly calendar views
- Task checklist management
- Local-first storage for events, reminders, tasks, and notification records
- Light, dark, and system themes
- Takka mascot with state-specific moods

### Reminders and alarms

- Scheduled Android reminders with exact-alarm support and fallback behavior
- Native Android alarm scheduler and foreground audio service with Stop/Snooze controls
- Custom reminder ringtones with live preview
- Persistent Alarm Mode for critical events
- Configurable 5-, 10-, and 15-minute snooze durations
- Reboot and timezone recovery for scheduled notifications
- Notification, battery optimization, autostart, and pending-alarm diagnostics
- Scheduled test notifications for verifying the Android AlarmManager path

### Home-screen widget

The live **Next Up** widget shows the event happening now or the next upcoming event. It refreshes when schedules change and can schedule Android wake-up alarms at event boundaries without requiring the app to remain open.

### AI-assisted scheduling

Takka can optionally extract event and task proposals from text or voice input through OpenAI-compatible providers. Proposals remain editable and require user approval before they are saved.

The validation layer:

- Resolves relative dates using the supplied date and timezone
- Separates timed events from untimed tasks
- Rejects invalid or untitled events
- Handles missing times and invalid JSON safely
- Normalizes importance and reminder values
- Repairs an end time that precedes a start time

Takka includes seven provider presets and supports a custom OpenAI-compatible endpoint. Provider credentials are stored using secure storage.

### Localization and accessibility

- English and Arabic localization
- Right-to-left Arabic layout support
- Correct RTL timeline and event-card navigation
- Semantic category icons for Study, Work, Exercise, Meetings, University, Important, and Personal

## Architecture

Takka uses a local-first Flutter architecture:

```text
Flutter UI
   ↓
Riverpod providers
   ↓
EventRepository
   ├── Drift SQLite database
   ├── NotificationService
   └── WidgetUpdater

AI input → provider client → JSON validation → confirmation UI → repository save
```

The repository is the single persistence path for both manually created events and approved AI proposals. Event timestamps are stored as UTC epoch milliseconds and converted to the user’s local timezone for display and scheduling.

## Getting started

### Requirements

- Flutter stable compatible with Dart SDK `>=3.4.0 <4.0.0`
- JDK 17
- Android SDK with API 36 compile support
- Android minimum API level 23

### Install dependencies and run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Run validation

```bash
flutter analyze
flutter test
flutter build apk --release
```

The local release build uses the debug-signing fallback when `android/key.properties` is absent. Do not distribute that build as a production APK.

## Reminder setup on Android

For the most reliable reminder delivery:

1. Allow Takka to send notifications.
2. On Android 12 and later, enable **Alarms & reminders** when exact timing is required.
3. Exclude Takka from battery optimization where appropriate.
4. Enable OEM autostart if your device provides that setting.
5. Use the scheduled test notification before relying on an important reminder.

Android manufacturer policies may still delay or suppress alarms when background activity is restricted.

## Documentation

- [Documentation index](docs/README.md)
- [Architecture](docs/ARCHITECTURE.md)
- [File map](docs/FILE_MAP.md)
- [AI layer and provider contract](docs/AI.md)
- [Provider configuration](docs/PROVIDERS.md)
- [Notification reliability](docs/NOTIFICATIONS.md)
- [Security guidance](docs/SECURITY.md)
- [Build guide](docs/BUILD.md)
- [Release guide](docs/RELEASE.md)
- [v1.0.14 release notes](docs/RELEASE_NOTES_v1.0.14.md)
- [v1.0.1 release notes](docs/RELEASE_NOTES_v1.0.1.md)

## Privacy and security

Schedule data is stored in the app’s private local SQLite database. When AI features are used, only the input and date/time context required for processing are sent to the selected endpoint. Review the provider’s privacy policy before entering sensitive information.

The current architecture connects to AI endpoints directly from the device and does not provide a backend proxy. Production deployments should use server-side key protection, rate limiting, and key rotation where appropriate.

Never commit API keys, signing passwords, `key.properties`, `.jks` files, `.keystore` files, or Base64 keystore exports. See [SECURITY.md](docs/SECURITY.md) and [GITHUB_SIGNING.md](docs/GITHUB_SIGNING.md).

## Current limitations

The current release does not include:

- Recurring events
- Cloud synchronization
- Backend-based API key protection
- Conversational tool calling
- Guaranteed alarm delivery when Android or an OEM restricts background activity

## Project identity

| Property | Value |
|---|---|
| Application | Takka |
| Dart package | `takka` |
| Android application ID | `com.example.takka` |
| Current version | `1.0.14+15` |
| Minimum Android API | 23 |
| Compile SDK | API 36 |
| License | MIT |

## Contributing

Before submitting a change, run dependency resolution, code generation, static analysis, tests, and an Android release build. Keep generated Drift files synchronized with schema changes and do not commit credentials or signing material.

## License

Takka is released under the [MIT License](LICENSE).

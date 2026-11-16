# Takka

[![Build APK](https://github.com/3BD3LR7MAN/takka/actions/workflows/build-apk.yml/badge.svg)](https://github.com/3BD3LR7MAN/takka/actions/workflows/build-apk.yml)
[![Latest Release](https://img.shields.io/github/v/release/3BD3LR7MAN/takka?display_name=tag)](https://github.com/3BD3LR7MAN/takka/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Takka** is an Android-first Flutter app for planning events and tasks with a daily timeline, recurring schedules, calendar views, scheduled reminders, and optional AI-assisted event proposals from text or voice.

> **The AI proposes. Validation decides. The human approves. One repository save path persists data.**

## Latest release

[Takka v1.0.2](https://github.com/3BD3LR7MAN/takka/releases/tag/v1.0.2) — Android app version `1.0.2` (build code `17`)

This build adds recurring events, a weekly calendar, per-event alarm choices, local alarm sounds, expanded background alarm support, and GitHub release update checks.

> **Before installing:** this exact APK is debug-signed with a different certificate from both the public v1.0.1 APK and the earlier 1.0.15+16 build. Android cannot install it over either; trying it requires uninstalling the current app, which may erase schedules and settings stored on the device. If that data matters, do not uninstall; a data-preserving update requires an APK signed with the same key as the installed app.

> **Version labels:** the GitHub release tag `v1.0.2` matches the APK's app version `1.0.2`. Android uses a separate integer build code, set to `17` to continue increasing from the prior code `16`. The in-app updater compares app versions, so it will not offer `1.0.2` as an update to an installation reporting `1.0.15` because that would be a downgrade.

The update dialog shows release notes and opens an attached production APK directly when one is available; otherwise it opens the GitHub release page.

> **Repository requirement:** update checks use the unauthenticated public GitHub Releases API for `3BD3LR7MAN/takka`. The repository must remain publicly accessible for end-user update checks to work. Never embed a GitHub personal access token in the Android application.

## Features

### Planning and organization

- Manual event creation and editing with conflict detection
- Daily timeline, weekly calendar, and monthly calendar views
- Recurring events: daily, weekly, every two weeks, monthly, weekdays, or weekends, with an optional end date
- Task checklist management
- Local-first storage for events, reminders, tasks, and notification records
- Light, dark, and system themes
- Takka mascot with state-specific moods

### Reminders and alarms

- Scheduled Android reminders with exact-alarm support and fallback behavior
- Background alarm audio with Stop and Snooze controls, subject to Android permission and battery limits
- Custom reminder ringtones with live preview
- Choose an alarm sound file from the device, set a default in Settings, and override it per event
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

Android or manufacturer background restrictions may delay or suppress alarms. Exact timing may require the **Alarms & reminders** permission. Alarms are not delivered after an explicit force-stop until Takka is opened again.

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
- [v1.0.2 release notes](docs/RELEASE_NOTES_v1.0.2.md)
- [v1.0.14 release notes](docs/RELEASE_NOTES_v1.0.14.md)
- [v1.0.1 release notes](docs/RELEASE_NOTES_v1.0.1.md)
- [v1.0.0 release notes](docs/RELEASE_NOTES_v1.0.0.md)

## Privacy and security

Schedule data is stored in the app’s private local SQLite database. When AI features are used, only the input and date/time context required for processing are sent to the selected endpoint. Review the provider’s privacy policy before entering sensitive information.

The current architecture connects to AI endpoints directly from the device and does not provide a backend proxy. Production deployments should use server-side key protection, rate limiting, and key rotation where appropriate.

Never commit API keys, signing passwords, `key.properties`, `.jks` files, `.keystore` files, or Base64 keystore exports. See [SECURITY.md](docs/SECURITY.md) and [GITHUB_SIGNING.md](docs/GITHUB_SIGNING.md).

## Current limitations

The current release does not include:

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
| Current app version | `1.0.2` |
| Android build code | `17` |
| Minimum Android API | 23 |
| Compile SDK | API 36 |
| License | MIT |

## Contributing

Before submitting a change, run dependency resolution, code generation, static analysis, tests, and an Android release build. Keep generated Drift files synchronized with schema changes and do not commit credentials or signing material.

## License

Takka is released under the [MIT License](LICENSE).

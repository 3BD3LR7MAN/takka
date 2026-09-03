# File Map

This map describes the responsibility of each maintained project area. Generated, machine-local, and build-output files are intentionally excluded.

| Path | Responsibility |
|---|---|
| `lib/main.dart` | Flutter bootstrap, database/repository creation, notification initialization, lifecycle repair, and app shell |
| `lib/core/router.dart` | GoRouter route definitions |
| `lib/core/navigator.dart` | Global navigator key used by notification navigation |
| `lib/core/l10n.dart` | English/Arabic application strings and locale helpers |
| `lib/core/theme.dart` | Light and dark Material themes |
| `lib/core/time_utils.dart` | Date and time formatting helpers |
| `lib/core/links.dart` | Developer profile URLs and display handles |
| `lib/core/mascot/takka_mascot.dart` | Takka vector mascot and moods |
| `lib/data/db.dart` | Drift tables, queries, migrations, and generated database access |
| `lib/data/db.g.dart` | Drift-generated database code; regenerate with build_runner |
| `lib/data/repositories.dart` | Event/task repository and the single event save path |
| `lib/data/notification_service.dart` | Notification channels, scheduling, cancellation, diagnostics, and rescheduling |
| `lib/data/system_service.dart` | Android settings bridges for exact alarms, battery optimization, and autostart |
| `lib/data/widget_updater.dart` | Next Up home-widget data synchronization |
| `lib/domain/event_engine.dart` | Conflict and timeline domain calculations |
| `lib/features/today/` | Daily timeline and task checklist |
| `lib/features/events/` | Event creation, editing, details, and event cards |
| `lib/features/calendar/` | Calendar month view and day selection |
| `lib/features/ai/ai_service.dart` | AI request contract, prompt, JSON schema, and deterministic validation |
| `lib/features/ai/ai_models.dart` | Proposed event/task models |
| `lib/features/ai/ai_providers.dart` | Provider presets, secure configuration, and OpenAI-compatible HTTP client |
| `lib/features/ai/providers.dart` | Riverpod configuration/service state |
| `lib/features/settings/` | Settings, AI configuration, notification diagnostics, and developer links |
| `android/app/src/main/AndroidManifest.xml` | Android permissions, activities, receivers, and widget declarations |
| `android/app/build.gradle` | Android SDK settings and optional private release signing |
| `android/app/src/main/kotlin/` | Android activity, boot receiver, and widget provider implementations |
| `android/key.properties.example` | Non-secret signing configuration template |
| `.github/workflows/android-release.yml` | Secret-backed signed release workflow |
| `.github/workflows/build-apk.yml` | Unsigned/debug-fallback CI artifact workflow |
| `test/` | Flutter unit/widget tests |

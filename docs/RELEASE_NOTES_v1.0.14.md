# Takka v1.0.14+15

## GitHub release update checks

- Added an automatic GitHub Releases check at app startup, throttled to at most once every 24 hours.
- Added a manual **Check for updates** action in Settings.
- Compares the installed application version with the latest stable GitHub release using semantic-version rules.
- Displays the release notes and opens the APK asset directly when one is attached; otherwise opens the GitHub release page.
- Added English and Arabic UI strings and non-blocking error handling.

## Important repository requirement

The checker uses the unauthenticated GitHub REST API for `3BD3LR7MAN/takka`. GitHub's public Releases endpoint cannot retrieve releases from a private repository. To use automatic checks on end-user devices, publish releases in a publicly accessible repository. Do not embed a GitHub personal access token in the Android application; for private releases, use a trusted backend or an authenticated distribution channel.

## Included alarm reliability work

This build also includes the native Android alarm scheduler and foreground audio service introduced in v1.0.13, with ongoing Stop/Snooze controls. Android does not run scheduled alarms after the user explicitly force-stops the app.

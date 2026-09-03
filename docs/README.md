# Takka Documentation

Takka is a local-first Flutter scheduling application with an optional AI extraction layer. Users can create events and tasks manually or submit editable text and voice input to an OpenAI-compatible endpoint. AI output is treated as an untrusted proposal: validation runs before the confirmation screen, and only the repository save path writes to Drift.

## Documentation index

| Document | Scope |
|---|---|
| [FILE_MAP.md](FILE_MAP.md) | Source tree and ownership map |
| [PRODUCT.md](PRODUCT.md) | Product behavior and UX rules |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Runtime architecture and data flow |
| [AI.md](AI.md) | Providers, prompt, schema, validation, and privacy |
| [PROVIDERS.md](PROVIDERS.md) | Presets and custom endpoint configuration |
| [NOTIFICATIONS.md](NOTIFICATIONS.md) | Alarm scheduling, receivers, permissions, and troubleshooting |
| [SECURITY.md](SECURITY.md) | Secrets, API keys, signing, and threat model |
| [BUILD.md](BUILD.md) | Local development and verification |
| [RELEASE.md](RELEASE.md) | Release and GitHub Actions procedure |
| [EVALS.md](EVALS.md) | Current tests and future AI evaluation protocol |
| [GITHUB_SIGNING.md](GITHUB_SIGNING.md) | Keystore-safe GitHub setup |

## Core invariant

> **The AI proposes. Validation decides. The human approves. One repository save path persists data.**

## Current status

The project is an Android Flutter application. The release APK builds successfully with the local debug fallback when no private keystore is present. A production-signed build requires the private signing inputs described in [GITHUB_SIGNING.md](GITHUB_SIGNING.md). The automated test suite currently contains seven passing tests; the analyzer reports non-blocking lint/info messages only.

## Quick links

- [Root README](../README.md)
- [GitHub signing guide](GITHUB_SIGNING.md)
- [Flutter documentation](https://docs.flutter.dev/)

## References

[1]: https://docs.flutter.dev/ "Flutter documentation"
[2]: https://developer.android.com/develop/ui/views/notifications "Android notifications documentation"

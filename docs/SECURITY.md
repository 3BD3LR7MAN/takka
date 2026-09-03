# Security

## Secrets that must never be committed

The repository ignores `.jks`, `.keystore`, `key.properties`, `local.properties`, Base64 keystore exports, build output, and local Flutter state. Do not place API keys, signing passwords, or keystores in source files, issues, screenshots, or logs.

## Android signing

`android/app/build.gradle` loads `android/key.properties` only when it exists. Local development without a private keystore uses the debug signing configuration. GitHub Actions reconstructs the keystore temporarily from repository Secrets and deletes it in cleanup. See [GITHUB_SIGNING.md](GITHUB_SIGNING.md).

## AI keys

AI configuration is stored through `flutter_secure_storage`, backed by Android Keystore on supported Android devices. This protects casual filesystem access but does not make a key safe from extraction out of a distributed APK. For production, move provider credentials to a backend proxy.

## Incident response

If a signing key or API key is exposed, revoke or rotate it immediately. A deleted secret remains in Git history. Keystore compromise may require a new application identity and a migration plan; do not assume deleting the file repairs the exposure.

## Review checklist

Before pushing, inspect `git status --ignored`, search for credential-shaped strings, confirm no private files are tracked, and review the GitHub Actions workflow for secret logging. Use least-privilege repository permissions.

## References

[1]: https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions "GitHub Actions security hardening"
[2]: https://developer.android.com/privacy-and-security/keystore "Android Keystore"

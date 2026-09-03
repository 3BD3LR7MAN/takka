# Secure GitHub release setup

This repository is prepared so signing credentials remain outside Git. **Never commit a `.jks`, `.keystore`, `key.properties`, or password to GitHub**, including a private repository.

## Local signed builds

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Put the keystore at the path specified by `storeFile`.
3. Replace the placeholder values with the real alias and passwords.
4. Run `flutter build apk --release`.

The Gradle script reads `android/key.properties` only when it exists. Without it, local release builds use the debug signing configuration so development remains possible. The real properties file and keystore are ignored by Git.

## GitHub Actions signed builds

The workflow at `.github/workflows/android-release.yml` runs manually or when a `v*` tag is pushed. Add these four **Actions repository secrets** under **Settings → Secrets and variables → Actions**:

| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | Base64 contents of the `.jks` file |
| `STORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Key alias |

Create the Base64 value locally without committing the file:

```bash
base64 -w 0 takka-release.jks > keystore.base64
```

Paste the contents of `keystore.base64` into `KEYSTORE_BASE64`, then delete the temporary text file. The workflow restores the keystore only inside the ephemeral runner, signs the APK, uploads the APK as a workflow artifact, and removes the private files in an `always()` cleanup step.

## First GitHub push checklist

Before pushing, run `git status --ignored` and verify that the keystore, `android/key.properties`, `android/local.properties`, build output, and temporary Base64 files are ignored. If any secret was ever committed, rotate the keystore credentials and remove it from Git history; deleting the file in a later commit is not sufficient.

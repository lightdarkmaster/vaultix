# Vaultix

**Your Digital Life. One Secure Vault.**

A local-first Android password manager built with Flutter. No accounts, no
servers, no analytics, no network access.

## Setup

```bash
flutter create --org com.vaultix --project-name vaultix --platforms android .
# unzip the Vaultix project over it so lib/, test/, assets/ and pubspec.yaml replace the generated ones
flutter pub get
dart run flutter_launcher_icons      # generates the launcher icon
flutter analyze
flutter test
flutter run
```

### Android configuration (one time)

1. **MainActivity.** Replace `android/app/src/main/kotlin/com/vaultix/vaultix/MainActivity.kt`
   with `android_setup/MainActivity.kt` (needed for biometrics; also hides the app
   in the recent-apps switcher).
2. **AndroidManifest.xml** (`android/app/src/main/`):
   - `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>`
   - on `<application>`: `android:label="Vaultix"` and `android:allowBackup="false"`
3. **minSdk** must be 23 or higher (`android/app/build.gradle` or `.kts`).
4. If the biometric prompt crashes with a theme error, set the parent of
   `LaunchTheme` and `NormalTheme` in `res/values/styles.xml` to
   `Theme.AppCompat.DayNight`.

Publisher details (developer name, contact email) live in
`lib/core/constants/app_info.dart`.

## Architecture

Feature-based layout with `data / domain / presentation` per feature and a
shared `core/`. State management is Riverpod; navigation is go_router with an
auth-aware redirect (splash → setup / lock → app shell). The structure is
pragmatic rather than strict Clean Architecture: repositories are concrete
classes exposed through providers, with no separate use-case layer.

```
lib/
  core/            constants, theme, security (crypto, secure store, clipboard),
                   database (sqflite), router, utils, shared widgets
  features/
    authentication/  master password, lock/setup, PIN, biometrics, auto-lock
    dashboard/       home screen
    vault/           credentials: list, form, detail, repository, cipher
    password_generator/
    password_health/ analysis engine, recommendations, health screen
    categories/
    settings/        security, appearance, backup/restore, clear vault, about, legal
```

## Security model

```
master password --Argon2id(salt)--> KEK --AES-256-GCM--> wraps random 256-bit vault key
vault key --AES-256-GCM (unique nonce, field-bound AAD)--> password and notes columns
```

- The master password is never stored. A wrong password simply fails to unwrap the key.
- The vault key exists in memory only while unlocked and is zeroed on lock.
- PIN: vault key wrapped by an Argon2id key derived from the PIN, stored in
  Keystore-backed secure storage; removed after 5 wrong attempts.
- Biometrics: a copy of the vault key in Keystore-backed secure storage, released
  only after an in-app biometric prompt (not hardware-bound to the sensor).
- Failed attempts: 5 free tries, then 30 s doubling to 15 min, persisted.
- Entry names, website, username and tags are stored unencrypted so search works.
- Clipboard is cleared after a configurable delay and on lock.
- `FLAG_SECURE` hides the app in the recent-apps switcher (also blocks screenshots).
- Argon2id comes from the `cryptography` package (pure Dart, run in an isolate), so
  it is slow in debug builds and fine in release.

## Backup file format

JSON: `{ format: "vaultix-backup", version: 1, kdf: {...}, salt, data }`. `data` is
the payload encrypted with AES-256-GCM under an Argon2id key from the *backup*
password (separate from the master password). KDF parameters are bounds-checked on
import.

## Database

SQLite via sqflite, schema version 2 (v1 → v2 adds `password_updated_at`,
`access_count` and seeds default categories). Tables: `credentials`, `categories`,
`settings`, `security`.

## Tests

`flutter test` runs crypto, backup codec, credential cipher, password strength,
generator, health analysis, recommendations, URL and filter logic, and a few widget
tests. SQLite repositories (merge/replace import, category rules, wipe) are not
covered by automated tests; use `RELEASE_CHECKLIST.md`.

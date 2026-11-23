# Vaultix release checklist

## 1. Build health
- [ ] `flutter pub get`, `flutter analyze` (no errors), `flutter test` (all pass)
- [ ] `dart run flutter_launcher_icons` has been run; the app shows the Vaultix icon and name
- [ ] Publisher details set in `lib/core/constants/app_info.dart`
- [ ] Privacy Policy and Terms reviewed (they are starting-point texts, not legal advice)

## 2. Manual test script (run on a real device)

**First run**
- [ ] Setup rejects short and weak master passwords and mismatched confirmation
- [ ] After setup the Home screen appears; restart the app: lock screen appears

**Unlock and lock**
- [ ] Wrong master password shows attempts left; after 5 a countdown lock appears and survives an app restart
- [ ] PIN: set up, unlock, 5 wrong PINs removes it
- [ ] Biometrics: enable in Settings, lock, unlock by fingerprint/face; cancel falls back to password
- [ ] Auto-lock: "as soon as I leave the app" locks on Home press; 1-minute option locks after idle and after backgrounding longer than a minute
- [ ] Manual lock buttons (Home header, Settings) work

**Vault**
- [ ] Add, view, edit, delete (with confirmation) an entry; fields persist after app restart
- [ ] Search by name, username, website and tag; category chips; favorites filter; both sort orders
- [ ] Copy username/password; clipboard is cleared after the chosen delay and on lock
- [ ] Open website works; an invalid URL is refused in the form
- [ ] Notes are shown after editing and do not appear in search

**Generator and health**
- [ ] Generator respects length and character types; last type cannot be switched off; "exclude similar" works
- [ ] "Save to vault" and the form's Generate button fill the password field
- [ ] Add a weak password and two entries sharing a password: Home score drops, Health screen lists them, fixing them raises the score

**Categories**
- [ ] Create, edit, delete a custom category (entries move to Other); defaults cannot be renamed/deleted

**Backup and restore**
- [ ] Export: wrong master password refused; share sheet opens; vault does not lock while sharing
- [ ] Import with wrong password is refused; with the right one shows a correct preview
- [ ] Merge skips duplicates; Replace asks for confirmation and restores everything (check one password and one note)
- [ ] A backup opened with a newer/corrupted file shows a clear message

**Destructive actions**
- [ ] Change master password: old password stops working, PIN/biometrics still work, entries still open
- [ ] Clear vault data: requires master password; app returns to setup with default categories only

**Upgrades**
- [ ] Install an older Vaultix build with entries, upgrade, confirm entries and categories survive (DB v1 → v2)

## 3. Privacy and permissions
- [ ] Merged release manifest has no `INTERNET` permission (check `build/app/intermediates/merged_manifests/` or `aapt dump permissions app-release.apk`)
- [ ] Recent-apps screen shows no vault content
- [ ] Dark and light themes both readable; test a small phone and a large phone/tablet in portrait and landscape

## 4. Release build
1. Create an upload keystore and `android/key.properties`; reference it in `android/app/build.gradle` signing config.
2. Set `version:` in `pubspec.yaml` (e.g. `1.0.0+1`).
3. `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`
4. Keep `build/symbols` and the keystore backed up.
5. Install the release APK once (`flutter build apk --release`) and repeat the first-run and unlock tests, because release uses R8 and different timing.

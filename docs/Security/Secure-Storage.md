# Local Data Encryption & Secure Storage

## Purpose
This guide evaluates local encryption options for protecting Personally Identifiable Information (PII) and preparing the codebase to pass security audits. It acknowledges our current Supabase token management flow and recommends a path forward as that dependency may evolve.

## Current State — Supabase Token Flow
`supabase_flutter` saves the login session (access token and refresh token) through a `LocalStorage` object. Its default, `SharedPreferencesLocalStorage`, writes plain text to `shared_preferences`. It does **not** use `flutter_secure_storage`, and `flutter_secure_storage` is not a dependency of `supabase_flutter`.

The app replaces that default. `SupabaseWrapperImpl.initialize()` passes `SecureSessionLocalStorage` (`lib/libraries/supabase/secure_session_local_storage.dart`) to `Supabase.initialize` through `authOptions`. It saves the session through `SecureStorageWrapper` (`lib/libraries/secure_storage/`), which wraps `flutter_secure_storage`. Tests use `FakeSecureStorageWrapper` in its place.

What it does:
- **New sign-in:** the session is written to secure storage under the key `sb-<project>-auth-token`. Nothing is written to `shared_preferences`.
- **Update from an earlier app version:** on start-up, a session found in `shared_preferences` under the same key is copied to secure storage and then deleted from `shared_preferences`, so signed-in users stay signed in. If the copy fails, the old entry stays and the copy is tried again on the next start. If secure storage already holds a session, it wins and the old entry is deleted.
- **Sign-out:** the session is removed from secure storage, and from `shared_preferences` if an old copy is still there.
- **Unreadable session:** if secure storage cannot be read (for example the Android Keystore key is gone), the app starts signed out. Supabase calls the read during start-up without catching errors, so a thrown error would stop the app from starting. `SecureStorageWrapperImpl` logs the failure to Sentry once.

Not covered:
- Supabase also keeps the PKCE code verifier in `shared_preferences` (`SharedPreferencesGotrueAsyncStorage`). It is a short-lived value used while a sign-in link is being completed, not a session token, and it is not moved.
- Any additional PII we store beyond auth tokens — names, IDs, private information, etc. — is not covered by Supabase. We are fully responsible for that.

## Native Security Layers

### iOS — Keychain Services
`flutter_secure_storage` writes items with `kSecAttrAccessibleWhenUnlocked` unless told otherwise (`KeychainAccessibility.unlocked`). Those items cannot be read while the phone is locked, which blocks a background token refresh, and they can move to a new phone through an encrypted backup.

`SecureStorageWrapperImpl` passes `IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device)` instead, which is `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.

## Security Properties
- Encrypted at rest: iOS encrypts Keychain items; the device must be unlocked once after a restart before items with this setting can be read.
- Post-Reboot Protection: Data is inaccessible after a restart until the user enters their passcode for the first time.
- Background Ready: Once the "First Unlock" occurs, the app can securely retrieve tokens to perform silent syncs even while the screen is locked.
- Stays on this device: the `ThisDeviceOnly` setting keeps items out of iCloud Keychain and prevents them being restored onto a different phone.


### Android — Keystore
Since `flutter_secure_storage` 10 the plugin no longer uses Jetpack `EncryptedSharedPreferences`. Version 11 removed the `encryptedSharedPreferences` option altogether, and the app pins 11.2.0, so there is nothing to switch on. The default `AndroidOptions()` wraps a random AES-GCM key with an RSA-OAEP key held in the Android Keystore, and stores the encrypted values in app-private shared preferences.

- Version 11 needs Android API 24 or newer, which is also the minimum Flutter 3.35 and later supports.
- Whether the Keystore key is hardware-backed depends on the device.
- `android:allowBackup="false"` is set in `AndroidManifest.xml`. The Keystore key is never backed up, so a restored copy of the encrypted values cannot be decrypted and the plugin throws `InvalidKeyException: Failed to unwrap key`. The plugin README recommends turning backup off for this reason. The cost is that Android's cloud backup and device-to-device transfer no longer carry any of the app's local data.

## Critical Gotcha — Data Persists After Uninstall (iOS)

> ⚠️ **Important:** On iOS, data stored via `flutter_secure_storage` persists across uninstall and reinstall.

Keychain data can persist across app uninstalls unless explicitly cleared, whereas Android typically wipes all app-associated data, including secure storage, upon uninstallation.

**The risk:** A user uninstalls the app, reinstalls it, and the app silently picks up stale tokens, cached PII, or old flags — without the user's awareness.

**Solution (not yet implemented, tracked by [CA-519](https://ripplearc.youtrack.cloud/issue/CA-519)):**
On first launch after a fresh install, check for a 'first-run' flag stored in regular `SharedPreferences` (which does get cleared on uninstall). If the flag is absent, run a `deleteAll()` on `flutter_secure_storage` to wipe any stale data.

> ⚠️ Because the session now lives in secure storage, the flag check alone is not safe. An app that was installed before the flag existed also has no flag, so a plain `deleteAll()` would sign out every user who updates. An absent flag with a session still in `shared_preferences` is an update, not a fresh install, and must not wipe.

```dart
// Run during app initialization
final prefs = await SharedPreferences.getInstance();
final isFirstRun = prefs.getBool('has_launched_before') ?? true;

if (isFirstRun) {
  await const FlutterSecureStorage().deleteAll();
  await prefs.setBool('has_launched_before', false);
}
```

[Read more about this issue](https://github.com/mogol/flutter_secure_storage/issues/43)
[Youtrack issue to implement this](https://ripplearc.youtrack.cloud/issue/CA-519).

## Package Comparison

### Option A — flutter_secure_storage

| Aspect | Details |
|--------|---------|
| **Best for** | Small, discrete secrets (tokens, keys, user IDs) |
| **Encryption** | Platform-native (Keychain / Keystore-wrapped AES-GCM) |
| **Data structure** | Simple key-value pairs |
| **Max data size** | Not designed for large datasets — degrades past ~100 keys |
| **Performance** | Very fast for reads/writes of small values |
| **OS update resilience** | Excellent — has survived multiple major OS updates. Occasional breakage on Android after major version jumps is documented, but patches arrive quickly |
| **Uninstall persist** | iOS: YES (see above). Android: No |
| **Audit suitability** | High — maps directly to OWASP MASVS L2 requirements |
| **Complexity** | Low |

**Verdict:** ✅ Right tool for secrets. ❌ Not the right tool for structured datasets.

### Option B — Hive (with AES-256 Encryption)

| Aspect | Details |
|--------|---------|
| **Best for** | Structured local datasets, user preferences, offline-first data |
| **Encryption** | AES-256-CBC via `hive_flutter` + a manually managed encryption key |
| **Data structure** | Key-value boxes (typed, schema-friendly) |
| **Max data size** | Handles MBs of data well; good for lists and objects |
| **Performance** | Very fast — pure Dart, zero native bridge, reads are near-instant |
| **OS update resilience** | Good — pure Dart means no native code update risks. Note: Hive is in maintenance mode since 2022; Isar (its successor) is actively developed |
| **Uninstall persist** | No — standard app data, cleared on uninstall |
| **Audit suitability** | Medium — encryption is app-layer only. The AES key must be stored in `flutter_secure_storage`, creating a two-layer dependency |
| **Complexity** | Medium — requires key management strategy |

**Verdict:** Good for larger encrypted datasets, but requires pairing with `flutter_secure_storage` to protect the Hive key. Maintenance status is a mild concern.

### Option C — SQLCipher (via sqflite_sqlcipher)

| Aspect | Details |
|--------|---------|
| **Best for** | Relational data requiring queries, joins, and structural integrity |
| **Encryption** | AES-256 at the database file level (SQLCipher standard) |
| **Data structure** | Full SQL — tables, indexes, relations |
| **Max data size** | Scales to large datasets (hundreds of MBs) |
| **Performance** | Slower than Hive for simple reads due to SQL + per-page encryption overhead. Acceptable for complex queries |
| **OS update resilience** | Moderate — SQLCipher is a native library. Has historically had friction around Play Store 64-bit requirements and App Store binary size reviews |
| **Uninstall persist** | No — standard app data |
| **Audit suitability** | High — widely accepted in enterprise and government audits; FIPS 140-2 compatible builds available |
| **Complexity** | High — full SQL schema management, migrations, and native dependency overhead |

**Verdict:** Overkill for most mobile use cases. Justified only if we have complex relational PII data or an explicit audit requirement for SQLCipher.

## Side-by-Side Summary

|  | flutter_secure_storage | Hive + AES-256 | SQLCipher |
|---|---|---|---|
| **Use case** | Tokens, secrets, small PII | Structured datasets | Relational datasets |
| **Encryption** | OS-native (hardware) | App-layer (AES-256) | File-level (AES-256) |
| **Performance** | Fastest | Fast | Moderate |
| **Structured data** | No | Yes | Yes |
| **OS update safety** | Strong | Strong | Requires monitoring |
| **Audit strength** | High | Medium | High |
| **Complexity** | Low | Medium | High |
| **Uninstall persist (iOS)** | YES — must handle | No | No |

## Recommendation

Use a **layered approach** — don't pick just one.

### Layer 1 — flutter_secure_storage for all secrets
This is non-negotiable. Tokens, encryption keys, and any small PII fields (user ID, email) should live here. It maps to the OS hardware security layer and satisfies OWASP MASVS compliance.

### Layer 2 — Hive (or Isar) for structured PII datasets
If we ever need to store larger structured data locally — offline user profiles, cached form data — Hive with AES-256 is the pragmatic choice. The Hive encryption key must itself be stored in `flutter_secure_storage`.

### SQLCipher — hold in reserve
If a future audit explicitly mandates SQLCipher, or if we evolve into storing complex relational PII data, it is worth revisiting. For now it introduces more complexity than it solves.

### Regarding Supabase
The login session is kept in secure storage by `SecureSessionLocalStorage` (see Current State above). Ensure any PII we store beyond Supabase-managed tokens is explicitly routed through `flutter_secure_storage`, not written to regular `SharedPreferences` or local files.

## Action Items

- [ ] **Priority: High** — Implement first-run stale data wipe on iOS to handle the uninstall persistence issue ([CA-519](https://ripplearc.youtrack.cloud/issue/CA-519)), keeping the update-versus-fresh-install check above
- [ ] **Priority: High** — Audit existing code for any PII written to `SharedPreferences`, local files, or logs — migrate to `flutter_secure_storage`
- [ ] **Priority: Medium** — Document the key management strategy if Hive is adopted: where the AES key lives and how it is rotated
- [ ] **Priority: Ongoing** — Monitor Supabase SDK changelogs for changes to the `LocalStorage` interface that `SecureSessionLocalStorage` extends
- [ ] **Priority: Medium** — The version is pinned to 11.2.0 in `pubspec.yaml`. [Establish a policy for reviewing it after major iOS/Android OS releases](https://ripplearc.youtrack.cloud/issue/CA-518/SecurityInfrastructure-Pin-fluttersecurestorage-Version-and-Establish-Review-Policy)

## Related Documentation

- [OWASP Mobile Application Security Verification Standard (MASVS)](https://github.com/OWASP/owasp-masvs)
- [Flutter Secure Storage Package](https://pub.dev/packages/flutter_secure_storage)
- [Supabase Flutter SDK](https://pub.dev/packages/supabase_flutter)
- [Original google doc](https://docs.google.com/document/d/1nGc02O13FRqPZ1XmNWETADTIwa7Mnm7b/edit)

# Local Data Encryption & Secure Storage

## Purpose
This guide evaluates local encryption options for protecting Personally Identifiable Information (PII) and preparing the codebase to pass security audits. It acknowledges our current Supabase token management flow and recommends a path forward as that dependency may evolve.

## Current State — Supabase Token Flow
Supabase's Flutter SDK (`supabase_flutter`) handles session tokens automatically. Internally, it uses `flutter_secure_storage` under the hood to persist the access token and refresh token on-device. This means we are already relying on secure storage — just indirectly.

**What this means for us:**
- Tokens are encrypted at rest through platform-native mechanisms (Keychain on iOS, Keystore / EncryptedSharedPreferences on Android)
- If Supabase's token strategy changes (e.g., moving to in-memory only, or introducing a custom adapter), we will need our own secure storage layer to remain in control
- Any additional PII we store beyond auth tokens — names, IDs, private information, etc. — is not covered by Supabase. We are fully responsible for that

## Native Security Layers

### iOS — Keychain Services
By default, `flutter_secure_storage` utilizes the `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` attribute. While this offers maximum security, it prevents the app from accessing data (like Auth Tokens) during background updates or silent notifications if the user's device is locked.
To support background processes, we must manually configure the storage to use `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` by passing `accessibility: KeychainAccessibility.first_unlock_this_device_only` to `IOSOptions` in `flutter_secure_storage` ios configuration.

## Security Properties
- Hardware Encryption: Data remains encrypted via the device’s Secure Enclave.
- Post-Reboot Protection: Data is inaccessible after a restart until the user enters their passcode for the first time.
- Background Ready: Once the "First Unlock" occurs, the app can securely retrieve tokens to perform silent syncs even while the screen is locked.
- No Cloud Leakage: Because we use the ThisDeviceOnly suffix, the keys are never synced to iCloud or included in unencrypted backups.


### Android — Keystore + EncryptedSharedPreferences
To ensure higher security on Android, manually enable `EncryptedSharedPreferences` by passing `encryptedSharedPreferences: true`, as this feature is disabled by default. This way the encryption key lives in hardware on supported devices and is never exposed to the app in plaintext.

- On Android 6.0+ (API 23+), hardware-backed key storage is available
- On older devices, it falls back to software-backed storage — still encrypted, but without hardware guarantees
- This is considered enterprise-safe for most compliance requirements (GDPR, HIPAA-adjacent)

## Critical Gotcha — Data Persists After Uninstall (iOS)

> ⚠️ **Important:** On iOS, data stored via `flutter_secure_storage` persists across uninstall and reinstall.

Keychain data can persist across app uninstalls unless explicitly cleared, whereas Android typically wipes all app-associated data, including secure storage, upon uninstallation.

**The risk:** A user uninstalls the app, reinstalls it, and the app silently picks up stale tokens, cached PII, or old flags — without the user's awareness.

**Solution:**
On first launch after a fresh install, check for a 'first-run' flag stored in regular `SharedPreferences` (which does get cleared on uninstall). If the flag is absent, run a `deleteAll()` on `flutter_secure_storage` to wipe any stale data.

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
| **Encryption** | Platform-native (Keychain / EncryptedSharedPreferences) |
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
No immediate changes are required to the token flow. The recommended action is to implement the first-run stale data wipe and ensure any PII we store beyond Supabase-managed tokens is explicitly routed through `flutter_secure_storage`, not written to regular `SharedPreferences` or local files.

## Action Items

- [ ] **Priority: High** — Implement first-run stale data wipe on iOS to handle the uninstall persistence issue
- [ ] **Priority: High** — Audit existing code for any PII written to `SharedPreferences`, local files, or logs — migrate to `flutter_secure_storage`
- [ ] **Priority: Medium** — Document the key management strategy if Hive is adopted: where the AES key lives and how it is rotated
- [ ] **Priority: Ongoing** — Monitor Supabase SDK changelogs for any changes to their storage adapter — if they shift away from `flutter_secure_storage`, we need our own token persistence layer
- [ ] **Priority: Medium** — [Pin the `flutter_secure_storage` version in `pubspec.yaml` and establish a policy for reviewing it after major iOS/Android OS releases](https://ripplearc.youtrack.cloud/issue/CA-518/SecurityInfrastructure-Pin-fluttersecurestorage-Version-and-Establish-Review-Policy)

## Related Documentation

- [OWASP Mobile Application Security Verification Standard (MASVS)](https://github.com/OWASP/owasp-masvs)
- [Flutter Secure Storage Package](https://pub.dev/packages/flutter_secure_storage)
- [Supabase Flutter SDK](https://pub.dev/packages/supabase_flutter)
- [Original google doc](https://docs.google.com/document/d/1nGc02O13FRqPZ1XmNWETADTIwa7Mnm7b/edit)

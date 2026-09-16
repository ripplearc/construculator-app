# RULE 15: Judicious Sentry Error Reporting

## Name
Sentry Logging

## Category
Error Handling & Monitoring

## Severity Levels
- **Critical:** Expected errors (validation, auth failures) logged to Sentry, wasting quota
- **Major:** Duplicate error logging across multiple layers
- **Minor:** Using `error()` when `warning()` or `info()` would suffice
- **Suggestion:** Consider using breadcrumbs instead of full error events

## Description

`AppLogger.error()` and `AppLogger.omg()` send events to Sentry and consume quota. Reserve them for genuinely unexpected failures. Expected errors, validation failures, and normal business-flow errors use lower severity levels.

**Core Principle:** Sentry is for bugs and unexpected system failures, not expected business-logic errors.

## Applicability

Applies to all code that uses `AppLogger` in `lib/`, particularly:
- Data layer: `lib/features/**/data/`
- Repository implementations
- DataSources
- Error handling boundaries

---

## For Coding Agents (Prescriptive)

### Core Principle

**Log errors at ONE layer only** — typically the DataSource (or Wrapper) at the system boundary. Upper layers (Repository, UseCase, BLoC) consume `Either<Failure, T>` without re-logging.

### Decision Tree: Which Log Level?

```
Is this error expected in normal operation?

├─ YES (expected business/system error)
│  ├─ User input validation failed?     → debug() or warning()  (no Sentry)
│  ├─ Expected API error (404, 409)?    → warning() or info()   (breadcrumb)
│  └─ Duplicate entry (unique constraint)? → warning()           (breadcrumb)
│
└─ NO (unexpected system failure)
   ├─ Parsing failed unexpectedly?     → error()  (Sentry event)
   ├─ Auth token invalid/expired?      → error()  (Sentry event)
   ├─ Critical storage failure?        → omg()    (critical Sentry event)
   └─ Invariant violation?             → omg()    (critical Sentry event)
```

### AppLogger Levels

| Level | Sentry Impact | When to Use | Example |
|-------|---------------|-------------|---------|
| `debug()` | None | Development debugging | `AppLogger.debug('Fetching user data')` |
| `info()` | Breadcrumb only | Normal operations | `AppLogger.info('User logged in successfully')` |
| `warning()` | Breadcrumb only | Expected errors | `AppLogger.warning('Invalid email format')` |
| `error()` | **Sentry event** ⚠️ | Unexpected failures | `AppLogger.error('Failed to parse response', error, stack)` |
| `omg()` | **Critical Sentry event** 🚨 | Critical failures | `AppLogger.omg('Database corruption detected', error, stack)` |

### Log Once — at the Boundary

Canonical pair (DataSource logs, Repository transforms):

```dart
// DataSource: log at boundary, then rethrow
class RemoteUserDataSource {
  Future<UserDto> fetchUser(String id) async {
    try {
      return await _api.get('/users/$id');
    } catch (e, stack) {
      AppLogger.error('Failed to fetch user from API', e, stack); // ✅ log once
      rethrow;
    }
  }
}

// Repository: no re-log, just translate to Failure
class UserRepositoryImpl {
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      final dto = await _dataSource.fetchUser(id);
      return Right(User.fromDto(dto));
    } catch (e) {
      return Left(NetworkFailure(message: 'Failed to fetch user')); // ✅ no log
    }
  }
}
```

**UseCase and BLoC do not log** — UseCase passes through `Either`, BLoC emits an error state.

### Distinguishing Expected from Unexpected

Inside a `catch` block, branch on the error code/type before choosing a log level:

- **Supabase / Postgrest:** `PGRST116` (not found), `23505` (duplicate), `23503` (FK) → `warning()`. Unknown PG codes, server errors → `error()`.
- **HTTP / Dio:** `404` → `info()`; `401` (token expired) → `error()`; other 5xx / network → `error()`.
- **Validation:** invalid input from the user is always `debug()` or `warning()`, **never** `error()`.
- **Auth:** wrong credentials → `warning()`; unexpected auth exception → `error()`.

---

## For Review Agents (Detective)

### Detection Patterns

| Pattern | Grep | Severity |
|---|---|---|
| `error()` / `omg()` use | `grep -rn "AppLogger.error\\|AppLogger.omg" lib/` — review each for "expected" context | Critical (if expected) |
| Duplicate logging at DataSource + Repository | `grep -A 5 "AppLogger.error" lib/ \| grep -E "(rethrow\\|return Left)"` | Major |
| Logging in upper layers | `grep -rn "AppLogger.error" lib/features/**/domain/ lib/features/**/presentation/` | Major |

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| `error('Invalid email')` | Use `debug()` or `warning()` | Critical |
| `error('404 not found')` | Use `info()` or `warning()` | Critical |
| `error('Duplicate entry')` (PG `23505`) | Use `warning()` | Critical |
| `error('Invalid credentials')` | Use `warning()` | Critical |
| Same error logged in DataSource AND Repository | Remove duplicate; log once at boundary | Major |
| `error()` in BLoC / UseCase | Move to DataSource / Repository / Wrapper | Major |
| `error()` without branching on error code | Add conditional: expected → `warning()`, unexpected → `error()` | Major |

### Review Questions

1. Is this error expected in normal operation? → if yes, must not be `error()` / `omg()`.
2. Is the error logged at multiple layers? → if yes, remove duplicate.
3. Is this a validation / user-input error? → must be `debug()` or `warning()`.
4. Does the catch branch on the SDK error code? → if not, it's likely over-logging.

---

## Summary: Suggested Fixes

1. **Reserve `error()` for unexpected failures** — parsing errors, system failures, invariant violations.
2. **Use `warning()` for expected errors** — validation, 404s, duplicates, invalid credentials.
3. **Log once at the boundary** — typically DataSource / Wrapper; never in UseCase / BLoC.
4. **Branch on error code** before picking a log level.
5. **Use breadcrumbs liberally** — `info()` / `warning()` are free context attached to real events.

## References

- [Sentry Best Practices](https://docs.sentry.io/platforms/flutter/best-practices/)
- Review Script Lines: 519-539 in `scripts/review_pr.sh`
- Related: UI / Business Separation, `code-data` skill (error mapping table)

## Notes

**Quota awareness:** every `error()` / `omg()` is a billable Sentry event. `debug()` / `info()` / `warning()` are free and produce breadcrumbs attached to the next real event.

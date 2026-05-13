---
name: code-data
description: |
  Stage 3: Coding (Data Layer) - Write RepositoryImpl, DataSources, and DTOs.
  Data layer implements repository interfaces and handles external data sources (API, DB, cache).

  ⚠️ INVOCATION: Only use when the ticket touches the data layer (repository implementations, data sources, API/DB access).

  Trigger: "write data code", "implement data layer", "create datasource" (DataSource interface + related data layer classes)

disable-model-invocation: false
---

# Code Data Skill

**Verb:** Write data layer code (RepositoryImpl, DataSources, DTOs).

**Input:** Context from `plan-implementation` + `code-domain` — repository interfaces, data classes, file paths.

## 1. Class Overview

| Class Type | Naming (RULE_2) | Purpose |
|------------|-----------------|---------|
| **DataSource** (interface) | `{Noun}DataSource` | Contract with **explicit method names** (e.g., `fetchInitialEstimationsByProjectId`) |
| **RemoteDataSource** | `Remote{Noun}DataSource` | Fetches from API/DB via `SupabaseWrapper` |
| **RepositoryImpl** | `{Noun}RepositoryImpl` | Implements domain repository; maps errors to Failures |
| **DTO** | `{Noun}Dto` | JSON ↔ Entity mapping |

## 2. RemoteDataSource Pattern

**Purpose:** Fetch data from external source (Supabase); log debug on success; rethrow errors.

**Required imports:**
```dart
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
```

**Logging:**
- Log debug on success: `_logger.debug('Fetched N items')`
- **Do NOT log errors** — RepositoryImpl is the error boundary (RULE_15)

**Error handling:**
- **Always rethrow** — Let RepositoryImpl handle error mapping and logging

## 3. RepositoryImpl Pattern

**Purpose:** Implement domain repository interface; delegate to DataSource; map exceptions to Failures.

**Required imports:**
```dart
import 'dart:async';
import 'dart:io';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
```

**Error mapping (at RepositoryImpl boundary):**

| Exception Type | Log Level | Failure Type | Notes |
|----------------|-----------|--------------|-------|
| `TimeoutException` | warning | `{Feature}Failure(timeoutError)` | Expected — network timeout; log warning only |
| `SocketException` | warning | `{Feature}Failure(connectionError)` | Expected — connection failure; log warning only |
| `PostgrestException` (expected) | warning | `{Feature}Failure(notFound/duplicate)` | Expected — `PGRST116` (not found), `23505` (duplicate), `23503` (FK violation); log warning only |
| `PostgrestException` (critical) | error | `{Feature}Failure(databaseError)` | Critical — unknown PG codes, server errors; log error (Sentry) |
| Other | error | `UnexpectedFailure()` | Critical — unexpected exceptions; log error (Sentry) |

**RULE_15 — Log once at RepositoryImpl only:**
- **Warning level:** Expected errors; no Sentry event
- **Error level:** Critical/unexpected errors; sends Sentry event

**Pattern:** Wrap datasource call in try-catch; return `Either<Failure, T>` (never throw).

**AppLogger signature:** `_logger.error('message', error, stackTrace)` or `_logger.warning('message', error, stackTrace)`

## 4. DTO Pattern

**Purpose:** Map JSON ↔ Domain entities.

**Validation:** Handle invalid/missing JSON gracefully:
- Use `as` casts with null-aware operators for required fields
- Provide sensible defaults or throw during `fromJson` if critical data missing
- Document expected JSON structure in dartdoc

## 5. Dependency Registration

Add to `lib/features/{feature}/{feature}_module.dart`:

```dart
void _registerDependencies(Injector i) {
  i.addLazySingleton<{Noun}DataSource>(() => Remote{Noun}DataSource(supabaseWrapper: i()));
  i.addLazySingleton<{Noun}Repository>(() => {Noun}RepositoryImpl(dataSource: i()));
}
```

## 6. Layer Boundaries (RULE_5)

| ❌ Data MUST NOT Import | ✅ Data CAN Import |
|-------------------------|-------------------|
| Presentation layer (BLoC, UI) | Domain interfaces (`{Noun}Repository`) |
| | DTOs (own layer) |
| | External SDKs (`SupabaseWrapper`, `Dio`) |
| | Logging (`AppLogger`) |

## Output Files

- `lib/features/{feature}/data/data_source/interfaces/{noun}_data_source.dart`
- `lib/features/{feature}/data/data_source/remote_{noun}_data_source.dart`
- `lib/features/{feature}/data/repositories/{noun}_repository_impl.dart`
- `lib/features/{feature}/data/models/{noun}_dto.dart`
- Updated: `lib/features/{feature}/{feature}_module.dart`

## Key Principles

1. **Explicit names** — `fetchInitialEstimationsByProjectId`, not `getEstimations` (RULE_2)
2. **Error boundary** — RemoteDataSource logs error then rethrows; RepositoryImpl is the boundary where exceptions become Failures
3. **DTO ↔ Entity** — DTOs for JSON; Entities for domain; validate/handle invalid JSON
4. **RULE_15: Log once** — At RepositoryImpl boundary only (don't re-log as errors propagate)
5. **Never throw from repository** — Always `Either<Failure, T>`

## References

- **RULE_2:** `skills/rules/02-naming-conventions.md`
- **RULE_5:** `skills/rules/05-ui-business-separation.md`
- **RULE_15:** Sentry logging at boundaries
- **Examples:** `lib/features/global_search/data/data_source/remote_global_search_data_source.dart`, `lib/features/global_search/data/repositories/global_search_repository_impl.dart`
- **Future:** `write-tests` skill (planned — unit tests for data layer with fakes)


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

Fetch from external source. Log `_logger.debug('Fetched N items')` on success; **always rethrow on error** — RepositoryImpl is the error boundary (RULE_15); do NOT log errors here.

## 3. RepositoryImpl Pattern

Implement domain repository interface; delegate to DataSource; map exceptions to Failures.

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

**Failure identification (before writing try-catch):**
1. List every failure case the repository method can produce (network, not-found, auth, validation, etc.)
2. Search `lib/features/{feature}/domain/` for an existing `{Feature}Failure` class — if it covers the case, **reuse it**
3. If no matching Failure exists, create `lib/features/{feature}/domain/failures/{feature}_failure.dart` with the new cases
4. Never invent a Failure inline — it must live in its own file and be importable by domain and data layers

**Pattern:** Wrap datasource call in try-catch; return `Either<Failure, T>` (never throw).

## 4. DTO Pattern

**Purpose:** Map JSON ↔ Domain entities.

**Validation:** Handle invalid/missing JSON gracefully:
- Use `as` casts with null-aware operators for required fields
- Provide sensible defaults or throw during `fromJson` if critical data missing
- Document expected JSON structure in dartdoc

## 5. Dependency Registration

In `{feature}_module.dart`, register DataSource as `addLazySingleton` (inject `SupabaseWrapper`) and RepositoryImpl as `addLazySingleton` (inject DataSource). See `code-domain` skill for the canonical `_registerDependencies` shape.

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
2. **Error boundary** — RemoteDataSource rethrows without logging; RepositoryImpl is the error boundary where exceptions become Failures
3. **DTO ↔ Entity** — DTOs for JSON; Entities for domain; validate/handle invalid JSON
4. **RULE_15: Log once** — At RepositoryImpl boundary only (don't re-log as errors propagate)
5. **Never throw from repository** — Always `Either<Failure, T>`. Use `package:construculator/libraries/either/either.dart` for `Either` and `package:construculator/libraries/errors/failures.dart` for `Failure` — **do NOT import `dartz`**.

## References

- **RULE_2:** `skills/rules/02-naming-conventions.md`
- **RULE_5:** `skills/rules/05-ui-business-separation.md`
- **RULE_15:** Sentry logging at boundaries
- **Examples:** `lib/features/global_search/data/data_source/remote_global_search_data_source.dart`, `lib/features/global_search/data/repositories/global_search_repository_impl.dart`
- `write-tests` skill — Unit tests for data layer with fakes


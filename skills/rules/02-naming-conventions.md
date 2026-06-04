# RULE 2: Naming Conventions & Abstraction Levels

## Rule ID
RULE_2

## Category
Architecture & Design

## Severity Levels
- **Critical:** Forbidden suffixes (`Helper`, `Util`, `Manager` alone)
- **Major:** Wrong suffix for layer (e.g., `Service` in data layer, missing `Local/Remote` prefix on DataSource)
- **Minor:** UseCase doesn't follow verb-noun pattern
- **Suggestion:** Name could be more descriptive

## Description

Class naming follows two principles:

1. **Suffix conventions** — suffixes indicate responsibility and layer.
2. **Abstraction levels** — name precision is **inversely** proportional to abstraction level. High level (UI/Domain) uses abstract names (`getEstimations`); low level (Data) uses concrete, explicit names (`fetchInitialEstimationsByProjectId`).

## Applicability

All production code in `lib/` across all architecture layers.

---

## Part 1: Class Suffix Conventions

### Quick Reference

| Suffix | Pattern | Purpose | Layer | Example |
|--------|---------|---------|-------|---------|
| **UseCase** | `VerbNounUseCase` | Single business operation | Domain | `GetUserEstimationsUseCase` |
| **Service** | `NounService` | Coordinates multiple operations | Domain | `AuthenticationService` |
| **Repository** | `NounRepository` | Data access abstraction (interface) | Domain | `EstimationRepository` |
| **RepositoryImpl** | `NounRepositoryImpl` | Repository implementation | Data | `EstimationRepositoryImpl` |
| **DataSource** | `(Local\|Remote)NounDataSource` | Raw data (API, DB, cache) | Data | `RemoteEstimationDataSource` |
| **BLoC** | `NounBloc` + `NounEvent` + `NounState` | UI state coordination | Presentation | `AuthBloc`, `AuthEvent`, `AuthState` |
| **Formatter** | `NounFormatter` | Data formatting | Helper | `CurrencyFormatter` |
| **Validator** | `NounValidator` | Input validation | Helper | `EmailValidator` |
| **Parser** | `NounParser` | String/data parsing | Helper | `JsonParser` |
| **Mapper** | `NounMapper` | Object-to-object mapping | Helper | `UserDtoMapper` |
| **Converter** | `NounConverter` | Type conversion | Helper | `TimestampConverter` |

### 🚫 Forbidden Suffixes

- ❌ `Helper` — too generic; pick a specific role (Formatter / Validator / Mapper / …).
- ❌ `Util` / `Utils` — same problem.
- ❌ `Manager` alone — use `Service` (unless it manages a stateful resource like a `ConnectionManager`).

### Decision Tree

```
What is the class responsibility?

├─ Single business operation?           → UseCase           (VerbNounUseCase)
├─ Multiple coordinated operations?     → Service           (NounService)
├─ Abstracts data access?               → Repository + RepositoryImpl
├─ Handles raw data (API/DB/Cache)?     → DataSource        ((Local|Remote)NounDataSource)
├─ Manages UI state?                    → BLoC + Event + State
└─ Transforms/validates/parses?         → Formatter / Validator / Parser / Mapper / Converter
```

Layer is determined by directory: `presentation/` / `domain/` / `data/`. Apply the suffix table once layer + responsibility are decided.

---

## Part 2: Abstraction-Level Naming

**Core principle:** name precision is inversely proportional to abstraction level.

```
HIGH ABSTRACTION (abstract names)
↑
│  UI / Domain                  → getEstimations, fetchUser, saveProject
│  Repository interface         → getEstimationsByProjectId, fetchUserById
│  Repository implementation    → fetchInitialEstimationsByProjectId, fetchUserFromCacheOrNetwork
│  DataSource                   → fetchInitialEstimationsByProjectId (explicit op + scope + lookup key)
↓
LOW ABSTRACTION (explicit names)
```

### Canonical Pair

```dart
// ❌ Bad — high level too explicit, low level too vague
class FetchInitialEstimationsFromSupabaseUseCase { } // exposes SDK
abstract class EstimationDataSource {
  Future<List<EstimationDto>> getEstimations(String id);  // hides pagination/reset semantics
}

// ✅ Good — abstract at high level, explicit at low level
class GetEstimationsUseCase {
  Stream<List<Estimation>> execute(String projectId) => repository.getEstimations(projectId);
}
abstract class EstimationDataSource {
  Future<List<EstimationDto>> fetchInitialEstimationsByProjectId(String id);
  // fetch = network · Initial = resets pagination · ByProjectId = lookup key
}
```

### Data-Layer Naming Requirements

✅ **Explicit names must encode:**
- **Operation type:** `fetch` (network), `load` (cache), `find` (search), `ensure` (get-or-create).
- **Scope/intent:** `Initial` (resets pagination), `Next` (paginates), `ByProjectId` (lookup key).
- **Side effects:** if the method creates/resets state, make it explicit.

❌ **Avoid:** hiding init / state-reset / get-or-create behind a bare `get…` in the data layer.

---

## For Review Agents (Detective)

### Check For

1. Forbidden suffixes: `Helper`, `Util`, `Utils`, bare `Manager`.
2. Wrong suffix for layer (UseCase outside `domain/usecases/`, DataSource outside `data/data_source/`, etc.).
3. DataSource missing `Local` / `Remote` prefix.
4. UseCase not in `VerbNounUseCase` form.
5. Vague data-layer methods: generic `get…` without operation type or scope; hidden side effects.

### Common Violations

| ❌ Violation | ✅ Fix | Severity | Layer |
|---|---|---|---|
| `class AuthHelper` | `class AuthenticationService` | Critical | Domain |
| `class DataUtil` | `class CurrencyFormatter` (or specific role) | Critical | Helper |
| `class UserUseCase` | `class GetUserUseCase` | Major | Domain |
| `class ApiDataSource` | `class RemoteUserDataSource` | Major | Data |
| `class EstimationDataSource` (no prefix) | `class RemoteEstimationDataSource` / `class LocalEstimationDataSource` | Major | Data |
| `getEstimations(id)` on a DataSource | `fetchInitialEstimationsByProjectId(id)` | Major | Data |
| `loadUser(id)` (source unspecified) | `loadUserFromCache(id)` or `fetchUserFromNetwork(id)` | Minor | Data |

---

## References

- [RULE_2 Gist: Class Naming Convention](https://gist.github.com/ripplearcgit/89f05e4f83e087f63148bbbb1d99a178)
- Related: RULE_5 (UI/Business Separation) — places classes in the right layer.

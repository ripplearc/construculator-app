# RULE 2: Naming Conventions & Abstraction Levels

## Rule ID
RULE_2

## Category
Architecture & Design

## Severity Levels
- **Critical:** Using forbidden suffixes (`Helper`, `Util`, `Manager` without Service)
- **Major:** Wrong suffix for layer (e.g., `Service` in data layer, missing `Local/Remote` prefix on DataSource)
- **Minor:** Name doesn't follow verb-noun pattern for UseCase
- **Suggestion:** Name could be more descriptive or follow abstraction principle better

## Description

Class naming must follow two principles:
1. **Suffix Conventions:** Use correct suffixes that indicate responsibility and layer
2. **Abstraction Levels:** Name precision inversely proportional to abstraction level
   - High level (UI/Domain): Abstract names (e.g., `getEstimations`)
   - Low level (Data/Repository): Concrete, explicit names (e.g., `fetchInitialProjectEstimations`)

## Applicability

Applies to all production code in `lib/` directory across all architecture layers.

---

## Part 1: Class Suffix Conventions

### Quick Reference Table

| Suffix | Pattern | Purpose | Layer | Example |
|--------|---------|---------|-------|---------|
| **UseCase** | `VerbNounUseCase` | Single business operation | Domain | `GetUserEstimationsUseCase` |
| **Service** | `NounService` | Complex domain logic, multiple operations | Domain | `AuthenticationService` |
| **Repository** | `NounRepository` | Data access abstraction (interface) | Domain | `EstimationRepository` |
| **RepositoryImpl** | `NounRepositoryImpl` | Repository implementation | Data | `EstimationRepositoryImpl` |
| **DataSource** | `(Local\|Remote)NounDataSource` | Raw data handling (API, DB, cache) | Data | `RemoteEstimationDataSource` |
| **BLoC** | `NounBloc` + `NounEvent` + `NounState` | UI state coordination | Presentation | `AuthBloc`, `AuthEvent`, `AuthState` |
| **Formatter** | `NounFormatter` | Data formatting/transformation | Helper | `CurrencyFormatter`, `DateFormatter` |
| **Validator** | `NounValidator` | Input validation | Helper | `EmailValidator` |
| **Parser** | `NounParser` | String/data parsing | Helper | `JsonParser` |
| **Mapper** | `NounMapper` | Object-to-object mapping | Helper | `UserDtoMapper` |
| **Converter** | `NounConverter` | Type conversion | Helper | `TimestampConverter` |

### 🚫 Forbidden Suffixes

- ❌ **`Helper`** - Too generic, doesn't indicate responsibility
- ❌ **`Util`** or **`Utils`** - Too generic, doesn't indicate responsibility
- ❌ **`Manager`** alone - Use `Service` instead (unless managing stateful resources)

---

## For Coding Agents (Prescriptive)

### Decision Tree: What Should I Name This Class?

```
What is the class responsibility?

├─ Single business operation?
│  └─ YES → UseCase
│     └─ Pattern: VerbNounUseCase
│     └─ Example: GetUserProfileUseCase, CreateProjectUseCase
│
├─ Multiple coordinated business operations?
│  └─ YES → Service
│     └─ Pattern: NounService
│     └─ Example: AuthenticationService, ValidationService
│
├─ Abstracts data access?
│  └─ YES → Repository (interface) + RepositoryImpl (implementation)
│     └─ Pattern: NounRepository, NounRepositoryImpl
│     └─ Example: UserRepository, UserRepositoryImpl
│
├─ Handles raw data (API/DB/Cache)?
│  └─ YES → DataSource
│     └─ Pattern: (Local|Remote)NounDataSource
│     └─ Example: RemoteUserDataSource, LocalEstimationDataSource
│
├─ Manages UI state?
│  └─ YES → BLoC
│     └─ Pattern: NounBloc + NounEvent + NounState
│     └─ Example: AuthBloc, AuthEvent, AuthState
│
└─ Transforms/validates/parses data?
   └─ YES → Specific Helper
      ├─ Formats data? → NounFormatter
      ├─ Validates input? → NounValidator
      ├─ Parses strings? → NounParser
      ├─ Maps objects? → NounMapper
      └─ Converts types? → NounConverter
```

### When Naming Classes

**Step 1: Identify the layer**
- Presentation: `lib/features/**/presentation/`
- Domain: `lib/features/**/domain/`
- Data: `lib/features/**/data/`

**Step 2: Identify the responsibility**
- Use the decision tree above

**Step 3: Apply naming pattern**
- Follow the table above

**Step 4: Apply abstraction principle** (see Part 2 below)

### Examples - What to Create

| Scenario | Layer | Correct Name | Wrong Name ❌ |
|----------|-------|--------------|---------------|
| Fetch user profile from API | Domain | `GetUserProfileUseCase` | `UserService`, `ProfileFetcher`, `UserHelper` |
| Handle authentication flow | Domain | `AuthenticationService` | `AuthUseCase`, `LoginHelper` |
| Abstract cost estimation data | Domain | `EstimationRepository` (interface) | `EstimationService`, `EstimationHelper` |
| Call Supabase API | Data | `RemoteEstimationDataSource` | `EstimationApiService`, `SupabaseHelper`, `EstimationDataSource` |
| Cache user data locally | Data | `LocalUserDataSource` | `UserCache`, `UserCacheHelper` |
| Format currency for display | Helper | `CurrencyFormatter` | `CurrencyHelper`, `CurrencyUtil` |
| Validate email format | Helper | `EmailValidator` | `ValidationHelper`, `EmailUtil` |
| Coordinate login UI state | Presentation | `AuthBloc` + `AuthEvent` + `AuthState` | `LoginManager`, `AuthHelper` |

---

## Part 2: Abstraction-Level Naming

### Core Principle

**Naming precision is inversely proportional to abstraction level.**

- **High Level (UI/Domain):** Focus on *what* → Abstract, business-oriented names
- **Low Level (Data/Repository):** Focus on *how* and *scope* → Concrete, explicit names

### The Abstraction Scale

```
HIGH ABSTRACTION (Abstract Names)
↑
│  UI/Domain Layer
│  └─ getEstimations
│  └─ fetchUser
│  └─ saveProject
│
│  Repository Interface
│  └─ getEstimationsByProjectId
│  └─ fetchUserById
│  └─ saveProjectWithMetadata
│
│  Repository Implementation
│  └─ fetchInitialEstimationsByProjectId
│  └─ fetchUserFromCacheOrNetwork
│  └─ saveProjectAndCreateDefaultEstimation
│
↓  DataSource Layer
LOW ABSTRACTION (Explicit Names)
```

### Examples by Layer

#### ✅ Good: High Level (UseCase/UI)

```dart
// UseCase - Abstract, business intent
class GetEstimationsUseCase {
  Stream<List<Estimation>> execute(String projectId) {
    return repository.getEstimations(projectId);
  }
}

// BLoC - Abstract event name
class EstimationBloc {
  void _onLoadEstimations(LoadEstimations event, ...) {
    // Abstract: "load" doesn't specify if it's from cache, network, etc.
  }
}
```

#### ❌ Bad: High Level with Low-Level Details

```dart
// Too explicit for domain layer
class FetchInitialEstimationsFromSupabaseUseCase { } // ❌
class RefreshCachedEstimationsUseCase { } // ❌

// Correct alternative
class GetEstimationsUseCase { } // ✅
```

#### ✅ Good: Low Level (Repository/DataSource)

```dart
// Repository Interface - More specific than UseCase
abstract class EstimationRepository {
  Stream<List<Estimation>> getEstimationsByProjectId(String projectId);
}

// Repository Implementation - Explicit about what it does
class EstimationRepositoryImpl implements EstimationRepository {
  @override
  Stream<List<Estimation>> getEstimationsByProjectId(String projectId) {
    return dataSource.fetchInitialEstimationsByProjectId(projectId);
  }
}

// DataSource - Very explicit: source, intent, scope
class RemoteEstimationDataSource {
  Future<List<EstimationDto>> fetchInitialEstimationsByProjectId(String id) {
    // Clearly defines:
    // - fetch (network operation)
    // - Initial (resets pagination)
    // - ByProjectId (lookup key)
  }
}
```

#### ❌ Bad: Low Level with Vague Names

```dart
// Repository - too vague
abstract class EstimationRepository {
  Stream<List<Estimation>> getEstimations(String id); // ❌
  // What does this do?
  // - Is it from cache?
  // - Does it reset pagination?
  // - Does it create a project if missing?
}

// DataSource - too vague
class RemoteEstimationDataSource {
  Future<List<EstimationDto>> getEstimations(String id); // ❌
  // Same problems - hiding complexity
}

// Correct alternatives
abstract class EstimationRepository {
  Stream<List<Estimation>> getEstimationsByProjectId(String projectId); // ✅
}

class RemoteEstimationDataSource {
  Future<List<EstimationDto>> fetchInitialEstimationsByProjectId(String id); // ✅
}
```

### Key Requirements for Data Layer

✅ **Explicit names must include:**
- **Operation type:** `fetch` (network), `load` (cache), `find` (search), `ensure` (get-or-create)
- **Scope/Intent:** `Initial` (reset pagination), `Next` (pagination), `ByProjectId` (lookup key)
- **Side effects:** If method has side effects (create, reset), make it explicit

❌ **Avoid hiding logic behind generic names:**
- Never hide initialization or state-reset logic behind generic `get` names in Data Layer
- Never hide "get-or-create" behavior behind `get` or `find`

---

## For Review Agents (Detective)

### Detection Patterns

**Pattern 1: Forbidden Suffixes**

```bash
# Grep for violations
grep -rn "class.*Helper" lib/
grep -rn "class.*Util" lib/
grep -rn "class.*Utils" lib/
grep -rn "class.*Manager(?!Service)" lib/
```

**Pattern 2: Wrong Suffix for Layer**

Check that:
- UseCases are in `lib/features/**/domain/usecases/`
- Services are in `lib/features/**/domain/services/`
- Repositories (interfaces) are in `lib/features/**/domain/repositories/`
- RepositoryImpl are in `lib/features/**/data/repositories/`
- DataSources are in `lib/features/**/data/datasources/`
- BLoCs are in `lib/features/**/presentation/bloc/`

**Pattern 3: Missing DataSource Prefix**

```bash
# DataSources must start with Local or Remote
grep -rn "class.*DataSource" lib/features/**/data/datasources/ | grep -v "^(Local|Remote)"
```

**Pattern 4: UseCase Naming**

```bash
# UseCases should follow VerbNounUseCase pattern
grep -rn "class.*UseCase" lib/features/**/domain/usecases/ | grep -v "^[A-Z][a-z]*[A-Z].*UseCase"
```

**Pattern 5: Vague Data Layer Names**

Flag methods in Repository/DataSource that:
- Use generic `get` without specifying scope (e.g., `getEstimations` without `ByProjectId`)
- Don't indicate if operation is network (`fetch`), cache (`load`), or search (`find`)
- Hide pagination reset or side effects

### Common Violations

| ❌ Violation | ✅ Fix | Severity | Layer |
|-------------|--------|----------|-------|
| `class AuthHelper` | `class AuthenticationService` | Critical | Domain |
| `class DataUtil` | `class DataFormatter` | Critical | Helper |
| `class UserUseCase` | `class GetUserUseCase` | Major | Domain |
| `class ApiDataSource` | `class RemoteUserDataSource` | Major | Data |
| `class EstimationDataSource` | `class RemoteEstimationDataSource` or `LocalEstimationDataSource` | Major | Data |
| `getEstimations(id)` in DataSource | `fetchInitialEstimationsByProjectId(id)` | Major | Data |
| `loadUser(id)` without specifying source | `loadUserFromCache(id)` or `fetchUserFromNetwork(id)` | Minor | Data |

---

## References
- [RULE_2 Gist: Class Naming Convention](https://gist.github.com/ripplearcgit/89f05e4f83e087f63148bbbb1d99a178)
- Related: RULE_5 (UI/Business Separation) - ensures classes in right layer

## Notes

This rule combines two related concepts:
1. **Suffix Conventions** (original RULE_2) - What to call classes based on responsibility
2. **Abstraction Naming** (original RULE_11) - How abstract or concrete names should be based on layer

Both serve the same goal: making code self-documenting through consistent, meaningful names.

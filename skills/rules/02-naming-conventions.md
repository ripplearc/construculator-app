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

#### ✅ Good: Abstract names at high levels, explicit at low levels

```dart
// UI/Domain - Abstract (focuses on "what")
class GetEstimationsUseCase {
  Stream<List<Estimation>> execute(String projectId) {
    return repository.getEstimations(projectId);
  }
}

// Data - Explicit (specifies "how" and "scope")
class RemoteEstimationDataSource {
  Future<List<EstimationDto>> fetchInitialEstimationsByProjectId(String id) {
    // fetch = network, Initial = resets pagination, ByProjectId = lookup key
  }
}
```

#### ❌ Bad: Wrong abstraction level

```dart
// High level too explicit
class FetchInitialEstimationsFromSupabaseUseCase { } // ❌ Exposes implementation
class GetEstimationsUseCase { } // ✅

// Low level too vague
class RemoteEstimationDataSource {
  Future<List<EstimationDto>> getEstimations(String id); // ❌ Hides complexity
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

**Check for:**
1. **Forbidden suffixes:** `Helper`, `Util`, `Utils`, `Manager` (without Service)
2. **Wrong suffix for layer:** UseCases not in domain/usecases/, DataSources not in data/data_source/, etc.
3. **Missing DataSource prefix:** DataSources must start with `Local` or `Remote`
4. **UseCase naming:** Must follow `VerbNounUseCase` pattern
5. **Vague Data layer names:** Methods using generic `get` without scope, not indicating operation type (`fetch`/`load`/`find`), hiding side effects

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

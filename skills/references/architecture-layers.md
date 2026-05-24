# Architecture Layers Reference

This reference defines the responsibility boundaries and directory conventions for Flutter Clean Architecture. Used by RULE_2 (Naming Conventions) and RULE_5 (UI/Business Separation).

---

## Layer Stack (Top to Bottom)

```
┌─────────────────────────────────────────┐
│ PRESENTATION (UI)                        │
│ - Widgets, Pages, BLoCs                 │
│ - User interaction & state rendering    │
│ - lib/features/**/presentation/         │
│ - lib/app/                              │
└─────────────────────────────────────────┘
           ↓ Events / States
┌─────────────────────────────────────────┐
│ DOMAIN (Business Logic)                 │
│ - UseCases, Entities, Services          │
│ - Pure business rules                   │
│ - lib/features/**/domain/               │
│ - lib/libraries/**/domain/              │
└─────────────────────────────────────────┘
           ↓ Calls / Returns
┌─────────────────────────────────────────┐
│ DATA (Infrastructure)                   │
│ - Repositories, DataSources, DTOs       │
│ - External integrations                 │
│ - lib/features/**/data/                 │
│ - lib/libraries/**/data/                │
└─────────────────────────────────────────┘
```

---

## Presentation Layer

**Location:** `lib/features/**/presentation/` or `lib/app/`

**Responsibilities:**
- Render UI based on state
- Collect user inputs and dispatch events
- Navigation
- Display errors and loading states

**What belongs here:**
- `*Page` widgets (top-level screens)
- `*Bloc` + `*Event` + `*State`
- `*Widget` (presentation components)
- `*Controller` (for forms, animations)

**What does NOT belong:**
- ❌ Business logic (validation, calculations)
- ❌ Data transformations
- ❌ Direct database or API calls
- ❌ State derivations (use selectors in BLoC instead)

**Naming:** Abstract, user-facing names (see RULE_2)
- `LoginPage` (not `SupabaseAuthPage`)
- `EstimationBloc` (not `PostgresEstimationBloc`)

**Related Rules:**
- RULE_2: Naming Conventions
- RULE_5: UI/Business Separation
- RULE_4: CoreUI Components

---

## Domain Layer

**Location:** `lib/features/**/domain/` or `lib/libraries/**/domain/`

**Responsibilities:**
- Business logic and rules
- Use case orchestration
- Domain entities and value objects
- Service abstractions

**What belongs here:**
- `*UseCase` - Single business operation
- `*Service` - Complex business logic
- `*Entity` - Domain models (not DTOs!)
- `*Repository` (interface only)
- `*Failure` - Domain errors

**What does NOT belong:**
- ❌ UI widgets or rendering logic
- ❌ Database schemas or API models
- ❌ External library dependencies (HTTP, DB)
- ❌ Implementation details

**Naming:** Business-focused, technology-agnostic (see RULE_2)
- `GetEstimationsUseCase` (not `FetchFromSupabaseUseCase`)
- `Estimation` entity (not `EstimationDto`)
- `EstimationRepository` interface (implementation is in data/)

**Related Rules:**
- RULE_2: Naming Conventions
- RULE_3: Test Double Pattern

---

## Data Layer

**Location:** `lib/features/**/data/` or `lib/libraries/**/data/`

**Responsibilities:**
- Implement repository interfaces
- Fetch/persist data from external sources
- Map between DTOs and domain entities
- Handle network and database errors

**What belongs here:**
- `*RepositoryImpl` - Repository implementations
- `*DataSource` (Remote/Local)
- `*Dto` - Data transfer objects
- `*Mapper` - DTO ↔ Entity conversion
- Database clients, HTTP clients

**What does NOT belong:**
- ❌ Business logic (that's domain's job)
- ❌ UI rendering
- ❌ Direct user interaction

**Naming:** Technology-aware, concrete (see RULE_2)
- `EstimationRepositoryImpl` (implements `EstimationRepository`)
- `RemoteEstimationDataSource` (uses Supabase)
- `LocalEstimationDataSource` (uses SQLite)
- `EstimationDto` (JSON/database schema)

**Related Rules:**
- RULE_2: Naming Conventions
- RULE_3: Test Double Pattern
- RULE_15: Sentry Logging (log at boundaries)

---

## Dependency Flow

**Rule:** Dependencies flow inward only.

```
Presentation → Domain → Data
     ✅           ✅       ✅

Data → Domain
  ❌ (Data can't depend on Domain implementations, only interfaces)

Domain → Presentation
  ❌ (Domain should never know about UI)
```

**Example:**
```dart
// ✅ Good: Presentation depends on Domain
class EstimationBloc {
  final GetEstimationsUseCase getEstimations;  // Domain UseCase
}

// ✅ Good: Domain defines interface, Data implements
abstract class EstimationRepository {  // Domain interface
  Future<Either<Failure, List<Estimation>>> getEstimations(String projectId);
}

class EstimationRepositoryImpl implements EstimationRepository {  // Data implementation
  // ...
}

// ❌ Bad: Domain depending on Data
class GetEstimationsUseCase {
  final EstimationRepositoryImpl repository;  // ❌ Should depend on interface!
}

// ❌ Bad: Domain depending on Presentation
class ValidationService {
  final BuildContext context;  // ❌ Domain shouldn't know about UI!
}
```

---

## Directory Conventions

### Feature Structure
```
lib/features/estimation/
├── data/
│   ├── data_source/
│   │   ├── local_estimation_data_source.dart
│   │   └── remote_estimation_data_source.dart
│   ├── models/
│   │   └── estimation_dto.dart
│   └── repositories/
│       └── estimation_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── estimation.dart
│   ├── repositories/
│   │   └── estimation_repository.dart
│   └── usecases/
│       ├── get_estimations_usecase.dart
│       └── save_estimation_usecase.dart
└── presentation/
    ├── bloc/
    │   ├── estimation_bloc.dart
    │   ├── estimation_event.dart
    │   └── estimation_state.dart
    ├── pages/
    │   └── estimation_list_page.dart
    └── widgets/
        └── estimation_card.dart
```

### Libraries (Shared) Structure
```
lib/libraries/estimation/
├── data/
│   ├── data_source/
│   │   └── interfaces/
│   ├── models/
│   └── repositories/
└── domain/
    ├── entities/
    ├── enums/
    └── repositories/

lib/libraries/errors/
└── domain/
    └── failures.dart

lib/libraries/supabase/
└── data/
    └── supabase_client.dart
```

---

## Quick Decision Guide

**I'm writing code that...**

| Does it...? | → Put it in... |
|------------|---------------|
| Renders UI, shows widgets | Presentation |
| Validates business rules | Domain (UseCase/Service) |
| Calls an API or database | Data (DataSource) |
| Maps DTO to Entity | Data (RepositoryImpl) |
| Coordinates multiple operations | Domain (UseCase) |
| Handles button presses | Presentation (BLoC event) |
| Decides if user can delete item | Domain (Service/UseCase) |
| Fetches from Supabase | Data (RemoteDataSource) |

---

## Common Anti-Patterns

### ❌ Business Logic in Presentation

```dart
// ❌ Bad: Validation in widget
class LoginPage extends StatelessWidget {
  void _onSubmit() {
    if (email.contains('@') && password.length >= 8) {  // ❌ Business logic!
      context.read<AuthBloc>().add(LoginRequested(email, password));
    }
  }
}

// ✅ Good: Validation in Domain
class LoginPage extends StatelessWidget {
  void _onSubmit() {
    // Just dispatch, let domain validate
    context.read<AuthBloc>().add(LoginRequested(email, password));
  }
}

class AuthBloc {
  Future<void> _onLoginRequested(event) async {
    final result = await loginUseCase.execute(event.email, event.password);
    // UseCase validates email/password format
  }
}
```

### ❌ UI Concerns in Domain

```dart
// ❌ Bad: UI logic in UseCase
class GetEstimationsUseCase {
  Future<Either<Failure, String>> execute(String projectId) async {
    final result = await repository.getEstimations(projectId);
    return result.map((estimations) {
      // ❌ Formatting for display - that's UI's job!
      return estimations.map((e) => '\$${e.amount}').join(', ');
    });
  }
}

// ✅ Good: UseCase returns domain entities, UI formats
class GetEstimationsUseCase {
  Future<Either<Failure, List<Estimation>>> execute(String projectId) {
    return repository.getEstimations(projectId);
  }
}

// BLoC or Widget formats for display
Text('\$${estimation.amount}')
```

### ❌ Data Layer Doing Business Logic

```dart
// ❌ Bad: Business rules in Repository
class EstimationRepositoryImpl {
  Future<Either<Failure, void>> save(Estimation estimation) async {
    // ❌ Business validation should be in Domain!
    if (estimation.amount <= 0) {
      return Left(ValidationFailure('Amount must be positive'));
    }
    await dataSource.save(estimation.toDto());
    return Right(unit);
  }
}

// ✅ Good: Repository just saves, UseCase validates
class SaveEstimationUseCase {
  Future<Either<Failure, void>> execute(Estimation estimation) async {
    // ✅ Validation in domain
    if (estimation.amount <= 0) {
      return Left(ValidationFailure('Amount must be positive'));
    }
    return repository.save(estimation);
  }
}
```

---

## Summary

| Layer | Responsibility | Example Classes | Naming Style |
|-------|---------------|-----------------|--------------|
| **Presentation** | Render & collect input | `*Page`, `*Bloc`, `*Widget` | Abstract, user-facing |
| **Domain** | Business logic | `*UseCase`, `*Entity`, `*Service` | Business-focused |
| **Data** | External integration | `*RepositoryImpl`, `*DataSource`, `*Dto` | Technology-aware |

**Golden Rule:** Each layer solves ONE kind of problem. Don't mix concerns.

---

## References

- RULE_2: Naming Conventions (class naming by layer)
- RULE_5: UI/Business Separation (what belongs in UI vs Domain)
- [Flutter Clean Architecture](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [Uncle Bob's Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

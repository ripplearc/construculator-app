---
name: code-domain
description: |
  Stage 3: Coding (Domain Layer) - Write UseCases, Repositories (interfaces), and Services.
  Domain layer contains pure business logic with no knowledge of UI or data sources.

  ⚠️ INVOCATION: Only use when the ticket touches the domain layer (business logic, use cases, repository interfaces).

  Trigger: "write domain layer code", "implement domain layer use cases", "create domain usecase"

disable-model-invocation: false
---

# Code Domain Skill

**Verb:** Write domain layer code (UseCases, Repository interfaces, Services).

**Input:** Context from `plan-implementation` — class names, file paths, dependencies.

## Domain Class Patterns

| Class Type | Naming | Signature | Responsibilities | Forbidden |
|------------|--------|-----------|------------------|-----------|
| **UseCase** | `{Verb}{Noun}UseCase` | `Future<Either<Failure, T>> call(Param p)` | Single business operation; delegates to repository | Business logic implementation (delegate to repository) |
| **Repository** | `{Noun}Repository` (abstract) | `Future<Either<Failure, T>> methodNameByScope(Param p)` | Data access contract with **explicit names** (RULE_2) | Implementation details (data sources, SDKs) |
| **Service** | `{Noun}Service` | `Future<Either<Failure, T>> methodName(Param p)` | Coordinates multiple repositories | Direct data access (use repositories) |

**Examples of explicit repository names (RULE_2):**
- ✅ `fetchInitialEstimationsByProjectId`, `loadMoreLogs`, `hasMoreLogs`
- ❌ `getEstimations`, `fetchData`, `load`

## Enums

Document each enum case with dartdoc comments explaining business meaning.


## Required Imports

```dart
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
```

## Dependency Registration

Add to `lib/features/{feature}/{feature}_module.dart`:

```dart
void _registerDependencies(Injector i) {
  i.add<{Verb}{Noun}UseCase>(() => {Verb}{Noun}UseCase(i()));
  i.add<{Noun}Service>(() => {Noun}Service(repo1: i(), repo2: i())); // If needed
}
```

## Layer Boundaries (RULE_5)

| ❌ Domain MUST NOT Import | ✅ Domain CAN Import |
|---------------------------|---------------------|
| Flutter widgets (`package:flutter`) | Entities |
| Data layer (`RepositoryImpl`, `DataSource`) | Failures |
| Presentation layer (`BLoC`, UI) | Either |
| | Repository interfaces (abstract) |

## Output Files

- `lib/features/{feature}/domain/usecases/{verb}_{noun}_usecase.dart`
- `lib/features/{feature}/domain/repositories/{noun}_repository.dart`
- `lib/features/{feature}/domain/services/{noun}_service.dart` (if coordinating multiple repos)
- Updated: `lib/features/{feature}/{feature}_module.dart`

## Priority Rules (Critical to Success)

### 🔴 Non-Negotiable (Must Follow)
1. **Pure business logic** — No UI, no data source knowledge
2. **No layer violations** — Domain MUST NOT import Flutter, data layer, or presentation layer (see RULE_5)
3. **Either, never throw** — Always return `Either<Failure, T>`, never throw exceptions

### 🟡 Core Patterns (Always Apply)
4. **UseCases orchestrate** — Delegate to repositories; don't implement business rules
5. **Explicit repository names** — Use `fetchInitialByProjectId`, not `get` (RULE_2)
6. **Dartdoc required** — Document parameters, return types, edge cases

## References

- **RULE_2:** `skills/rules/02-naming-conventions.md`
- **RULE_5:** `skills/rules/05-ui-business-separation.md`
- **Examples:** `lib/features/auth/domain/usecases/login_usecase.dart`, `lib/features/estimation/domain/repositories/cost_estimation_log_repository.dart`
- **Next:** `code-data` (implements repository interfaces)
- **Future:** `write-tests` skill (planned — unit tests for domain layer)

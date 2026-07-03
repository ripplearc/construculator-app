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
| **Repository** | `{Noun}Repository` (abstract) | `Future<Either<Failure, T>> methodNameByScope(Param p)` | Data access contract with **explicit names** (Naming & Abstraction) | Implementation details (data sources, SDKs) |
| **Service** | `{Noun}Service` | `Future<Either<Failure, T>> methodName(Param p)` | Coordinates multiple repositories | Direct data access (use repositories) |

**Examples of explicit repository names (Naming & Abstraction):**
- ✅ `fetchInitialEstimationsByProjectId`, `loadMoreLogs`, `hasMoreLogs`
- ❌ `getEstimations`, `fetchData`, `load`

## Entities

Prefer `Equatable` for all entities to enable value equality without boilerplate:

- ✅ Extend `Equatable` and override `props`
- ❌ Don't manually override `==` and `hashCode`

## Dependency Registration

Add to `lib/features/{feature}/{feature}_module.dart`:

```dart
void _registerDependencies(Injector i) {
  i.add<{Verb}{Noun}UseCase>(() => {Verb}{Noun}UseCase(i()));
  i.add<{Noun}Service>(() => {Noun}Service(repo1: i(), repo2: i())); // If needed
}
```

## Layer Boundaries (UI / Business Separation)

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
2. **No layer violations** — Domain MUST NOT import Flutter, data layer, or presentation layer (see UI / Business Separation)
3. **Either, never throw** — Always return `Either<Failure, T>`, never throw exceptions. Use `package:construculator/libraries/either/either.dart` for `Either` and `package:construculator/libraries/errors/failures.dart` for `Failure` — **do NOT import `dartz`**. Before writing interface signatures, identify all failure cases: search `lib/features/{feature}/domain/` for an existing `{Feature}Failure` — reuse it if found, otherwise note that `code-data` must create it.

### 🟡 Core Patterns (Always Apply)
4. **UseCases orchestrate** — Delegate to repositories; don't implement business rules
5. **Explicit repository names** — Use `fetchInitialByProjectId`, not `get` (Naming & Abstraction)
6. **Dartdoc required** — Document parameters, return types, edge cases

## References

- **Naming & Abstraction:** `skills/rules/02-naming-conventions.md`
- **UI / Business Separation:** `skills/rules/05-ui-business-separation.md`
- **Examples:** `lib/features/auth/domain/usecases/login_usecase.dart`, `lib/features/estimation/domain/repositories/cost_estimation_log_repository.dart`
- **Next:** `code-data` (implements repository interfaces)
- `write-tests` skill — Unit tests for domain layer

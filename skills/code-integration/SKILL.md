---
name: code-integration
description: |
  Stage 3: Coding (Integration Layer) - GATED - Only for new third-party SDK integrations.
  Creates wrapper layer so domain never imports SDKs directly.

  ⚠️ GATED: Only use when ticket explicitly requires adding an external service/SDK that is not previously implemented or integrated in the codebase.
  Examples: new payment provider, analytics SDK, push notification service.

  Trigger: "integrate new SDK", "add third party service", "create wrapper"

disable-model-invocation: false
---

# Code Integration Skill

**Verb:** Write integration wrapper for a new third-party SDK.

⚠️ **GATED** — Only when the ticket requires adding an external service or SDK that is not previously implemented or integrated in the codebase.

## Gate Check

| ✅ Use This Skill | ❌ Use `code-data` Instead |
|------------------|---------------------------|
| NEW payment provider (Stripe, PayPal) | Existing Supabase (use `SupabaseWrapper`) |
| NEW analytics SDK (Mixpanel, Amplitude) | Existing auth (use `AuthManager`) |
| NEW cloud service (AWS S3, Firebase Storage) | Regular data sources |
| NEW push notification provider | |
| NEW OAuth provider | |

**Input:** Context from `plan-implementation` — SDK name, wrapper interface (if needed), operations needed.

## Wrapper Pattern Classes

| Class Type | Naming (RULE_2) | Signature | Responsibilities | Type Boundary |
|------------|-----------------|-----------|------------------|---------------|
| **Wrapper** | `{SDK}Wrapper` | Concrete class with SDK-specific methods | Wraps SDK client; maps SDK types ↔ domain types; handles SDK errors | **Only place SDK types appear** |
| **Interface** (optional) | `{SDK}WrapperInterface` | Abstract class with domain types only | Domain-facing contract when abstraction needed | Domain sees this |
| **Failure** | `{SDK}Failure extends Failure` | `{SDK}ErrorType errorType` | SDK-specific error types (timeout, auth, rate limit, etc.) | Domain error type |
| **Fake** (test) | `Fake{SDK}Client` | `implements sdk.{SDK}Client` | Test double with pre-configured responses/errors (RULE_3) | Test boundary |

**Pattern:** Create wrapper in `lib/libraries/{sdk}/{sdk}_wrapper.dart` that domain code depends on directly (or via optional interface).

## Wrapper Error Mapping

| SDK Exception | Log Level | Failure Type | Notes |
|---------------|-----------|--------------|-------|
| SDK-specific (e.g., `sdk.{SDK}Exception`) | error | `{SDK}Failure(errorType: ...)` | Map SDK error codes to domain types |
| `TimeoutException` | warning | `{SDK}Failure(timeout)` | Expected error |
| Other | error | `UnexpectedFailure()` | RULE_15: Log once at wrapper boundary |

## Required Imports

```dart
// Wrapper
import 'package:{sdk_package}/{sdk_package}.dart' as sdk;
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
```

## Dependency Registration

Create `lib/libraries/{sdk}/_{sdk}_module.dart`:

```dart
import 'package:flutter_modular/flutter_modular.dart';
import 'package:{sdk_package}/{sdk_package}.dart' as sdk;

class {SDK}Module extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<sdk.{SDK}Client>(() => sdk.{SDK}Client(apiKey: /* config */));
    i.addLazySingleton<{SDK}Wrapper>(() => {SDK}Wrapper(client: i()));
    // Or with interface: i.addLazySingleton<{SDK}WrapperInterface>(() => {SDK}Wrapper(client: i()));
  }
}
```

Then import in `lib/app/app_module.dart`.

## Output Files

- `lib/libraries/{sdk}/interfaces/{sdk}_wrapper_interface.dart` (optional — only if abstraction needed)
- `lib/libraries/{sdk}/{sdk}_wrapper.dart`
- `lib/libraries/{sdk}/_{sdk}_module.dart`
- `lib/libraries/{sdk}/domain/{sdk}_failure.dart`
- `test/libraries/{sdk}/fake_{sdk}_client.dart` (RULE_3: fake, not mock)
- `test/libraries/{sdk}/{sdk}_wrapper_test.dart`
- Updated: `lib/app/app_module.dart` (import `{SDK}Module`)

## Key Principles

1. **Domain isolation** — Wrapper is boundary; domain never imports SDK directly
2. **Wrapper is type translation layer** — SDK types → Domain types
3. **Error translation** — SDK exceptions → Domain Failures at wrapper boundary
4. **Testability** — Fake SDK client (RULE_3), test wrapper mapping logic

## References

- **RULE_2:** `skills/rules/02-naming-conventions.md`
- **RULE_3:** `skills/rules/03-test-double-pattern.md`
- **RULE_15:** Sentry logging at boundaries
- **Clean Architecture:** Domain depends on wrappers, not SDKs
- **Example:** `lib/libraries/supabase/supabase_wrapper.dart`
- **Future:** `write-tests` skill (planned — wrapper tests with fake SDK clients)

⚠️ **Use sparingly** — Most data access uses existing wrappers (`SupabaseWrapper`, `AuthManager`). Only for external services or SDKs that are not previously implemented or integrated in the codebase.


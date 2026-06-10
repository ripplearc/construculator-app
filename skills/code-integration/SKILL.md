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

- ✅ Use this skill for NEW SDKs/services not yet in the codebase (payment, analytics, cloud storage, push, OAuth).
- ❌ Use `code-data` for existing integrations (`SupabaseWrapper`, `AuthManager`) or regular data sources.
- ⚠️ **Gate failure:** If the SDK already exists, **stop immediately** — point the user to `code-data` and the existing wrapper.

**Input:** Context from `plan-implementation` — SDK name, wrapper interface (if needed), operations needed.

## Wrapper Pattern Classes

| Class Type | Naming (RULE_2) | Signature | Responsibilities | Type Boundary |
|------------|-----------------|-----------|------------------|---------------|
| **Wrapper** | `{SDK}Wrapper` | Concrete class with SDK-specific methods | Wraps SDK client; maps SDK types ↔ domain types; handles SDK errors | **Only place SDK types appear** |
| **Interface** (optional) | `{SDK}WrapperInterface` | Abstract class with domain types only | Domain-facing contract when abstraction needed | Domain sees this |
| **Failure** | `{SDK}Failure extends Failure` | `{SDK}ErrorType errorType` | SDK-specific error types (timeout, auth, rate limit, etc.) | Domain error type |
| **Fake** (test) | `Fake{SDK}Client` | `implements sdk.{SDK}Client` | Faithful re-implementation of the SDK client interface; injected in place of the real SDK in tests; exposes configurable fields to control responses and errors per-test (RULE_3) | Test boundary |

**Pattern:** Create wrapper in `lib/libraries/{sdk}/{sdk}_wrapper.dart` that domain code depends on directly (or via optional interface).

## Wrapper Error Mapping

| SDK Exception | Log Level | Failure Type | Notes |
|---------------|-----------|--------------|-------|
| SDK-specific (e.g., `sdk.{SDK}Exception`) | error | `{SDK}Failure(errorType: ...)` | Map SDK error codes to domain types |
| `TimeoutException` | warning | `{SDK}Failure(timeout)` | Expected error |
| Other | error | `UnexpectedFailure()` | RULE_15: Log once at wrapper boundary |


## Dependency Registration

Create `lib/libraries/{sdk}/_{sdk}_module.dart` extending `Module`. In `binds(Injector i)`, register the SDK client (`sdk.{SDK}Client` with API key from `EnvLoader`) and the wrapper (`{SDK}Wrapper`) as `addLazySingleton`. Use a `{SDK}WrapperInterface` binding if domain depends on an interface. Import the module in `lib/app/app_module.dart`.

**Config pattern:** Keys are read from `assets/env/.env.{dev|qa|prod}` via `EnvLoader` (already in DI — inject with `i.get<EnvLoader>()`). Never hardcode credentials. Add the key to all three `.env` files.

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
3. **Error translation** — SDK exceptions → Domain Failures at wrapper boundary. `{SDK}Failure extends Failure` and `UnexpectedFailure` both come from `package:construculator/libraries/errors/failures.dart`
4. **Testability** — Fake SDK client (RULE_3), test wrapper mapping logic

## References

- **RULE_2:** `skills/rules/02-naming-conventions.md`
- **RULE_3:** `skills/rules/03-test-double-pattern.md`
- **RULE_15:** Sentry logging at boundaries
- **Clean Architecture:** Domain depends on wrappers, not SDKs
- **Example:** `lib/libraries/supabase/supabase_wrapper.dart`
- `write-tests` skill — Wrapper tests with fake SDK clients


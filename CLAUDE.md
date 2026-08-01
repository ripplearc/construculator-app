# CLAUDE.md

Construculator — a Flutter app for construction cost estimation. Talks to a Supabase/PowerSync backend (`construculator-backend`) and shares UI via the `ripplearc_coreui` package.

This file is behavioral guidance for agents. It is **not** architecture documentation — keep it lean. Detailed design lives in code and the wiki.

## Commands

Environments are selected with `--dart-define=ENVIRONMENT=<dev|qa|prod>` (defaults to `dev`).

- Run: `fvm flutter run --dart-define=ENVIRONMENT=dev`
- Test: `fvm flutter test`
- Analyze + custom lints: `fvm flutter analyze && fvm dart run custom_lint`
- Codegen (freezed / json_serializable): `fvm dart run build_runner build --delete-conflicting-outputs`
- Localizations (after editing `lib/l10n/*.arb`): `fvm flutter gen-l10n`

Run codegen after touching any `@freezed` / `@JsonSerializable` type. Generated files (`*.g.dart`, `*.freezed.dart`, `lib/l10n/generated/**`) are excluded from analysis — never hand-edit them.

CI runs on Codemagic, not in-repo: comment `#RunCheck` on a PR to trigger the pre-check / comprehensive-check / iOS-debug builds (`.github/workflows/run_c_check.yml`).

## Architecture

**Two top-level buckets under `lib/`:**
- `features/` — vertical slices (`auth`, `project`, `estimation`, `dashboard`, `calculations`, `members`, `global_search`). Features must **not** import each other.
- `libraries/` — shared infrastructure (`auth`, `supabase`, `router`, `either`, `errors`, `config`, `time`, `logging`, `shared_widgets`, … — selected examples, see `lib/libraries/` for the full set). Anything reused across features belongs here, not in a feature. Libraries are layered — higher-level libs may depend on lower-level ones, but not the reverse, and no cycles (see "Conventions" below).

**Every feature is Clean Architecture** with the same layout — follow it exactly when adding to a feature:
```
<feature>/
  data/          data_source/ (interfaces + remote impl), repositories/ (impl), models/
  domain/        entities/, repositories/ (interface), usecases/
  presentation/  pages/, widgets/, helpers/, bloc/<action>_bloc/{bloc,event,state}.dart
  <feature>_module.dart
```

**Dependency direction:** `presentation → domain ← data`. Domain defines repository *interfaces* and entities; `data` implements them; `presentation` calls usecases and never reaches into `data`. Direct repo access from blocs is acceptable only when the usecase would be a pure bypass with no domain logic.

**DI & routing — flutter_modular.** Each feature owns a `*_module.dart` extending `Module`:
- `binds(Injector i)` registers data sources, repositories, usecases, and blocs (`addLazySingleton` for services, `add` for blocs).
- `routes(RouteManager r)` wires routes, guarded by `AuthGuard()` where auth is required.
- `imports` pulls in dependency modules. `AppModule` (`lib/app/app_module.dart`) is the composition root; `main.dart` builds `AppBootstrap` (config, envLoader, supabaseWrapper) and threads it top-down.

**Bloc-per-action.** One bloc per user action, not one god-bloc per screen (e.g. estimation has separate `add` / `delete` / `rename` / `change_lock` / `list` blocs). Provide them via `MultiBlocProvider` at the route. Inject dependencies through the constructor — never call `Modular.get` inside a bloc (lint-enforced).

**Error handling.** Cross-layer results return `Either<Failure, T>` (custom impl in `libraries/either`), never thrown exceptions. Failures are typed (`libraries/errors/failures.dart`) with per-domain error enums (e.g. `EstimationErrorType`). Use `.fold(...)` to handle both sides.

**Offline sync.** Queries use PowerSync watches (reactive, offline-capable); mutations go via Supabase directly — see `libraries/supabase` for the wrapper. Data sources must not assume live network availability.

## Hard rules (enforced by `ripplearc_linter` — don't fight them)

- **No direct instantiation** of injectable types — wire dependencies through the module's `binds()` and constructor-inject. Never call `Modular.get` inside blocs or usecases.
- **No forced unwrapping** (`!`) and **no generic exceptions** — use typed failures; prefer `sealed` over `dynamic`.
- **No `DateTime.now()`** — inject and use `Clock` (`libraries/time`).
- **Theming:** never use static colors or typography — pull from the coreui theme.
- **Tests:** prefer Fakes over Mocks; document fake parameters; no test timeouts; single quotes. Mutation testing is in use (`mutation_test`). Tests mirror `lib/` under `test/features/<feature>/`; shared fakes live in `test/fakes/`.
- **Docs:** document public interfaces; do **not** document private/internal methods.
- **TODOs** must link a YouTrack story, e.g. `// TODO: https://ripplearc.youtrack.cloud/issue/CA-119/...`.

## Conventions (follow these; lint enforcement is staged but currently OFF)

These rules exist in `ripplearc_linter` but are disabled in `analysis_options.yaml` pending cleanup — the linter won't catch violations yet, so apply them by hand:

- **Feature isolation** — features must not import each other; route through `libraries/` instead (CA-642). For libraries: no cycles, and direction must flow foundation → infrastructure → domain libs — never upward.
- **No `Modular.get` outside a module** — constructor-inject into blocs/usecases instead (CA-627).
- **Document enums** (CA-641).
- **coreui icon set only** — no raw `IconData` outside coreui (CA-633).

## Logging

Use `AppLogger().tag('<ClassName>')` with `.debug` / `.error`; Sentry is wired for release.

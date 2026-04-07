# CI Scripts and Workflows

This page explains how our local validation script (`scripts/run_check.sh`) and Codemagic workflows (`codemagic.yaml`) work together.

## Purpose

- Keep pull requests healthy by running analysis, linter, tests, coverage checks, mutation checks, and builds.
- Align local checks with CI behavior to reduce surprises during review.

## At a Glance

- Local validation entrypoint: `scripts/run_check.sh`
- CI orchestration: `codemagic.yaml`
- CI trigger from PR comments: `#runcheck` (case-insensitive)
- Toolchain manager: `fvm`
- Primary quality gates:
   - Static analysis
   - Custom lint (`ripplearc_linter`)
   - Unit/widget tests
   - Coverage threshold enforcement
   - Mutation testing
   - Platform builds (Android and iOS where applicable)

## Local Script: `scripts/run_check.sh`

### Why use this script before creating a PR?

Running the script locally helps catch:

- Rebase conflicts with the target branch.
- Analysis and custom lint failures.
- Coverage regressions.
- Test placement issues (tests not discovered by configured paths).
- Build issues that would fail CI.

After pushing, run `--pre` first to quickly check changed files, then run `--all` or `--comp` for full validation before creating PR.

### Supported modes

```bash
./scripts/run_check.sh --pre
./scripts/run_check.sh --comp
./scripts/run_check.sh --all
./scripts/run_check.sh --mutations
./scripts/run_check.sh --all --target main
```

- `--pre`: Fast PR-oriented checks on changed files/tests.
- `--comp`: Full repository checks (analysis, broader tests, builds).
- `--all`: Runs both pre-check and comprehensive check.
- `--mutations`: Runs mutation tests only.
- `--target BRANCH`: Compares and rebases against target branch (default: `main`).

### Typical command choices

- After pushing (quick check on changed files):

```bash
./scripts/run_check.sh --pre --target main
```

- After `--pre` passes, run full validation (use Docker for golden tests):

```bash
./scripts/run_check.sh --all --target main
```

- Mutation-only iteration:

```bash
./scripts/run_check.sh --mutations --target main
```

### What the script does

1. Verifies required tools (`git`, `flutter`, `dart`, and `lcov` when needed).
2. Validates branch and dependency state before quality gates.
3. Runs `fvm flutter pub get`.
4. Rebases against `origin/<target>` to detect conflicts early.
5. Runs analysis:
   - Pre-check: changed Dart files only.
   - Comprehensive: full project (`.`).
6. Runs custom lint rules via `ripplearc_linter` (non-generated changed files).
7. Runs relevant tests and enforces coverage threshold.
8. Runs mutation tests when mutation config XML files changed (or explicitly requested).
9. Builds Android APK; builds iOS debug (macOS only).

### Execution flow (simplified)

1. Parse mode flags (`--pre`, `--comp`, `--all`, `--mutations`).
2. Resolve target branch (`TARGET_BRANCH`, default `main`).
3. Validate local dependencies.
4. Run selected check function(s):
   - `pre_check`
   - `comprehensive_check`
   - `run_mutation_tests`
5. Exit non-zero on first critical failure.

### Rebase check behavior

The script rebases onto `origin/<target_branch>` before analysis to detect conflicts early.

- On conflict: it prints conflicted files (when possible), aborts rebase, and exits with failure.
- On success: proceeds with analysis/test/build gates.

### Custom lint scope

Custom lint runs only on changed Dart files in `lib` and `test`, excluding generated files:

- `lib/generated/`
- `*.g.dart`
- `*.freezed.dart`
- `lib/l10n/generated/`

This keeps pre-checks faster while preserving quality on authored code.

### Coverage behavior

- Default target comes from `ARC_CODE_COVERAGE_TARGET` (script default: `95`).
- Coverage is calculated from `coverage/lcov.info` after filtering generated/localization files.
- Script fails when coverage is below target.

### Mutation testing behavior

- Mutation mode is triggered by running the script with the `--mutations` flag.
- The script looks for changed XML config files under:
   - `test/features/**/mutations/*.xml`
   - `test/libraries/**/mutations/*.xml`
- If no mutation config changed, mutation run is skipped with a success exit.
- If configs changed, the script runs:

```bash
dart run mutation_test <changed-configs> --no-builtin
```

### Build behavior

- Android:
   - Detects product flavors from `android/app/build.gradle`.
   - **TODO (CA-620)**: The script currently uses `--flavor fishfood` even when flavors are absent, which is incorrect. This should be fixed to omit the `--flavor` flag when no product flavors are configured.
   - Current behavior (needs fix):
     - When flavors are present: builds with `--debug --flavor fishfood`, expects `app-fishfood-debug.apk`.
     - When flavors are absent: builds with `--flavor fishfood` (incorrect), expects `app-debug.apk`.
   - Verifies expected APK output path based on flavor configuration.
- iOS (Darwin only):
   - Pre-caches iOS artifacts.
   - Runs CocoaPods install (`ios/pod install`).
   - Builds debug app with no code signing.

## Codemagic Workflows (`codemagic.yaml`)

### How Codemagic is triggered

Codemagic is triggered from GitHub by commenting `#runcheck` on a pull request.

- Trigger source: `.github/workflows/run_c_check.yml` (`issue_comment` event).
- Required marker: `#runcheck` in the PR comment body (case-insensitive).
- Examples that work: `#runcheck`, `#RunCheck`, `#RUNCHECK`.

When triggered, the workflow starts these Codemagic pipelines for the PR source branch:

- `pre-check`
- `comprehensive-check`
- `ios-debug-build`

**Important**: The script uses `set -euo pipefail`, which means it exits immediately on the first command failure. If `pre-check` fails, `comprehensive-check` will not run. Each step must pass before proceeding to the next.

### How local and CI responsibilities split

**Important**: Codemagic runs are expensive. Always validate locally after pushing before creating a PR.

- Local script: fast, low-cost feedback. After pushing: run `--pre` on changed files, then `--all`/`--comp` for full validation.
- Codemagic: branch/PR enforcement and artifact production. Only triggered after local validation passes.

This approach saves CI resources and provides faster iteration cycles for developers.

### `pre-check` workflow (Linux)

**Use locally via `./scripts/run_check.sh --pre --target main`** after pushing to quickly verify your changed files.

CI mirrors this quick check:

- Installs FVM and project Flutter SDK.
- Runs code analysis on changed files.
- Runs changed unit/widget tests with coverage threshold validation.
- Publishes test report: `test-results/flutter.json`.

If this passes, proceed to full validation with `--all` or `--comp`.

### `comprehensive-check` workflow (Linux)

**Run locally via `./scripts/run_check.sh --all --target main`** after `--pre` passes, before creating a PR.

---

## ⚠️ CRITICAL: Always Use Docker for Comprehensive Checks ⚠️

**You MUST run comprehensive checks inside the Docker container.** Do not run `--all` or `--comp` modes directly on your host machine.

**Why?** Golden/screenshot tests depend on exact font rendering and UI consistency. Running outside Docker will generate mismatched golden files that fail in CI (if commited to your pr), wasting time and CI resources.

**How to run:**

```bash
# Start a shell session in the running Docker container
docker exec -it construculator-app-flutter-1 bash

# Then run the comprehensive check
./scripts/run_check.sh --comp
```

**Never skip this step.** If you run comprehensive checks outside Docker, CI will fail with golden test mismatches.

---

CI mirrors this full validation:

- Runs full code analysis across the entire project.
- Runs all unit/widget tests with comprehensive coverage validation.
- Runs screenshot (golden) tests (if present).
- Runs mutation tests when mutation XML files changed from base.
- Builds Android debug APK (`--flavor fishfood`) to verify no build regressions.
- Exports APK, coverage, test report, and mutation report artifacts.

This is the heaviest local check and also the most expensive CI run. Always pass it locally before creating PR, especially for high-impact or release-sensitive changes.

### `periodic-check` workflow (Linux scheduled/base branch checks)

Runs on a schedule against the base branch for ongoing health monitoring:

- Runs full analysis, all tests, screenshots, mutation tests, and Android build.
- Uses discovery of mutation config files and runs all found configs.
- Detects quality drift that may not surface in narrow PR scopes.


### `ios-debug-build` workflow (macOS)

**Run locally via `./scripts/run_check.sh --all --target main`** (iOS build is included in `--all` mode) after pushing and passing `--pre`, before creating a PR.

CI validates iOS builds separately:

- Installs iOS dependencies (`pod install`).
- Pre-caches iOS artifacts and builds iOS debug app with `--no-codesign`.
- Exports iOS debug artifact (`.app`).

MacOS developers should always verify iOS builds pass locally before creating PR changes.

## Environment and Configuration

### Toolchain

- Flutter: `3.32.0` (via Codemagic environment + FVM).
- FVM is the standard entrypoint for local and CI commands.

### Required tools (local)

- `git`
- `flutter`
- `dart`
- `lcov` (required for coverage-producing modes)
- `bc` (used for coverage arithmetic in script logic)

If any required tool is missing, the script fails fast.

### Common environment variables

- `ARC_CODE_COVERAGE_TARGET`: standard required coverage.
- `CODE_COVERAGE_MINIMUM`: fallback target used in specific commit-message scenarios (`#DeltaCoverageLow` or `DCL` in CI).
- `TARGET_BRANCH`: local script compare/rebase target (default `main`).
- `BASE_BRANCH`, `CM_PULL_REQUEST_DEST`, `CM_COMMIT`, `CM_REPO_URL`: CI branch/commit context.
- `FORCE_FAIL`: optional CI hard fail switch in selected workflows.

### Variable precedence notes

- Local `run_check.sh` uses shell environment values when provided.
- If not set, script-level defaults apply (for example `TARGET_BRANCH=main`).
- CI values are injected by Codemagic runtime and workflow groups.

### Caching

Codemagic caches key paths to speed builds:

- `.fvm/`
- Pub cache(s)
- Gradle cache
- `ios/Pods` (where applicable)

Caching improves run time but can hide stale-state problems. If behavior looks inconsistent:

**Local cache management:**
- Clear Flutter pub cache: `fvm flutter pub cache repair`
- Clean project build artifacts: `fvm flutter clean`
- Clear Gradle cache (Android): `rm -rf ~/.gradle/caches`
- Clean pods (iOS): `cd ios && rm -rf Pods Podfile.lock && pod install && cd ..`

**CI cache management:**
- Codemagic caches are managed automatically per workflow run
- Caches persist between builds to speed up dependency installation
- If CI shows stale behavior, you can trigger a clean build by clearing the cache through Codemagic UI or asking a team admin

Always verify Flutter version alignment through FVM (`fvm flutter --version`) to ensure local and CI environments match.

## Platform Considerations

- Local script iOS build runs only on macOS (`uname == Darwin`).
- Linux workflows use package managers like `apt-get` (and in one workflow `brew`) for `lcov` installation.
- iOS build/pod steps require macOS runners (`ios-debug-build`).
- Android build targets `fishfood` flavor in both local comprehensive checks and CI.
- **Golden/screenshot tests**: Run comprehensive checks inside Docker container to ensure golden files match CI environment exactly. Font rendering and UI differences between host systems can cause false mismatches.

## Test Discovery Paths (Important)

These paths are assumed by script and workflow logic. Tests outside these patterns may not run:

- `test/features/**/units/*.dart`
- `test/features/**/widgets/*.dart`
- `test/features/**/screenshots/*.dart`
- `test/features/**/mutations/*.xml`
- `test/libraries/**/units/*.dart`
- `test/libraries/**/mutations/*.xml`

When adding new test suites, keep naming and placement consistent with existing conventions.

## Failure Modes and Troubleshooting

### 1) Rebase conflict during checks

Symptoms:

- Script fails after rebase step.
- Conflict file list is printed.

Actions:

1. Rebase manually onto target branch.
2. Resolve conflicts and run local tests for touched areas.
3. Re-run `./scripts/run_check.sh --pre  `.

### 2) Coverage below threshold

Symptoms:

- Coverage percent printed below `ARC_CODE_COVERAGE_TARGET`.

Actions:

1. Add/expand unit or widget tests for changed logic paths.
2. Confirm test files are under supported discovery paths.
3. Re-run coverage-producing command.

### 3) Missing coverage file

Symptoms:

- `coverage/lcov.info` missing or empty.

Actions:

1. Ensure tests actually executed.
2. Check for early test aborts.
3. Re-run with clean state and verify `fvm flutter test ... --coverage` output.

### 4) iOS build fails locally

Symptoms:

- Pod resolution/build failure on macOS.

Actions:

1. Run `fvm flutter precache --ios`.
2. Run `cd ios && pod install && cd ..`.
3. Re-run iOS debug build command.

### 5) Mutation tests unexpectedly skipped

Symptoms:

- Mutation step reports no changed mutation configs.

Actions:

1. Confirm XML files are under supported mutation directories.
2. Ensure branch diff includes those files.
3. Use explicit `--mutations` mode if validating mutation scope intentionally.

## Practical Guidance for Team Members

### Cost-Aware Development

Each CI run is expensive. Respect that cost by validating locally after pushing.

**Step 1: After pushing (quick check on changed files)**:

```bash
# Fast check on your changes only
./scripts/run_check.sh --pre --target main
```

**Step 2: If `--pre` passes, run full validation**:

```bash
# Full codebase validation (use Docker for golden test consistency)
docker exec -it construculator-app-flutter-1 bash
./scripts/run_check.sh --all --target main
```

**Step 3: After both pass, create PR**

- If `--all` or `--comp` passes locally, the CI run should also pass.
- Only create PR after full validation passes locally.

**If CI still fails after local success**:

- It likely means either a timing issue, a stale cache, or an environment difference.
- Verify file placement matches supported test paths.
- If the failure is reproducible locally, debug and fix locally.
- If failure appears CI-specific, report it and run a retry:

# E2E CI/CD

How the CUJ E2E suite runs in CI: schedule, on-demand trigger, results and
artifacts, retry/quarantine behaviour, the triage owner, and the pattern for
adding a new CUJ. The workflow is `.github/workflows/e2e_cuj.yml`; the
environment it stands up is documented in [E2E-Environment.md](E2E-Environment.md).

## Triggers

| Trigger | When |
|---|---|
| Schedule | Every Monday 03:00 UTC, against `main`. Weekly rather than nightly while the suite is new — see [CA-750](https://ripplearc.youtrack.cloud/issue/CA-750) for the cost/regression-range tradeoff behind that choice. |
| `#RunE2E` PR comment | Mirrors the `#RunCheck` pattern in `.github/workflows/run_c_check.yml`. Runs the suite against the commenting PR's head branch. |
| `workflow_dispatch` | Manual run, e.g. while triaging a red run or testing a backend branch via its `backend-ref` input. |

## Platform

GitHub Actions, `ubuntu-latest`, Android only — settled in CA-975 (see CA-750's
ticket history) over Codemagic (no Docker daemon on its macOS runners) and over
Firebase Test Lab (the backend stack and the app both need to be on the same
`localhost` for the Mailpit OTP capture CUJ-2 depends on).

> **TODO [CA-980](https://ripplearc.youtrack.cloud/issue/CA-980):** iOS
> functional coverage in CI is out of scope here; revisit by 2026-11-18.

The suite runs on an emulator booted on the runner itself via
[`reactivecircus/android-emulator-runner`](https://github.com/ReactiveCircus/android-emulator-runner).
Patrol's own docs warn that GitHub-hosted emulators are slower and less stable
than a device farm — that tradeoff was accepted explicitly in CA-975 in
exchange for keeping the backend and the app on the same runner. The retry
policy below exists largely to absorb it.

## What the workflow does

1. Checks out the app (the PR's head branch for `#RunE2E`, else the triggering ref).
2. Installs Flutter (pinned to `.fvmrc`'s `3.44.4`) and the Patrol CLI.
3. Starts the E2E backend via `.github/actions/e2e-env` (full `supabase start`
   plus PowerSync — the same stack `scripts/e2e/start_env.sh` starts locally).
4. Writes `assets/env/.env.dev` from the running stack via
   `scripts/e2e/generate_e2e_env.sh`, so the `fishfood`-flavored APK Patrol
   builds is already pointed at it.
5. Boots an Android emulator, forwards the stack's ports into it
   (`scripts/e2e/adb_reverse.sh`), and runs
   `patrol test --target integration_test/patrol_test.dart --flavor fishfood`.
6. Snapshots each attempt's JUnit XML into `build/e2e-attempts/attempt-<n>/`,
   reduces the set to one `e2e-run.json` via
   `scripts/e2e/build_e2e_report.dart`, publishes a pass/fail summary to the job
   summary, and uploads both — always, not only on failure, so a green run's
   numbers are visible too.
7. On failure, also uploads a screen recording, a final-state screenshot and
   the device log (`adb logcat`) captured during the run.

## Results and notifications

JUnit XML and (on failure) screenshots/video/logcat are uploaded as workflow
artifacts (30-day retention) and summarized in the run's job summary — both
visible from the Actions tab without re-running anything.

Codemagic's existing workflows notify `#build-notifications` in Slack, but that
integration is Codemagic's own and isn't reachable from GitHub Actions without
a webhook secret this repo doesn't currently have configured for GH Actions.
Wiring this workflow into the same Slack channel needs a `SLACK_WEBHOOK_URL` (or
equivalent) secret provisioned first — flagged for a decision rather than
guessed at here. Until then, a red scheduled run is visible via GitHub's
default behaviour of emailing the workflow's watchers on a failed scheduled
run, and via the Actions tab itself.

## Retry

The `patrol test` invocation gets one automatic retry (two attempts total)
inside the same job run, before the job is reported red. This targets
emulator/device-level flake (a slow boot, a dropped ADB connection) — the
category Patrol's own docs warn about for GitHub-hosted emulators — not
app-logic flake. A CUJ that still fails on the second attempt is a real
failure and should be investigated, not re-run again by hand as a first
response.

### Attempts are the flake signal

Gradle rewrites `build/app/outputs/androidTest-results/connected` on every
`patrol test` invocation, so before this the first attempt's XML was gone the
moment the retry started — a retried-and-passed run was indistinguishable from
a clean one. Each attempt is now snapshotted to
`build/e2e-attempts/attempt-<n>/` before the next one starts.

`build_e2e_report.dart` reads every snapshot and classifies each case by its
last attempt:

| Status | Meaning |
|---|---|
| `passed` | green on every attempt it ran in |
| `flaked` | green on the last attempt, red on an earlier one |
| `failed` | red on the last attempt |
| `skipped` | never ran; excluded from both rates |

`pass_rate` counts `flaked` cases as passes, because that is what CI reports
when a retry rescues a run. `flake_rate` is what that number hides, which is
why the trend dashboard plots both.

## Quarantine

With one CUJ today, quarantine is a manual, documented step rather than
tooling: comment out the failing CUJ's line in `integration_test/patrol_test.dart`
with `// QUARANTINED: <reason> — <ticket>`, so it stops blocking the weekly
run and `#RunE2E` while a ticket tracks the fix. Restore it by uncommenting
once the fix lands. If the suite grows enough that several CUJs need
quarantining at once, revisit this for something more structured (e.g. a
skip-list read by `patrol_test.dart`) — not needed yet.

## Owner

**Judgment call, needs confirmation:** naming CA-750's assignee (`ayanasamuel`)
as the owner who triages a red run, since there is no dedicated E2E/CI owner
recorded elsewhere and no CODEOWNERS entry more specific than
`@ripplearc/construculator-devop` for `.github/workflows/**`. Confirm this is
the right call, or name someone else.

## Adding a new CUJ

1. Write the test under `integration_test/features/<domain>/cuj_N_<name>_test.dart`,
   following the [selector convention](E2E-CUJ-Strategy.md#selector-convention)
   (stable `Key`s, no positional or raw-text finders).
2. Import it in `integration_test/patrol_test.dart` and call its `main()` from
   the aggregator's `main()` — that one file is the whole suite; nothing in
   the workflow needs to change for a new CUJ to run weekly and under
   `#RunE2E`.
3. If the CUJ needs seed data, add it to `construculator-backend`'s seeders
   (see [E2E-Environment.md](E2E-Environment.md#seeded-account)) rather than
   creating it at test time, so a fresh CI stack already has what the CUJ
   needs.

## Known risk: runner resource pressure

`ubuntu-latest` GitHub-hosted runners are 2 cores / 7GB RAM. This job runs a
full Docker Compose Supabase+PowerSync stack and a hardware-accelerated Android
emulator on the same runner concurrently — real resource pressure that this
first cut hasn't been run under yet. If runs are unstable for reasons the retry
doesn't absorb, a larger hosted runner is the likely fix; revisit once the
suite has run for real.

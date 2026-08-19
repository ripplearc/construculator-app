# Performance Harness (Weekly Lab Measurement)

How the weekly performance run is produced: what it measures, how to run it, and
what each artifact means.

This page covers the **lab harness** — a controlled, repeatable measurement on
dedicated hardware that produces the trend. It is not field telemetry from real
users, which is a separate mechanism with different tradeoffs.

For the definitions of the metrics themselves and why they are measured the way
they are, see [Performance Measurement](Performance-Measurement). This page
assumes those definitions and describes the machinery.

## At a Glance

- Workflow: `.github/workflows/weekly_system_health.yml`
- Capture: `scripts/perf/capture_perf_run.sh` (raw artifacts)
- Report: `scripts/perf/build_perf_report.dart` (`perf-run.json`)
- Publish: `scripts/perf/publish_perf_run.sh` (trend store)
- Journey: `integration_test/perf/pre_login_journey_test.dart`
- Trend store: the orphan `perf-data` branch
- Runner: `[self-hosted, perf-lab, android]`
- Platform: **Android only** for now

## What Is Measured

| Metric | Source | Reported as |
|---|---|---|
| Cold start | `start_up_info.json` per iteration | median |
| Warm start | `start_up_info.json` per iteration | median |
| Jank | flutter_driver timeline summary | p90 |
| Memory | DevTools memory profile | peak RSS |

Startup uses `timeToFirstFrameRasterizedMicros` rather than the frame *build*
timestamp, because rasterization is the point at which a frame actually reaches
the screen.

Startup is reported as a **median**, not a mean, so that one scheduling stall on
the device cannot drag the headline number. Jank is reported at **p90**, because
the interesting part of frame timing is the tail, not the average frame.

`--purge-persistent-cache` is what separates a cold start from a warm one. The
first launch after an install is captured and thrown away, because its one-off
costs (dex optimisation, first shader warm-up) never recur and would otherwise
skew the first run of every series.

> **Impeller note:** `--cache-sksl` and `--bundle-sksl-path` no longer exist.
> SkSL shader warm-up was a Skia mechanism; under Impeller there is no
> equivalent flag to pre-seed, so no shader priming step is possible here.

## Running It

### Scheduled

Runs automatically every Monday at 03:00 UTC against the default branch.

### On demand

Dispatch **Weekly System Health** from the Actions tab. Both inputs are
optional:

- `device_id` — overrides the `PERF_DEVICE_ID` repository variable
- `iterations` — startup iterations per phase (default `5`)

### From a pull request

Comment `#RunPerf` on the PR. This measures the PR's head branch and uploads the
artifact, but **does not** record a trend point — only default-branch runs enter
the history, so unmerged code cannot distort the baselines.

### Locally

Requires an attached Android device and `fvm`:

```bash
ENVIRONMENT=perf bash scripts/ci/generate_env_file.sh

bash scripts/perf/capture_perf_run.sh \
  --device-id <device-id> \
  --output-dir build/perf/local

fvm dart run scripts/perf/build_perf_report.dart \
  --input build/perf/local \
  --output build/perf/local/perf-run.json
```

`publish_perf_run.sh` does not push unless given `--push`, so it is safe to run
locally to inspect what would be recorded.

## Why a Self-Hosted Runner

Startup tracing needs a **host VM-service connection** to the device, and
`--profile-memory` shells out to **host-side DevTools**. A hosted device farm
gives no host attachment to the device, so neither measurement can be taken
there — this is a structural limitation, not a cost decision.

The execution-target evaluation behind this is recorded in
[E2E Execution Target](E2E-Execution-Target).

## The `perf` Environment

`scripts/ci/generate_env_file.sh` has a `perf` case that disables analytics,
Sentry and PostHog debug, so telemetry neither perturbs the measurements nor
publishes lab runs as though they were field data.

It writes `assets/env/.env.dev`, because `AppConfigImpl` resolves
`Environment.dev` to that file and the `Environment` enum has no `perf` member.
The harness therefore builds with `--dart-define=ENVIRONMENT=dev` and relies on
this case having already stripped the telemetry out of the file the app loads.

## Artifacts

A capture directory contains raw artifacts only:

```
meta.json                          run provenance
cold/run-<n>/start_up_info.json    one per cold iteration
warm/run-<n>/start_up_info.json    one per warm iteration
jank/<journey>.timeline_summary.json
memory/memory_profile.json
```

`build_perf_report.dart` reduces these to a single `perf-run.json`
(`schema_version: 1`).

Memory reports `available: false` rather than a number when the DevTools profile
shape is not recognised. That artifact's schema is owned by DevTools, not by
this repository, so an unrecognised shape must not become a fabricated data
point in the trend.

## The Trend Store

Runs are appended to the orphan **`perf-data`** branch, one file per run:

```
runs/<journey>/<captured-at>-<commit>.json
index.json
```

`perf-data` shares no history with `main`, so the store grows without adding
commits or files to the source tree. `index.json` is always **rebuilt** from the
stored runs rather than appended to, so a partially written index repairs itself
on the next publish, and re-publishing a run overwrites it rather than
double-counting a retried job.

### The `journey` field

Every record carries a `journey` (currently `pre_login_v1`). Runs are also
partitioned by journey on disk.

This matters because a performance number is only meaningful relative to the
work being measured. If the measured journey changes, comparing new runs against
old ones is meaningless. Publishing under a new journey id starts a **new
series** instead of silently corrupting the existing one.

## Known Gaps

### Device models are not yet recorded

The lab hardware is not yet fixed, so the harness parameterizes on device id and
records `device.model` as `null`. Nothing is hardcoded, and no baselines are
recorded here yet — a baseline is only meaningful once it is attached to a known
device. See [Performance Device Register](Performance-Device-Register).

### Android only

Only Android is measured. iOS is a deliberate follow-on: it needs a macOS
perf-lab runner and a separate device register, and none of the capture or
reporting logic assumes Android beyond the build and device flags.

### Pre-login baseline only

The measured journey stops at the login screen, so it excludes everything behind
authentication — sync, project loading and the dashboard.

**TODO [CA-981](https://ripplearc.youtrack.cloud/issue/CA-981):** measure a
primed, post-login session. That work changes production `lib/` code and is
tracked separately; this harness ships the pre-login baseline first and is not
blocked by it. When it lands, it must publish under a new journey id.

### The scripted scroll may not always scroll

The journey flings the login form's scroll view to generate frames. On a tall
enough screen the form fits without overflowing, so the gesture produces frames
without producing scrolling. Jank numbers are therefore comparable across runs
**on the same device**, but not necessarily across devices of different sizes.

## Troubleshooting

### `Device '<id>' is not attached`

The capture script checks the device against `flutter devices --machine` before
building. Confirm the device is attached and unlocked, and that `PERF_DEVICE_ID`
matches its id exactly.

### No `start_up_info.json` produced

Startup tracing is only downloaded by `flutter run --trace-startup`.
`flutter drive --trace-startup` does **not** produce this file. The capture
script uses `flutter run` for startup for exactly this reason; a run that
produces no startup data usually means that step was replaced or the device
disconnected before the first frame.

### The run produced no trend point

Only default-branch runs publish. A `#RunPerf` run on a PR uploads its artifact
but does not record history — this is intended.

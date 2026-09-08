# Performance Measurement

This page is the canonical reference for how Construculator measures rendering and system-health performance.

It defines **what** each metric means, **where** its boundaries are, and **how** to measure it reproducibly. It does not hold baseline numbers — see [Baselines](#baselines) for why, and who supplies them.

Verified against the toolchain pinned in `.fvmrc`: **Flutter 3.44.4**, **Dart 3.12.2**, **DevTools 2.57.0**.

---

## Scope: Lab Measurement vs Field Telemetry

Two separate paths produce performance data. They answer different questions and must not be conflated — a number from one is not comparable to a number from the other.

| | **Lab measurement** | **Field telemetry** |
|---|---|---|
| Owning ticket | CA-782 | CA-566 |
| Tooling | Flutter native tracing, profile mode | Sentry auto-instrumentation |
| Population | One device class, scripted journey | Real users, real devices, sampled |
| Determinism | Reproducible run to run | Non-deterministic by design |
| Cadence | Weekly, on CI | Continuous |
| Answers | "Did this change regress a controlled measurement?" | "What do users actually experience?" |
| Can gate CI | Yes | No |

**This page owns definitions and method for both paths.** It does not own baseline numbers. A baseline cannot exist before a harness exists to produce it, and a figure measured by hand on a developer machine will not transfer to a CI device — different hardware, different thermal state, different build.

Metric-to-source mapping. Startup appears as a single series measured under two conditions rather than as separate "cold start" and "TTID" metrics — see [Startup Metrics at a Glance](#startup-metrics-at-a-glance) for why they are one measurement:

| Metric | Lab (CA-782) | Field (CA-566) |
|---|---|---|
| TTID — cold condition | Primary source | Corroborating: `ui.load` transaction, `app_start_cold` measurement |
| TTID — warm condition | Primary source | Corroborating: `ui.load` transaction, `app_start_warm` measurement |
| TTFD | No lab marker — see [TTFD](#ttfd-time-to-full-display) | Primary source, once enabled — `ui.load.full_display` span |
| Memory | Primary source | Not collected |
| Jank (slow/frozen frames) | Primary source | Corroborating (slow/frozen frame counts) |

**Lab and field startup numbers are not directly comparable.** The lab measurement is anchored on engine entry (`FlutterEngineMainEnter`), while Sentry's app-start measurement begins earlier, at process start, and so includes pre-engine platform work. Expect the field series to read systematically higher than the lab series for the same build. Trend each against its own baseline; never treat a difference between the two as a regression.

Field telemetry is currently inactive: `tracesSampleRate` is `0.0` in `lib/libraries/sentry/sentry_wrapper_impl.dart`. See [Sentry](Sentry).

---

## Manual Profiling with DevTools

Use this for investigating a specific regression or reviewing a UI-heavy PR. It produces evidence for a reviewer, never a CI baseline.

### 1. Run in profile mode

```bash
fvm flutter run --profile --flavor fishfood --dart-define=ENVIRONMENT=dev
```

**Rules:**

- **Always `--profile`, never `--debug`.** Debug builds run unoptimized JIT code with assertions enabled. Frame times from a debug build are meaningless — they are routinely several times worse than release and vary independently of the code under test.
- **Always a physical device.** Emulators and simulators share the host CPU and GPU, and their startup and frame numbers are too noisy to compare across runs.
- **Profile mode disables hot reload.** Restart the process to pick up changes.

### 2. Connect DevTools

`flutter run` prints two URIs on startup:

```
A Dart VM Service on <device> is available at: http://127.0.0.1:<port>/<token>/
The Flutter DevTools debugger and profiler on <device> is available at: http://127.0.0.1:<port>/...
```

Open the second URI to attach directly. To attach a standalone instance to an already-running app, launch DevTools and paste the **Dart VM Service** URI (the first one) into its connect field:

```bash
fvm dart devtools
```

### 3. Performance tab

The **Flutter frames** chart plots one bar per frame, split into two segments:

- **UI time** — the Dart thread: building, laying out, and painting the widget tree. Regressions here are usually your code.
- **Raster time** — the raster thread: turning the layer tree into GPU commands. Regressions here are usually expensive clips, opacity layers, shadows, or oversized images.

Bars exceeding the frame budget are highlighted as jank. Selecting one opens its detail in the tabs below:

- **Frame Analysis** — breaks the selected frame into its costliest operations and flags common causes (expensive rebuilds, costly effects like `Opacity` or `saveLayer`).
- **Rebuild Stats** — widget rebuild counts per frame, attributed to source location. This is the tab that answers "what is rebuilding too often". Requires *Trace widget builds* (below).
- **Timeline Events** — the raw event tree for the frame.

Under **Enhance Tracing**, enable **Trace widget builds** to populate Rebuild Stats. Enable it only while you need it: the instrumentation itself costs time and inflates the very frame times you are measuring. Never read absolute frame times from a run with enhanced tracing on — use it to find *what* rebuilds, then re-measure with it off.

**Performance Overlay** toggles the on-device graphs, useful for a quick check without reading the chart.

### 4. CPU Profiler tab

The sampling profiler, for attributing UI-thread time to functions:

- **Bottom Up** — start here. Ranks leaf functions by self time; the fastest route to "what is actually burning CPU".
- **Call Tree** — top-down, for understanding how an expensive leaf is reached.
- **Method Table** — flat list with self and total time per method.

For startup work specifically, use the **app start up** profile, which covers the window before the first frame. Populate it by running with:

```bash
fvm flutter run --profile --cache-startup-profile
```

### 5. Memory tab

- **Chart** — live Dart heap and RSS over time. Use it to spot growth trends across a journey.
- **Profile** — allocation breakdown by class at a point in time.
- **Diff** — snapshot comparison; the tool for finding leaks. Snapshot, run the journey, return to the start state, snapshot again, diff. Objects that should have been released show up as retained.

### 6. Recording results for PR comparison

Three export routes, in increasing order of fidelity:

**a. DevTools snapshot.** The Performance and CPU Profiler tabs both have **Export**, which writes a snapshot file. To reload one, use **Open a file** on the DevTools landing page, or drag and drop the file onto it — there is no Import control on the Performance or CPU Profiler tabs themselves. Attach the file to the PR when a reviewer needs to inspect the same trace.

**b. Startup trace.**

```bash
fvm flutter run --profile --trace-startup --purge-persistent-cache
```

Writes two files under `build/`:

- `start_up_info.json` — the computed metrics (see [Cold Start](#cold-start) for the keys).
- `start_up_timeline.json` — the full timeline the metrics were derived from.

**c. Full Perfetto trace.**

```bash
fvm flutter run --profile --trace-to-file=build/trace.binpb
```

Writes a Perfetto protobuf loadable in the Perfetto trace viewer. For long captures, add `--endless-trace-buffer` so the ring buffer does not discard early events.

**A manual comparison is only valid if every one of these is held constant** between the two runs:

- The same physical device, at similar battery and thermal state
- The same build mode and flavor
- The same journey, performed identically
- Enhanced tracing off in both

State these conditions in the PR alongside the numbers. A figure without them is not evidence.

---

## Metric Definitions

Each definition below fixes a start boundary, an end boundary, and a capture method, so that two people measuring independently arrive at comparable numbers.

The timeline event names quoted here are emitted by the Flutter engine and framework — `FlutterEngineMainEnter` by the engine, the first-frame events by the framework — and are stable in the pinned SDK.

### Startup Metrics at a Glance

"Cold start", "TTID" and "warm start" name **one measurement under two conditions**, not three independent metrics. All three resolve to the same event pair and the same JSON key:

| Named metric | Condition | Boundary | Key |
|---|---|---|---|
| Cold start / TTID (cold) | Caches purged | `FlutterEngineMainEnter` → `Rasterized first useful frame` | `timeToFirstFrameRasterizedMicros` |
| Warm start / TTID (warm) | Caches warm | `FlutterEngineMainEnter` → `Rasterized first useful frame` | `timeToFirstFrameRasterizedMicros` |

Each is defined separately below because the ticket set names them separately and because their *conditions* differ in ways that matter. But **they are trended as two series, not four** — "TTID (cold)" and "TTID (warm)". The device matrix, thresholds and baselines below carry those two rows only. Recording "cold start" and "TTID" as separate rows would guarantee two identical numbers and make CI evaluate a single breach twice.

TTFD is a genuinely distinct measurement and is trended separately.

### Cold Start

**Definition:** the interval from engine entry to the first frame that is actually on screen, with no warm caches of any kind.

**Boundary:** `FlutterEngineMainEnter` → `Rasterized first useful frame`.

Note that the boundary starts at **engine entry**, not at process start. Platform work before the engine starts — process spawn, native library loading — is outside this measurement. Sentry's field measurement uses a wider boundary; see [Scope](#scope-lab-measurement-vs-field-telemetry).

**Capture:**

```bash
fvm flutter run --profile --trace-startup --purge-persistent-cache
```

Read `build/start_up_info.json`. Its keys:

| Key | Meaning |
|---|---|
| `engineEnterTimestampMicros` | The zero point — engine entry |
| `timeToFrameworkInitMicros` | Engine entry → framework initialization |
| `timeToFirstFrameMicros` | Engine entry → `Widgets built first useful frame` |
| `timeToFirstFrameRasterizedMicros` | Engine entry → `Rasterized first useful frame` |
| `timeAfterFrameworkInitMicros` | Framework init → first frame built |

**Use `timeToFirstFrameRasterizedMicros` as cold start.** `timeToFirstFrameMicros` measures the frame being *built*, not rasterized — it is retained for continuity with older benchmarks and understates what the user waits for.

**Invalidates the run:**

- Omitting `--purge-persistent-cache` — this is what makes a run genuinely cold. It clears persistent caches so the run reproduces first-launch conditions rather than reusing warmed state.
- A first launch immediately after install, which carries one-time setup cost. Discard it.
- Any background app install, sync, or indexing on the device.

**Note on shaders.** `--purge-persistent-cache` was historically the way to reproduce shader-compilation jank on first run. Under Impeller, shaders are compiled ahead of time and that class of first-run jank is largely pre-empted.

**Impeller is not universal, and this affects Class A.** In Flutter 3.44.4 Impeller is the default renderer on **iOS only**. On Android it is available but not the default: Vulkan-capable hardware gets it, older devices fall back to Skia, where first-run shader-compilation jank is still real. The Class A gating device — mid-tier, 4 GB RAM — is exactly the hardware most likely to fall back.

**Confirm which renderer the Class A device actually uses and record it alongside the baseline.** A jank baseline gathered on a Skia fallback device is not comparable to one gathered on an Impeller device, and silently swapping the handset for one that renders differently will register as a jank regression that no code change caused.

The SkSL warm-up flags (`--cache-sksl`, `--bundle-sksl-path`) **no longer exist** in Flutter 3.44.4; do not look for them. `--purge-persistent-cache` is still required, but on an Impeller device its value is cache hygiene rather than SkSL reproduction.

### TTID (Time to Initial Display)

**Definition:** the interval from engine entry to the first frame rendered to the screen, regardless of whether that frame's content is populated. A skeleton, spinner, or empty scaffold satisfies TTID.

**Boundary:** identical to cold start — `FlutterEngineMainEnter` → `Rasterized first useful frame`.

TTID and cold start are the same measurement taken from the same event pair; "cold start" names the *condition* (caches purged), TTID names the *endpoint*. Warm start is the same endpoint under warm caches.

**Capture:** as cold start; `timeToFirstFrameRasterizedMicros`.

**This is the metric to trend and to gate on.** It is emitted by the engine and framework, requires no application code, and is deterministic under fixed conditions.

### TTFD (Time to Full Display)

**Definition:** the interval from app launch to the first frame on which the screen is genuinely usable — the primary journey's data has loaded and is rendered, with no spinners or placeholders remaining in the primary content area.

**Where it diverges from TTID:** on any screen that renders a shell and then fills it asynchronously. If the dashboard shows a skeleton at 400 ms and its project list at 1,900 ms, TTID is 400 ms and TTFD is 1,900 ms. TTID alone would report that screen as fast while the user waits another 1.5 seconds.

**TTFD needs an application-emitted marker,** because only the application knows when a screen's content is complete. The marker must:

- Fire once per journey, on the first frame where primary content is rendered — not when the data arrives, but when the frame containing it is on screen.
- Be emitted from the screen that owns the journey, since "complete" is screen-specific.
- Be distinguishable per journey, so dashboard TTFD and estimation TTFD are separate series.

**Field path — already available, not yet enabled.** `sentry_flutter` 9.24.0 is a direct dependency and ships exactly this marker:

```dart
final display = SentryFlutter.currentDisplay();
// ...load the screen's primary content...
await display?.reportFullyDisplayed();
```

This closes a `ui.load.full_display` span and satisfies all three requirements above: it is per-route, called from the owning screen, and reported once. It requires `enableTimeToFullDisplayTracing` — `false` by default — plus a non-zero `tracesSampleRate`, so it is inert today. **Wiring it up belongs to CA-566**, alongside the rest of the field telemetry; adding the calls is application code and out of scope for this page.

**Lab path — no marker exists.** The CA-782 harness cannot read a Sentry span: it reads `start_up_info.json` and Perfetto traces, neither of which carries `ui.load.full_display`. Lab TTFD would need a separate timeline event emitted from the same screens. None exists, and none is proposed here.

**Which to trend:** **trend TTID, and gate only on TTID.** It is available now, deterministic, and lab-measurable. TTFD depends on network latency and cache state, so even once CA-566 enables it, treat it as a reported field series and an investigation trigger — never a hard CI gate, which it structurally cannot be given it has no lab source.

### Warm Start

**Definition:** the interval from engine entry to the first frame that is actually on screen, on a launch where persistent caches are already populated from a previous run.

**Boundary:** `FlutterEngineMainEnter` → `Rasterized first useful frame` — identical to cold start. Only the cache state differs.

**Capture:** the same startup trace **without** `--purge-persistent-cache`:

```bash
fvm flutter run --profile --trace-startup
```

`--purge-persistent-cache` is the single flag separating a cold run from a warm one. Everything else about the two commands is identical. A "cold start" number measured without it is a warm start number mislabelled — the most common way this measurement goes wrong.

**This is a warm-cache launch, not a resume from background.** The distinction matters because the prescribed tooling cannot measure the resume variant at all: `flutter run --trace-startup` launches a new process, and every value in `start_up_info.json` is anchored on `engineEnterTimestampMicros`, taken from `FlutterEngineMainEnter`. That event fires when the engine starts. It does not fire when an already-running process returns to the foreground, so a resume has no zero point and produces no startup trace.

Resume-from-background latency is a real and separately interesting measurement, but it needs different instrumentation — an app-side lifecycle marker — and is out of scope here. Do not report it as warm start.

**Invalidates the run:**

- Purging the cache, or running on a fresh install with no previous run to warm the cache. That is a cold start, whatever it is labelled.
- Measuring a resume instead of a launch. See above — this produces no trace, not a wrong number, but the failure is easy to misread as a tooling error.
- Any background app install, sync, or indexing on the device.

### Memory Consumption

**Definition:** memory held by the app at defined checkpoints during a scripted journey.

**What to sample — both, they answer different questions:**

- **Dart heap** — objects allocated by application code. Regressions here point at retained references in your own code.
- **RSS (resident set size)** — total physical memory including engine, textures, and platform allocations. This is what the OS sees and what triggers low-memory kills.

**When to sample:** at **steady state** after each journey step — after navigation settles and animations complete — not at peak. Peak values are dominated by transient allocation spikes and garbage collection timing, and do not trend. Sample at a minimum:

1. Immediately after first frame
2. At the end of each journey step
3. After returning to the start screen, which exposes anything the journey failed to release

**Over which journey:** the same scripted journey used for jank measurement, so a single run produces both. The journey must return to its starting screen so the final sample is meaningful.

**Capture:**

```bash
fvm flutter drive --profile --profile-memory=build/memory.json
```

> **Prerequisite — not runnable today.** `flutter drive` needs a driver target, and the project has no `integration_test/` or `test_driver/` directory and no `integration_test` entry in `pubspec.yaml`. CA-782 adds both. Until then this command has nothing to drive.

**Invalidates the run:** sampling during an animation or a scroll; comparing a peak in one run to a steady state in another; a run whose journey did not complete.

### UI Stutter and Jank

**Definition:** frames that miss the display's refresh budget.

- **Slow frame** — a frame exceeding the device's frame budget, which is `1000 / refresh_rate` ms: **16 ms at 60 Hz**, **~8 ms at 120 Hz**. Visible as stutter.
- **Frozen frame** — a frame exceeding **700 ms**. This threshold is absolute and does not scale with refresh rate: at 700 ms the UI is unresponsive regardless of panel, and users read it as a hang rather than as slowness.

**The slow-frame threshold is refresh-rate-relative, so a slow-frame count is meaningless without the refresh rate it was measured at.** A frame that passes on a 60 Hz device fails on a 120 Hz one, with no code change involved. This is why the [Device Matrix](#device-matrix-and-sample-count) states a refresh rate and a budget per class. Trend slow frames only within a single class, and never compare a count from Class A against one from Class C.

**Attribution.** Split every jank frame by thread, because the fixes are unrelated:

- **UI thread over budget** — expensive `build`, layout thrash, synchronous work on the main isolate. Fix in Dart.
- **Raster thread over budget** — expensive clips, `saveLayer`, opacity layers, oversized images. Fix in the widget tree's rendering characteristics.

**Capture:**

```bash
fvm flutter run --profile --trace-to-file=build/trace.binpb
```

Or, from an integration-driven journey, `watchPerformance`, which reports frame timings for the wrapped action. It is an instance method on the binding, so it must be called on the initialized instance:

```dart
final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

await binding.watchPerformance(() async {
  // drive the journey
}, reportKey: 'performance');
```

> **Prerequisite — not runnable today.** `integration_test` is absent from `pubspec.yaml` and there is no `integration_test/` directory. CA-782 adds both.

**What to report:** slow-frame count, frozen-frame count, and the **p90 frame time** over the journey. Do not report a mean — jank is a tail phenomenon and a mean hides it. p90 frame time is **reported only, never gated**: it is a diagnostic for interpreting a slow-frame movement, not an independent gate on top of it.

**Invalidates the run:** enhanced tracing left on; a journey with variable timing (waiting on a network call whose latency is not controlled); the first run after install.

---

## Device Matrix and Sample Count

> **Proposed — pending team sign-off.** The device classes, sample counts, and run protocol in this section are a starting proposal, not an agreed standard.

The execution target is owned by **CA-975** and is not settled here. Whichever target it lands on, the weekly system-health run uses physical devices and does not depend on the functional CUJ suite's stack, so a Class B iOS device remains a valid target for the startup metrics even if the functional suite ends up Android-only in CI.

Devices are specified as **classes**, not models. The requirement is that every run of a given metric uses the *same* class, so results trend; which specific handset fills a class is a hardware decision, not a methodology one.

| Class | Definition | Frame budget | Rationale |
|---|---|---|---|
| **A — baseline Android** | Mid-tier physical Android, 60 Hz, 4 GB RAM | 16 ms | The regression gate. Mid-tier surfaces regressions that flagship hardware absorbs. Confirm and record whether it runs Impeller or falls back to Skia — see [Cold Start](#cold-start). |
| **B — baseline iOS** | Physical iOS device one to two generations old, 60 Hz | 16 ms | Platform parity; separate engine and rendering path. Impeller is the default here. |
| **C — high refresh** | Physical device, 120 Hz | ~8 ms | Exposes budget failures invisible at 60 Hz. Reported, not gated. |

**No emulators or simulators for any gated metric.** They share host CPU and GPU and produce numbers too noisy to trend.

| Metric | Class | Samples per run | Statistic |
|---|---|---|---|
| TTID (cold) | A, B | 10 | Median |
| TTID (warm) | A, B | 10 | Median |
| Memory | A | 5 journeys | Median per checkpoint |
| Jank | A, C | 5 journeys | Slow/frozen counts; p90 frame time |

**Run protocol:**

1. Discard the first run after any install or reboot.
2. Execute N runs consecutively under identical conditions.
3. Report the **median**, not the mean. Startup distributions are right-skewed; one thermal outlier drags a mean and leaves a median untouched.
4. Record the observed spread alongside the median. It defines the noise floor, which the thresholds below depend on.

---

## Regression Thresholds

> **Proposed — pending team sign-off.** The percentages below are a starting proposal. No threshold can be enforced until [Baselines](#baselines) is populated.

Thresholds are expressed as **rules relative to a baseline**, not as absolute numbers, so they can be applied unchanged once CA-782 supplies the baseline values.

Only Classes A and B gate. Class C is reported for visibility into high-refresh behaviour and never fails a build.

| Metric | Class | Rule |
|---|---|---|
| TTID (cold) | A, B | Median exceeds baseline by **> 10%** |
| TTID (warm) | A, B | Median exceeds baseline by **> 15%** |
| Memory (steady state) | A | Median at any checkpoint exceeds baseline by **> 15%** |
| Slow frames | A | Count exceeds baseline by **> 20%** |
| Frozen frames | A | **Any** frozen frame on a journey with a baseline of zero |
| Slow / frozen frames | C | Reported only — never gated |
| p90 frame time | A, C | Reported only — never gated |

**Confirmation rule:** a breach fails the build only if it reproduces on **two consecutive weekly runs**. A single breach opens an investigation. Weekly performance figures are noisy enough that gating on one data point produces mostly false alarms.

**Continuous vs count metrics.** Percentage rules suit continuous metrics (times, memory) where the baseline is comfortably above zero. They break down for counts near zero, where a baseline of 1 makes any regression a 100% increase. Frozen frames therefore use an absolute rule.

**Noise-floor constraint.** A threshold tighter than the run-to-run spread recorded in the run protocol is a false-alarm generator. When the baselines land, check each percentage against the observed spread and widen any threshold that sits inside it. **Ratify the thresholds against real spread before enabling gating**, rather than adopting these numbers as-is.

---

## Baselines

> **Not yet established.** This section is a placeholder. CA-782 produces the baseline values from its first clean run and records them here.

| Metric | Class A (Android) | Class B (iOS) | Class C (120 Hz) |
|---|---|---|---|
| TTID (cold) | Not yet measured — CA-782 | Not yet measured — CA-782 | n/a |
| TTID (warm) | Not yet measured — CA-782 | Not yet measured — CA-782 | n/a |
| TTFD | No lab source — CA-566 field only | No lab source — CA-566 field only | n/a |
| Memory — Dart heap | Not yet measured — CA-782 | n/a | n/a |
| Memory — RSS | Not yet measured — CA-782 | n/a | n/a |
| Slow frames | Not yet measured — CA-782 | n/a | Not yet measured — CA-782 |
| Frozen frames | Not yet measured — CA-782 | n/a | Not yet measured — CA-782 |
| p90 frame time | Not yet measured — CA-782 | n/a | Not yet measured — CA-782 |

**Why this is empty.** A baseline cannot be established before a harness exists to produce it. Manual DevTools figures taken on a developer machine will not transfer to a CI harness — different device, different thermal conditions, different build pipeline — so populating this table by hand would produce numbers that fail on their first CI comparison for reasons unrelated to any code change.

**When CA-782 records its first clean run**, replace each cell with the measured value, and record alongside it: the device model filling each class, **which renderer that device used (Impeller or Skia)**, the SDK version, the date, and the observed spread across the N samples. The spread is required — the thresholds above cannot be ratified without it. The renderer is required because a jank baseline is not portable across renderers.

---

## Further Reading

- **Flutter: Performance profiling** – [Improving rendering performance](https://docs.flutter.dev/perf/rendering-performance)
- **Flutter: Performance metrics** – [Performance metrics](https://docs.flutter.dev/perf/metrics)
- **DevTools: Performance view** – [Using the Performance view](https://docs.flutter.dev/tools/devtools/performance)
- **DevTools: CPU Profiler view** – [Using the CPU profiler](https://docs.flutter.dev/tools/devtools/cpu-profiler)
- **DevTools: Memory view** – [Using the Memory view](https://docs.flutter.dev/tools/devtools/memory)
- **Impeller** – [Impeller rendering engine](https://docs.flutter.dev/perf/impeller)
- **Perfetto** – [Perfetto trace viewer](https://ui.perfetto.dev/)
- **Related pages** – [CI Scripts and Workflows](CI-Scripts), [Sentry](Sentry)

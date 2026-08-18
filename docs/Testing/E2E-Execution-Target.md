# E2E Execution Target

> Evaluation and decision for [CA-975](https://ripplearc.youtrack.cloud/issue/CA-975), which blocks [CA-749](https://ripplearc.youtrack.cloud/issue/CA-749), [CA-750](https://ripplearc.youtrack.cloud/issue/CA-750), [CA-782](https://ripplearc.youtrack.cloud/issue/CA-782) and [CA-976](https://ripplearc.youtrack.cloud/issue/CA-976).

## Decision

The E2E workload is split across two execution targets, because the functional suite and the system-health run need opposite things.

| Suite | Target | Platform coverage |
|---|---|---|
| Functional CUJ suite (CUJ-1, CUJ-2) | Runner-local Docker stack + emulator on a GitHub Actions Linux runner | Android in CI; iOS local-only |
| Weekly system-health run ([CA-782](https://ripplearc.youtrack.cloud/issue/CA-782)) | Self-hosted GitHub Actions runner with USB-attached, pinned handsets | Android first; iOS Class B as a follow-on |

Neither half uses a device cloud. That is not a cost preference — Firebase Test Lab **cannot run the system-health harness at all**, for reasons set out in [Why Firebase Test Lab was rejected](#why-firebase-test-lab-was-rejected).

This is settled, not provisional — [CA-749](https://ripplearc.youtrack.cloud/issue/CA-749), [CA-750](https://ripplearc.youtrack.cloud/issue/CA-750), [CA-782](https://ripplearc.youtrack.cloud/issue/CA-782) and [CA-976](https://ripplearc.youtrack.cloud/issue/CA-976) should be built against it.

Android-first in CI is a deliberate, time-boxed trade-off, and it applies **only to the functional suite**. The system-health run is not permanently restricted to Android; see [Platform coverage of the system-health run](#platform-coverage-of-the-system-health-run).

**TODO [CA-980](https://ripplearc.youtrack.cloud/issue/CA-980):** The Android-first CI decision is time-boxed and due for review by 2026-11-18, together with what it would take to add iOS functional coverage in CI.

The reasoning, the options that were rejected, and the cost model are below.

---

## Why one target does not fit

A device running in **Firebase Test Lab** has no network path to a Supabase or Mailpit container on the CI runner. The OTP capture that CUJ-2 depends on needs an HTTP request from the test binary to `localhost:54324`, and FTL offers no mechanism to carry that request back to the runner.

This is specific to FTL, not a property of device clouds generally. BrowserStack Local, Sauce Connect and LambdaTest all provide tunnels built precisely to expose a runner-local service to a cloud device, and BrowserStack documents that pattern for CI/CD. Those products are evaluated as [option D](#d--tunnel-capable-real-device-cloud--runner-local-stack) and rejected on cost, not on capability.

Beyond the network question, the two suites want different answers:

- The **functional suite** needs a real mail round trip and a database it can reset. Both are properties of the local stack.
- The **system-health run** needs the same physical hardware every week or its numbers do not trend, and it needs a host process attached to the device while the app runs. It does **not** need registration, OTP, or a resettable database — cold start, TTID, warm start, memory and jank are measured on a scripted profile-mode journey that can start from an already-authenticated session.

Forcing a single target to serve both is what produced two incompatible commitments in the strategy document. Splitting them removes the conflict rather than resolving it.

---

## Why Firebase Test Lab was rejected

FTL was the strategy document's recommended target. It cannot run the system-health harness, and this is a capability failure rather than a pricing one — no budget makes it work.

Flutter's performance instrumentation is **host-side**. The tooling drives the device over a VM-service connection from the machine running the command, and writes its output there:

| Metric | Mechanism | Requires |
|---|---|---|
| Cold start, TTID, warm start | `run_cold.dart` guards `if (traceStartup)` on a live `device.vmService`, then `downloadStartupTrace` writes the trace to a host path | A host-side VM-service connection |
| Memory | `drive_service.dart` shells out to `dart devtools --record-memory-profile=<path>` | A host process and a host filesystem |

Line references are `packages/flutter_tools/lib/src/run_cold.dart:113` and `packages/flutter_tools/lib/src/drive/drive_service.dart:252` in Flutter 3.32.0, the version `codemagic.yaml` pins. The same mechanism is present in 3.44.4 (`run_cold.dart:103`, `drive_service.dart:259`), so this is not a version artifact.

FTL runs an instrumentation package inside Google's cloud with no host attachment and returns pass/fail; the Android runner does not surface `reportData`. There is nowhere for the trace or the memory profile to be written, and nothing to write it.

This reframes the strategy document's entire cost table. It ranked FTL virtual against FTL physical against Codemagic on **device-minute price**, for a workload that could not execute on the first two at any price. The comparison was made on a dimension that did not apply.

---

## Options

### A — Hosted Supabase project + device cloud

Both suites run on physical devices in a device cloud against a hosted Supabase test project. The network path works, since the device reaches a public HTTPS endpoint.

Mailpit does not exist in a hosted project, so the OTP has to be read from a real inbox. That is a larger change than swapping one client for another:

- The hosted default SMTP service is capped at **2 emails per hour**, and delivers **only to addresses belonging to the project's organization**. A unique-per-run address — which [CA-976](https://ripplearc.youtrack.cloud/issue/CA-976) requires so a search cannot match a stale message — is rejected outright with "Email address not authorized".
- So a custom SMTP provider must be provisioned *before* any inbox strategy is reachable, and then a programmable inbox (Mailosaur, MailSlurp, or a catch-all domain with an inbound API) on top of it.

Two new vendors, CA-976's Mailpit client discarded rather than adapted, and the system-health half still fails on host attachment if the cloud is FTL.

### B — Runner-local Docker stack + runner-hosted emulator

The `construculator-backend` stack runs as a service on the CI runner; the app runs on an emulator on the same runner. Everything is on `localhost`.

Mailpit survives untouched and CA-976's scope stands as written. This is also the least speculative option: the backend repo **already** runs `supabase db start` on `ubuntu-latest` in `.github/workflows/database_tests.yml`, so Docker-in-CI on GitHub Actions is proven in production today. The E2E use needs the fuller `supabase start` (auth and the mail catcher, not just the database), but the runner and toolchain are known-good.

Two costs. Codemagic's `mac_mini_m2` instances have no Docker daemon and cannot host a Linux stack, so iOS cannot join the suite in CI. And emulated devices make CA-782's numbers untrendable.

### C — Split

The functional suite runs as in option B on a hosted GitHub Actions Linux runner. The system-health run moves to a **self-hosted** GitHub Actions runner with USB-attached, pinned handsets, starting from a primed session, with no dependency on the OTP flow.

The self-hosted runner is what makes the performance harness work: `flutter drive` runs on the runner host, the handset is attached to it, and the VM-service connection and output paths that FTL cannot provide are simply local.

Each suite gets the property it actually needs. The iOS-in-CI gap from option B remains and is tracked in [CA-980](https://ripplearc.youtrack.cloud/issue/CA-980).

### D — Tunnel-capable real-device cloud + runner-local stack

BrowserStack, Sauce Labs and LambdaTest all ship tunnel clients that expose a runner-local service to a cloud device, so the Mailpit path that FTL breaks would work here. This is the option that disproves any claim that device clouds are categorically incompatible with a runner-local backend.

It is rejected on recurring cost. BrowserStack App Automate lists at roughly **$199–249/mo for a single parallel** — treat that as indicative rather than firm, since BrowserStack does not publish a complete price list. That is an order of magnitude above option C's recurring cost, for a functional suite of two tests.

It also only addresses half the problem. A tunnel solves the network path; it does not give `flutter drive` a host attached to the device, so the system-health harness would still need the self-hosted runner from option C. Option D could at best replace the functional-suite leg, at ~$199+/mo, for no capability the runner-local emulator lacks.

---

## Platform coverage of the system-health run

**Android is first; iOS Class B remains in scope as a follow-on.** The Android-only constraint on the *functional* suite is a property of the Docker stack — Codemagic's `mac_mini_m2` instances have no Docker daemon, so an iOS job cannot host Supabase and the mail catcher. The system-health run does not use that stack, so the constraint does not carry over.

What it needs instead is a host with the handset attached. For iOS that means a macOS machine acting as a self-hosted runner with a pinned device on USB. That is additional hardware and setup rather than a blocker, which is why iOS is sequenced after Android rather than dropped: the Class B baseline row in the device matrix survives.

The scripted journey needs an authenticated session before it can measure memory and jank on post-login screens. Two ways to supply it:

- **Prime the session in the app under test** — a profile-mode build that starts from an injected session and local data, with no network dependency. Tracked as [CA-981](https://ripplearc.youtrack.cloud/issue/CA-981).
- **Point it at a backend** — works, but reintroduces a backend dependency for a run that is measuring client-side rendering.

The first is preferred. [CA-782](https://ripplearc.youtrack.cloud/issue/CA-782) is not blocked on it: it ships a pre-login baseline first — cold start, TTID and warm start need no session — and adds the post-login memory and jank journeys once CA-981 lands.

---

## OTP capture

| Option | Mechanism | Survives? | New dependency |
|---|---|---|---|
| A | Programmable inbox over IMAP or provider API | No — rewritten | Custom SMTP **and** an inbox vendor |
| B | Mailpit REST API on `localhost:54324` | Yes — unchanged | None |
| C | Mailpit, functional suite only; system-health run needs no OTP | Yes — unchanged | None |
| D | Mailpit over a vendor tunnel | Yes — unchanged | Tunnel client + subscription |

Registration cannot avoid this. The app's flow (`SendOtpUseCase` → `AuthManagerImpl.sendOtp`/`verifyOtp` → `signInWithOtp`/`verifyOTP`) goes through Supabase's passwordless OTP, which sends a code unconditionally. The backend's `enable_confirmations = false` applies to the password-signup confirmation flow, not this one, and Supabase's static test OTP exists only for SMS (`auth.sms.test_otp`). The code has to be read out of a real inbox on any target.

The backend's `config.toml` configures the mail catcher under the `[inbucket]` key, and its README still calls the service Inbucket, which raises the question of which API CA-976 should target. It is resolved: `database_tests.yml` pins `supabase/setup-cli@v1` at **2.106.0**, and the CLI was already serving Mailpit behind the `[inbucket]` key at that version. The `[local_smtp]` key that replaced `[inbucket]` arrived later, in CLI 2.108, as a rename of an implementation that had already changed. **CA-976's `/api/v1/search` paths are correct as scoped.**

---

## Cost

### The cadence correction

The strategy document's cost table is built on **30 nightly runs per month**. [CA-750](https://ripplearc.youtrack.cloud/issue/CA-750) and [CA-782](https://ripplearc.youtrack.cloud/issue/CA-782) have both since settled on a **weekly** cadence — 52 runs a year, or 4.33 a month.

Every figure in that table is therefore overstated by `30 ÷ 4.33 ≈ 6.9×`. Its tier-1 row, cadence-corrected:

| Option | Doc figure (nightly) | Cadence-corrected (weekly) |
|---|---|---|
| GitHub Actions + FTL virtual | ~$15/mo | ~$2.20/mo |
| GitHub Actions + FTL physical | ~$75/mo | ~$10.80/mo |
| Codemagic pay-as-you-go | ~$115/mo | ~$16.60/mo |

Those rows are the document's "1–10 tests" band priced at its **upper bound of 10 tests**. Phase 1 has two CUJs, so the real Phase-1 numbers are smaller again:

```
2 tests x 3 min x 4.33 runs/mo = 26 device-min/mo
physical  26 x $0.083  = $2.16/mo
virtual   26 x $0.0167 = $0.43/mo
delta                  = $1.73/mo
```

That $1.73/mo is what the document's central recommendation — prefer virtual devices — was actually buying, in exchange for numbers too noisy to trend. Even at the band's upper bound the gap is only $8.66/mo. And as [Why Firebase Test Lab was rejected](#why-firebase-test-lab-was-rejected) establishes, neither FTL column could have run the harness at any price.

The 3 min/test input is the **bottom** of the strategy document's own stated 3–10 min range; that document notes every figure roughly triples at the top of it. Figures below carry the same sensitivity.

### What the decided target costs

Neither half of option C bills per device-minute, so there is no usage-based cost model to build. What remains is device **occupancy** — how long the pinned handsets are tied up each week — and the non-recurring cost of owning them.

Sample counts come from the device matrix in [Performance Measurement](Performance-Measurement) (itself marked *proposed, pending sign-off*, so these move if it does). Cold start and TTID are read from the same `--trace-startup` capture, so ten runs yield both; warm start needs its own trace.

Assuming **30 s per startup sample** and **3 min per scripted journey** — both assumptions, not measurements, and the first thing to replace with real timings:

```
Class A startup   (10 cold+TTID + 10 warm) x 0.5 min = 10 min
Class B startup   (10 cold+TTID + 10 warm) x 0.5 min = 10 min
Class A memory     5 journeys x 3 min                = 15 min
Class A jank       5 journeys x 3 min                = 15 min
Class C jank       5 journeys x 3 min                = 15 min
                                              total  = 65 min
```

Treating cold start and TTID as separate captures gives 75 min; adding the protocol's discarded first run per block puts the realistic figure at **65–78 minutes per weekly run**. At the top of the 3–10 min journey range it approaches 170 minutes.

So a weekly run occupies the pinned devices for roughly **an hour to an hour and a quarter**, once a week. That is comfortable on owned hardware and is a scheduling fact rather than a bill.

### Recurring cost by option

| | Option A | Option D | Option C (decided) |
|---|---|---|---|
| Hosted Supabase test project | $25/mo (Pro) | — | — |
| Programmable inbox vendor | $9–19/mo | — | — |
| Custom SMTP | $0–20/mo | — | — |
| Device-cloud subscription | per-minute | ~$199–249/mo (indicative) | — |
| GitHub Actions runner minutes | ~$0 | ~$0 | ~$0 |
| **Recurring total** | **~$34–64/mo** | **~$199–249/mo** | **~$0/mo** |

Option C's zero is a zero in *recurring cloud spend*, not a claim that it is free. It carries real costs that simply do not arrive monthly:

- **Handsets**, one per pinned device class, bought once and never swapped — swapping one breaks the trend it exists to produce.
- **A runner host that stays up**, with the devices attached, plus a macOS host if and when iOS is added.
- **Maintenance** — a self-hosted runner is infrastructure the team owns, including OS updates, device reconnection after reboots, and physical access when a handset wedges.

Against option A, the comparison is roughly $34–64/mo forever versus a one-off hardware purchase and a machine the team maintains. Against option D it is ~$199–249/mo forever for the same trade. Option C is cheaper on a one- to two-year view, and it is the only one of the three that can run the performance harness at all.

The Supabase line under option A is not optional: the Free tier pauses a project after 7 days of inactivity, which a weekly run would hit on arrival every time, so Pro is the lowest tier that survives the cadence.

---

## Recommendation

**Option C.** It is the only evaluated option that can execute the system-health harness, it keeps CA-976's OTP approach intact, it gives CA-782 the fixed physical device class it needs, and its functional-suite foundation is already running in the backend repo rather than being designed here for the first time. On recurring spend it is also the cheapest, provided the session-priming route in [CA-981](https://ripplearc.youtrack.cloud/issue/CA-981) is taken; pointing the run at a hosted backend instead would add ~$25/mo.

What it means for the blocked tickets:

- **[CA-749](https://ripplearc.youtrack.cloud/issue/CA-749)** — build the environment as the `construculator-backend` Docker stack started on the runner, not a hosted project.
- **[CA-750](https://ripplearc.youtrack.cloud/issue/CA-750)** — the weekly pipeline targets GitHub Actions with the stack as a CI service. Android only; the `#RunE2E` opt-in trigger is unaffected.
- **[CA-782](https://ripplearc.youtrack.cloud/issue/CA-782)** — a separate weekly job on a self-hosted runner with pinned, USB-attached handsets. Android first, pre-login baseline first, iOS Class B and post-login journeys as follow-ons.
- **[CA-976](https://ripplearc.youtrack.cloud/issue/CA-976)** — Mailpit client proceeds as scoped, against the `/api/v1/search` API. Its "passes on both Android and iOS" criterion holds locally but not in CI.

The cost of the decision is iOS functional coverage in CI, accepted deliberately and reviewed under [CA-980](https://ripplearc.youtrack.cloud/issue/CA-980).

---

## Open items

- **Reconciling the strategy document.** `E2E-CUJ-Strategy.md` is not on `main` — it is still in [PR #399](https://github.com/ripplearc/construculator-app/pull/399). Its Test Environment section commits to Docker-in-CI while its Phased Rollout section commits to a hosted Supabase cloud project, and its cost table recommends a target that cannot run the performance harness. All three need to be replaced by the decision above, and that edit lands when #399 does.
- **Per-sample durations.** The 30 s startup and 3 min journey figures above are assumptions. CA-782's first clean run replaces them with measurements, at which point the occupancy figure should be restated.
- **The Performance Measurement link resolves only once [CA-476](https://ripplearc.youtrack.cloud/issue/CA-476) merges.** That page is the source of the sample counts above and is still in flight, so the link 404s in the wiki until it lands.
- **Device models.** The specific Android and iOS handsets filling each class must be chosen, pinned and never changed. Not chosen here.
- **Self-hosted runner host.** Which machine hosts the runner, who maintains it, and where it physically lives are not settled.
- **Supabase organisation tier.** Not determinable from this repo. Only needed if option A is ever revisited.
- **Codemagic plan tier.** `codemagic.yaml` names instance types but carries no plan signal. Does not affect the decision, since neither half of option C runs on Codemagic.

# E2E Testing Strategy for Critical User Journeys

> Research and planning document for epic [CA-746](https://ripplearc.youtrack.cloud/issue/CA-746).

---

## Why this matters

Unit and widget tests run against fakes — a fake Supabase, a fake router, a fake database. They tell you that individual pieces behave correctly in isolation. They cannot tell you whether the real app, talking to a real backend, successfully completes a flow a real user cares about.

E2E tests fill that gap. They drive the running app against a real backend, follow the same taps and screens a user would, and verify the outcome is correct. A regression caught at this layer is one that would have otherwise reached a real user.

We start with authentication because it is the mandatory gateway to everything else in the app. If login or registration is broken, no other feature is reachable.

---

## Initial Critical User Journeys

**CUJ-1 — Login**
A returning user opens the app, enters their email, enters their password, and lands on the dashboard.

**CUJ-2 — Registration**
A new user opens the app, enters their email, completes OTP verification, fills in their account details, and lands on the dashboard.

Together, these cover the full auth boundary — the handshake between the app and Supabase — and confirm that the app shell and dashboard render correctly after a session is established. All future CUJs build on top of this foundation.

---

## Tooling: Patrol

Flutter ships an `integration_test` package in its SDK that can drive a real app on a device or emulator. The decision is whether to use it directly or layer something on top of it.

We are going with **[Patrol](https://patrol.leancode.co/)** by LeanCode.

Patrol wraps `integration_test` and adds a native automation layer that can interact with things outside Flutter's widget tree — system permission dialogs, notification trays, deep links, biometric prompts. For the first two auth CUJs the difference is barely noticeable. But as we add journeys that involve push notifications or other native interactions, raw `integration_test` hits a it's limit. Starting with Patrol now avoids a painful migration later, when the test suite is larger and the cost might be higher.

Patrol also ships with a cleaner finder API that makes tests easier to read and less likely to break when widget trees change.

---

## Test Environment

### Phase 1 — Local development

Tests run against the local Supabase stack from `construculator-backend` (started with `supabase start` via Docker) and the local PowerSync instance. No new infrastructure is needed to get started.

One specific challenge with CUJ-2 is the OTP step. Registration in the app (`SendOtpUseCase` → `AuthManagerImpl.sendOtp`/`verifyOtp`) goes exclusively through Supabase's passwordless OTP flow (`signInWithOtp`/`verifyOTP`), which unconditionally sends a code. This is a separate mechanism from the password-signup confirmation flow, so the project's `enable_confirmations = false` setting (`supabase/config.toml`) has no effect on it. There is also no built-in "static test OTP" for email in Supabase — that feature exists only for SMS (`auth.sms.test_otp`), and only for a locally-run instance, which we already are.

Since the code can't be bypassed, the practical approach is to read the real one out of Mailpit — the local stack's SMTP catcher, exposed at `http://localhost:54324`:

1. Use a unique test email per run (e.g. a timestamp/UUID) so a search doesn't pick up a stale message from a previous run.
2. After triggering the OTP send, poll Mailpit's REST API (`GET /api/v1/search?query=to:"<email>"`, then `GET /api/v1/message/{ID}`) until the message arrives.
3. Extract the 6-digit code from the message body and enter it into the OTP screen.

This drives the real OTP round trip against the real local auth server, which is stronger coverage than trying to skip the step.

### Phase 2 — Dedicated test environment (future)

When E2E tests move into CI, they need an environment that is isolated from production and resettable between runs. Since the local stack is already just Docker Compose, the simplest path is to run the same `construculator-backend` stack as a CI service (both GitHub Actions and Codemagic support this) rather than standing up a separate hosted Supabase project — the Mailpit-polling approach from Phase 1 works unchanged in CI.

Key properties:
- Same Docker-based Supabase stack as local dev, migrated to match the production schema via the backend repo's migrations
- A small set of seeded test accounts with fixed, known credentials (committed to the repository — these are not secrets, just deterministic test fixtures), used for CUJ-1 (login), which has no OTP step
- State is resettable before each test run by re-running `supabase start` against a fresh seed, or via the Supabase admin API

Nothing in production is touched. Local development continues to point at the dev environment.

If a hosted cloud project is ever preferred over Docker-in-CI (e.g. for closer parity with the real hosted environment), the OTP problem would need a different solution — such as a real inbox reachable via IMAP/API — since Mailpit only exists in the local/Docker stack.

---

## CI/CD Integration

### When tests run

E2E tests take 3–10 minutes per CUJ on a real device. Running them on every pull request adds too much friction. The proposed model:

- **Nightly scheduled run on `main` if there's a change** — catches regressions automatically without slowing down the daily PR cycle
- **Opt-in trigger on PRs** — a comment like `#RunE2E` fires a targeted E2E workflow on demand, following the same pattern already established for `#RunCheck`

As the suite grows and stabilises, gating production deploys on a CUJ pass is worth revisiting (it is listed as a stretch goal in CA-746).

### Platform options

The existing CI platform is Codemagic, which handles unit, widget, and screenshot tests well. E2E tests are a different workload — longer device sessions — and Codemagic's pricing might make this expensive at scale. The alternatives worth evaluating before committing:

| Platform | Approach | Why consider it |
|---|---|---|
| **GitHub Actions + Firebase Test Lab** | GitHub Actions orchestrates the pipeline (free tier); Firebase Test Lab executes the Patrol binary on real Android/iOS devices at pay-per-minute rates | Most cost-effective for device-based E2E; Firebase Test Lab has native Patrol support |
| **Bitrise** | Flutter-native CI with built-in device testing | Strong Flutter tooling, more predictable pricing for longer jobs |
| **Codemagic (existing)** | Add an `e2e-check` workflow to `codemagic.yaml` | No new tooling to adopt, but cost scales poorly with device time |

The E2E tests themselves are platform-agnostic. The same Patrol binary runs on any of these platforms, so the platform decision can be deferred until Phase 2 without affecting Phase 1 work.

---

## Phased Rollout

### Phase 1 — Foundation
Set up Patrol and implement CUJ-1 (login) and CUJ-2 (registration), running locally against the existing dev environment. The output is two stable, passing tests and a clear pattern that makes it straightforward to add the next CUJ.

### Phase 2 — Infrastructure
Stand up the dedicated test Supabase cloud project and PowerSync instance. Wire the E2E suite into a nightly CI pipeline. Evaluate and commit to a CI platform based on cost and fit.

### Phase 3 — Expand coverage
Add CUJs for the remaining core product flows: project creation, estimation, member invitation, and PowerSync sync verification. Evaluate gating production deploys on CUJ pass.

---

*This is a research and planning document. Implementation details and infrastructure decisions will be recorded in the subtasks under CA-746 as work is picked up.*

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

Patrol wraps `integration_test` and adds a native automation layer that can interact with things outside Flutter's widget tree — system permission dialogs, notification trays, deep links, biometric prompts. For the first two auth CUJs the difference is barely noticeable. But as we add journeys that involve push notifications or other native interactions, raw `integration_test` hits its limit. Starting with Patrol now avoids a painful migration later, when the test suite is larger and the cost might be higher.

Patrol also ships with a cleaner finder API that makes tests easier to read and less likely to break when widget trees change. That property only holds if the suite uses the API deliberately, so the convention below is binding rather than advisory.

### Selector convention

Every widget a CUJ touches must be reachable through a stable, semantic anchor. Concretely:

- **Use `Key`s.** Every widget a CUJ interacts with carries a `const Key('<screen>_<element>_<role>')` — for example `Key('login_email_field')`, `Key('login_submit_button')`. Adding the key to the production widget is part of the CUJ's work, not a follow-up.
- **Semantics labels are the accepted alternative** where a key is impractical (e.g. a widget from a shared package we do not own). They also carry accessibility value, so prefer them over any text-matching fallback.
- **A type finder scoped to an unambiguous ancestor is the third accepted anchor**, for a widget from a package we do not own that carries neither a `Key` nor a meaningful semantics label — e.g. `$(BottomSheet).$(CoreButton)` for the confirm button inside a package-owned success modal. It is stable because the scope, not the position, identifies the widget; it is only acceptable when the scope resolves to exactly one match.
- **Positional finders are banned.** `$(TextField).first`, `.at(1)`, and anything else that depends on widget ordering silently targets the wrong widget the moment a field is reordered or an error banner is inserted above it, and the resulting failure does not point at the cause.
- **Raw English text finders are banned.** `$('Continue')` matches a literal string, and this app ships localization (see [Localization](Localization)). A text-matching finder fails under any non-English locale and couples the test to copy changes. If a label genuinely must be matched, resolve it through the localization key rather than hardcoding the English string.

The purpose is that a CUJ test fails only when the journey is broken — never because the widget tree was rearranged or a string was reworded.

### Constraint: Patrol has no Swift Package Manager support

Adopting Patrol constrains the pending CocoaPods → Swift Package Manager migration (CA-831). `flutter build ios` reports this directly:

```
The following plugins do not support Swift Package Manager for ios:
  - patrol
This will become an error in a future version of Flutter.
```

The repo already sets `enable-swift-package-manager: false` in `pubspec.yaml`, so nothing breaks today, but the E2E suite now depends on that staying false. CA-831 cannot complete until Patrol ships SPM support upstream, and this is a blocker on that ticket rather than a detail of this one.

---

## Test Environment

### Phase 1 — Local development

Tests run against the local Supabase stack from `construculator-backend` (started with `supabase start` via Docker) and the local PowerSync instance. No new infrastructure is needed to get started.

#### CUJ-1 credentials

CUJ-1 logs in, so it needs an account that already exists before the test runs. The source of truth is the backend repo's seeders, which Supabase applies automatically on `supabase db reset` (`supabase/config.toml` sets `db.seed.sql_paths = ["./seeders/**/*.sql"]`):

- `construculator-backend/supabase/seeders/sample_data/103_users.sql` creates the profile row for `seeder@example.com`.

That seed is only half the account. It populates `public.users` with a **placeholder `credential_id`**; the matching Supabase Auth identity — and therefore the password the test types — is not seeded, and the backend README currently asks the developer to create it by hand in Studio and paste the UID back into `users.credential_id`. A manual step is not something an E2E suite can depend on, so **the E2E work must make the auth user seeded rather than hand-created**: extend the seeders to insert the `auth.users` row with a known password and a `credential_id` that already matches, so that `supabase db reset` alone produces a login-ready account.

Until that lands, treat the hand-linked account as a known Phase 1 gap rather than the intended design, and keep the credentials in one place (`integration_test/utils/test_config.dart`) pointing at the seed above, so the test never carries an untraceable value.

One specific challenge with CUJ-2 is the OTP step. Registration in the app (`SendOtpUseCase` → `AuthManagerImpl.sendOtp`/`verifyOtp`) goes exclusively through Supabase's passwordless OTP flow (`signInWithOtp`/`verifyOTP`), which unconditionally sends a code. This is a separate mechanism from the password-signup confirmation flow, so the project's `enable_confirmations = false` setting (`supabase/config.toml`) has no effect on it. There is also no built-in "static test OTP" for email in Supabase — that feature exists only for SMS (`auth.sms.test_otp`), and only for a locally-run instance, which we already are.

Since the code can't be bypassed, the practical approach is to read the real one out of Mailpit — the local stack's SMTP catcher, exposed at `http://localhost:24324`. Note this requires a Supabase CLI recent enough to ship **Mailpit**: older CLI versions served **Inbucket** on the same port with a different API shape, so verify against the CLI version pinned in `construculator-backend` before relying on the endpoints below.

1. Use a unique test email per run (e.g. a timestamp/UUID) so a search doesn't pick up a stale message from a previous run.
2. After triggering the OTP send, poll Mailpit's REST API (`GET /api/v1/search?query=to:"<email>"`, then `GET /api/v1/message/{ID}`) until the message arrives. **Bound the loop:** poll at 1-second intervals and fail the test after 30 seconds with an explicit "OTP email never arrived" message. An unbounded wait turns a stuck SMTP delivery into a test that hangs until the outer harness timeout, which reports as a generic timeout rather than the real cause.
3. Extract the 6-digit code from the message body and enter it into the OTP screen.

This drives the real OTP round trip against the real local auth server, which is stronger coverage than trying to skip the step.

#### Known gap: Android and iOS drive different app identities

Patrol needs an app identity per platform (`pubspec.yaml`'s `patrol.android.package_name` / `patrol.ios.bundle_id`). Android points at the fishfood flavor (`com.cms.cm_sample.fishfood`), but the repo tracks no iOS `.xcscheme` files, so there is no iOS flavor to point at and `bundle_id` is the unflavored `com.example.construculatorAppArchitecture`.

The consequence is that the two platforms exercise different builds, potentially against different backends — which cuts against the "deterministic by construction" goal above and matters when reading a cross-platform E2E result. This predates the E2E work and is not solved here; it is recorded so results are read with it in mind, and adding iOS flavor schemes belongs in Phase 2 alongside the CI environment work.

### Phase 2 — Dedicated test environment (future)

When E2E tests move into CI, they need an environment that is isolated from production and resettable between runs. Since the local stack is already just Docker Compose, the simplest path is to run the same `construculator-backend` stack as a CI service (both GitHub Actions and Codemagic support this) rather than standing up a separate hosted Supabase project — the Mailpit-polling approach from Phase 1 works unchanged in CI.

Key properties:
- Same Docker-based Supabase stack as local dev, migrated to match the production schema via the backend repo's migrations
- A small set of seeded test accounts with fixed, known credentials (committed to the repository — these are not secrets, just deterministic test fixtures), used for CUJ-1 (login), which has no OTP step. **Invariant:** these accounts exist only in the local and CI stacks. The seeders that create them are never applied to a hosted environment, so the committed credentials must never be valid against staging or production. If that ever stops being true, the credentials stop being fixtures and have to move into CI secrets.
- State is resettable before each test run with `supabase db reset`, which drops the database, re-applies migrations, and re-runs the seeders. Note that `supabase start` is a no-op against an already-running stack and does **not** re-seed — a CI job written around it would silently carry state between runs, which is exactly the flakiness this section exists to prevent. Use `supabase stop --no-backup && supabase start` when a full teardown is wanted.

Nothing in production is touched. Local development continues to point at the dev environment.

If a hosted cloud project is ever preferred over Docker-in-CI (e.g. for closer parity with the real hosted environment), the OTP problem would need a different solution — such as a real inbox reachable via IMAP/API — since Mailpit only exists in the local/Docker stack.

---

## CI/CD Integration

### When tests run

E2E tests take 3–10 minutes per CUJ on a real device. Running them on every pull request adds too much friction. The proposed model:

- **Nightly scheduled run on `main` if there's a change** — catches regressions automatically without slowing down the daily PR cycle
- **Opt-in trigger on PRs** — a comment like `#RunE2E` fires a targeted E2E workflow on demand, following the same pattern already established for `#RunCheck`

As the suite grows and stabilizes, gating production deploys on a CUJ pass is worth revisiting (it is listed as a stretch goal in CA-746).

### Platform options

The existing CI platform is Codemagic, which handles unit, widget, and screenshot tests well. E2E tests are a different workload — longer device sessions — and Codemagic's pricing might make this expensive at scale. The alternatives worth evaluating before committing:

| Platform | Approach | Why consider it |
|---|---|---|
| **GitHub Actions + Firebase Test Lab** | GitHub Actions orchestrates the pipeline (free tier); Firebase Test Lab executes the Patrol binary on real Android/iOS devices at pay-per-minute rates | Most cost-effective for device-based E2E; Firebase Test Lab has native Patrol support |
| **Bitrise** | Flutter-native CI with built-in device testing | Strong Flutter tooling, more predictable pricing for longer jobs |
| **Codemagic (existing)** | Add an `e2e-check` workflow to `codemagic.yaml` | No new tooling to adopt, but cost scales poorly with device time |

The E2E tests themselves are platform-agnostic. The same Patrol binary runs on any of these platforms, so the platform decision can be deferred until Phase 2 without affecting Phase 1 work.

### Nightly run cost estimate

Rough monthly cost of the proposed nightly run, to inform the platform decision. Rates are current as of July 2026.

**Per-platform rates:**

| Platform | Rate |
|---|---|
| Firebase Test Lab — virtual (emulated) | $1/device-hr (~$0.017/min) |
| Firebase Test Lab — physical device | $5/device-hr (~$0.083/min) |
| GitHub Actions | Linux $0.006/min, macOS $0.062/min |
| Codemagic | pay-as-you-go macOS $0.095/min, or $299/mo unlimited |
| Bitrise | macOS ~$0.007–0.019/min + device-testing add-on |

Most platforms charge by **device time** (per device-hour). The estimate below assumes an average of **3 minutes per test** (assumptions: 30 nightly runs/month, ~10 min orchestration overhead per run; tiers sized at the upper bound — 10, 50, and 100 tests):

| Suite size | GitHub Actions + FTL virtual | GitHub Actions + FTL physical | Codemagic (pay-as-you-go) |
|---|---|---|---|
| 1–10 tests | ~$15/mo | ~$75/mo | ~$115/mo |
| 10–50 tests | ~$77/mo | ~$375/mo | ~$455/mo |
| > 50 tests | ~$155/mo | ~$745/mo | ~$885/mo |

**Bitrise is deliberately not costed here.** Its build minutes are priced publicly, but the device-testing add-on that would actually execute the Patrol binary is not, so any column for it would be a guess. Costing Bitrise requires a quote, which is part of evaluating it in Phase 2 rather than something this table can settle.

Takeaways:
- **GitHub Actions + Firebase Test Lab on virtual devices** is by far the cheapest option; physical devices cost ~5× more but give real-hardware coverage.
- Codemagic's flat **$299/mo unlimited** plan becomes the better deal at roughly **32 tests** — partway into the 10–50 tier, not past it. From the model above: `$299 / (30 runs × $0.095/min) ≈ 105 min per run`, and `(105 − 10) / 3 ≈ 32 tests`. The 10–50 row's own $455/mo already exceeds the flat plan, which is the same conclusion read off the table.
- Free tiers (FTL's daily free minutes, GitHub's included minutes) offset only the smallest suites and are negligible past tier 1.
- These figures scale close to linearly with per-test runtime — the model uses 3 min/test; at the 10 min/test upper end from ["When tests run"](#when-tests-run) above, the two Firebase Test Lab columns scale exactly (~3.3×, since they are pure device time), while Codemagic scales affinely because the ~10 min per-run orchestration overhead is fixed — roughly 2.8× at the smallest tier rising to ~3.3× at the largest.
- The columns are not strictly like-for-like: the Codemagic figures include the ~10 min per-run orchestration overhead, while the two Firebase Test Lab columns are pure device time and exclude the GitHub Actions minutes that orchestrate them (Linux at $0.006/min, so ~$2/mo — small in absolute terms, but worth knowing it is missing).

Sources: [Firebase Test Lab pricing](https://firebase.google.com/docs/test-lab/usage-quotas-pricing), [GitHub Actions runner pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing), [Codemagic pricing](https://codemagic.io/pricing/), [Bitrise pricing](https://bitrise.io/pricing).

---

## Phased Rollout

The environment each phase runs against is defined once in [Test Environment](#test-environment); this section states the work, not the environment, and defers to that section wherever the two touch.

### Phase 1 — Foundation
Set up Patrol and implement CUJ-1 (login) and CUJ-2 (registration) against the local `construculator-backend` stack (see [Phase 1 — Local development](#phase-1--local-development)). Includes making the CUJ-1 account fully seeded rather than hand-linked, and adding the `Key`s the [Selector convention](#selector-convention) requires. The output is two stable, passing tests and a clear pattern that makes it straightforward to add the next CUJ.

### Phase 2 — Infrastructure
Stand up the Docker-based `construculator-backend` stack as a CI service, per [Phase 2 — Dedicated test environment](#phase-2--dedicated-test-environment-future) — **not** a hosted Supabase cloud project. A hosted project is revisited only if production parity demands it, and doing so invalidates the Mailpit approach CUJ-2 depends on, so it is a decision to make explicitly rather than drift into. Wire the E2E suite into a nightly CI pipeline. Evaluate and commit to a CI platform based on cost and fit.

### Phase 3 — Expand coverage
Add CUJs for the remaining core product flows: project creation, estimation, member invitation, and PowerSync sync verification. Evaluate gating production deploys on CUJ pass.

---

*This is a research and planning document. Implementation details and infrastructure decisions will be recorded in [CA-919](https://ripplearc.youtrack.cloud/issue/CA-919) as work is picked up.*

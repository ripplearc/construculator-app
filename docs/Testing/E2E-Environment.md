# E2E Environment

A reproducible backend for end-to-end tests: a Supabase stack (API, Postgres,
GoTrue auth, Mailpit) plus the self-hosted PowerSync service, with a seeded
fixture set and a scripted way back to it. The same definition runs on a
developer machine and on a CI runner, so a failing E2E test means the same thing
in both places.

> **This stack is isolated from your normal development stack only if
> `E2E_BACKEND_DIR` points at a separate checkout.**
> `supabase/config.toml` declares its own `project_id`
> (`construculator-backend-e2e`), and `powersync/compose.yaml` attaches to
> that project's Docker network by name, so a *separate* checkout gets its
> own containers, volumes and network. But `E2E_BACKEND_DIR` defaults to a
> sibling directory literally named `construculator-backend` — if that's
> also the checkout you run `npx supabase start` from for ordinary local
> dev, `scripts/e2e/reset_env.sh` and `scripts/e2e/stop_env.sh --purge`
> destroy that shared project's data, not some separate E2E-only copy.
> Both commands still ask for confirmation before proceeding, naming the
> project they're about to act on. Nothing yet enforces the separate-checkout
> requirement structurally — tracked in
> [CA-1007](https://ripplearc.youtrack.cloud/issue/CA-1007). If you need
> both a dedicated E2E stack and ordinary local dev, use two checkouts and
> point `E2E_BACKEND_DIR` at the E2E-only one explicitly.

## Why this environment exists

E2E tests need a backend that can be returned to a known state. Without one,
tests become order-dependent and failures get ambiguous — a test can fail
because the code broke or because a row left over from an earlier run changed.
The seeded fixtures and `reset_env.sh` give that known state.

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Docker | Must be running. Both stacks are containers. |
| `construculator-backend` checkout | Owns `supabase/` and `powersync/`. Expected as a sibling of this repository, or point `E2E_BACKEND_DIR` at it. |
| Supabase CLI | Taken from `PATH`, else the backend's `node_modules`, else `npx`. |

## Quick start

```bash
scripts/e2e/start_env.sh          # Supabase + PowerSync
scripts/e2e/generate_e2e_env.sh   # write assets/env/.env.dev from the running stack
scripts/e2e/adb_reverse.sh        # only when targeting a device or emulator
fvm flutter run --dart-define=ENVIRONMENT=dev
```

To return the data to its seeded state between test runs — destructive, see the
note above:

```bash
scripts/e2e/reset_env.sh          # prompts; --yes or E2E_ASSUME_YES=1 to skip
```

And to tear everything down:

```bash
scripts/e2e/stop_env.sh           # non-destructive: stops containers, keeps volumes
scripts/e2e/stop_env.sh --purge   # also deletes the volumes; prompts first
```

## What the scripts do

| Script | Responsibility |
|--------|----------------|
| `lib.sh` | Shared paths, ports and helpers, including the confirmation gate. Sourced by the others, not run directly. |
| `start_env.sh` | Generates the auth signing key and `powersync/.env` if missing, starts both stacks, waits until each answers. Non-destructive. |
| `stop_env.sh` | Stops PowerSync first so it releases the Postgres replication slot, then Supabase. Destructive only with `--purge`. |
| `reset_env.sh` | Destroys the database, restores the seeded state and rebuilds PowerSync's bucket storage. |
| `generate_e2e_env.sh` | Writes the app env file, reading the anon key from `supabase status`. |
| `adb_reverse.sh` | Forwards the stack's ports into an attached Android device. |

## Ports

| Service | URL |
|---------|-----|
| Supabase API | `http://localhost:24321` |
| Postgres | `postgresql://postgres:postgres@localhost:24322/postgres` |
| Supabase Studio | `http://localhost:24323` |
| Mailpit | `http://localhost:24324` |
| PowerSync | `http://localhost:9081` |

Mailpit is the mail catcher on every Supabase CLI version this project pins. The
`[inbucket]` key in `supabase/config.toml` is historical naming — the container
it configures is Mailpit, and its messages are readable at
`http://localhost:24324/api/v1/search`.

## Devices and emulators

The generated env file points at `localhost`, which on a device means the device
itself. `scripts/e2e/adb_reverse.sh` forwards ports 24321, 24324 and 9081 from
the device back to the host, so one env file works in both places. This is
preferred over rewriting URLs to `10.0.2.2`, which only works on the Android
emulator and would need a second set of values.

## Seeded account

The backend seeds one account that E2E sign-in flows use:

| Field | Value |
|-------|-------|
| Email | `seeder@example.com` |
| Password | `e2e-local-only-password` |

Both the `auth.users` credential and the `public.users` profile are seeded, and
`public.users.credential_id` matches the credential's id. Before this was
seeded, the profile existed without a credential, so the account could be read
but never signed in as.

The password is fixed and public on purpose. It is only ever valid against a
local Docker stack, which is never reachable outside the machine that started
it. It must never be reused for a hosted environment.

## Resetting

`reset_env.sh` re-applies migrations and seeders and rebuilds PowerSync's bucket
storage from scratch. The bucket storage is rebuilt rather than reused because
`supabase db reset` creates a new replication slot, and PowerSync's existing
MongoDB buckets would otherwise still describe the previous database.

`supabase db reset` recreates the whole database, so `auth` is cleared along
with `public` — accounts registered through GoTrue during a test run do not
survive a reset, and the seeded account is restored by the seeders. A
registration journey can therefore be run repeatedly from a known state.

That same thoroughness is why the reset is gated: it clears the `auth` and
`public` schemas of the E2E project's database, and only the sample fixtures
come back. Confirm at the prompt, or pass `--yes` / set `E2E_ASSUME_YES=1` when
scripting it.

## CI

`.github/actions/e2e-env` is a composite action that stands the same stack up on
a runner. `.github/workflows/e2e_env_smoke.yml` exercises it and asserts that the
seeded user can actually sign in.

A runner starts with no Supabase project of its own, so the stack is created
from nothing and discarded with the runner — on top of the `project_id`
isolation described above, this gives CI a doubly clean slate. Destructive
steps need no prompt there; set `E2E_ASSUME_YES=1` if a workflow calls the
reset script directly.

```yaml
- uses: ./.github/actions/e2e-env
  id: env
  with:
    backend-ref: master
```

| Input | Default | Notes |
|-------|---------|-------|
| `backend-repo` | `ripplearc/construculator-backend` | Public, so no token is needed. |
| `backend-ref` | `master` | The backend's default branch. Override to test against a backend branch. |
| `backend-path` | `construculator-backend` | Checkout path on the runner. |
| `supabase-version` | `2.106.0` | Matches the backend's `database_tests.yml` pin. |

It reports `supabase-url`, `supabase-anon-key`, `mailpit-url` and
`powersync-url` as outputs.

## Known limits

`supabase/config.toml` sets `[auth.rate_limit] email_sent = 2`, meaning two
confirmation emails per hour. If that limit applies to the Mailpit path, a
registration journey that signs up more than twice in an hour will start failing
on the third attempt for reasons unrelated to the code under test.

> **TODO [CA-976](https://ripplearc.youtrack.cloud/issue/CA-976):** Confirm
> whether `email_sent` throttles the local Mailpit path, and raise the limit for
> the E2E environment if it does.

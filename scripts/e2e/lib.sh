#!/usr/bin/env bash
#
# Shared configuration and helpers for the E2E environment scripts.
#
# Sourced by start_env.sh, stop_env.sh and reset_env.sh. Defines where the
# backend repository lives, which ports the stack publishes, and the small
# helpers those scripts share. Callers are expected to `set -euo pipefail`
# themselves; this file only defines things.

# Backend repository checkout that owns supabase/ and powersync/.
# Defaults to a sibling of the app repository.
#
# supabase/config.toml declares project_id = "construculator-backend-e2e", a
# distinct project from whatever a developer's own local Supabase work uses
# by default — so the containers, volumes and Docker network these scripts
# start and destroy are their own, not a developer's ordinary dev stack.
# The confirmation gate below is defense-in-depth for whatever E2E data the
# stack itself has accumulated, not a guard against hitting unrelated data.
E2E_APP_DIR="${E2E_APP_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
E2E_BACKEND_DIR="${E2E_BACKEND_DIR:-$(dirname "$E2E_APP_DIR")/construculator-backend}"

# project_id from the backend's supabase/config.toml. Named here so the
# confirmation prompts can say exactly which project is about to be destroyed.
E2E_DB_PROJECT="construculator-backend-e2e"

# Read-only mirrors of the ports the backend already binds: the API, database
# and Mailpit ports come from supabase/config.toml, and the PowerSync port from
# PS_PORT in powersync/.env via compose.yaml. Changing them here only points the
# health checks and the generated env file somewhere else — it does not move the
# stack. To actually move a port, change it in the backend repository and update
# the matching value here.
E2E_SUPABASE_API_PORT=24321
E2E_SUPABASE_DB_PORT=24322
E2E_MAILPIT_PORT=24324
E2E_POWERSYNC_PORT=9081

e2e_log() { printf '==> %s\n' "$*"; }
e2e_warn() { printf 'warning: %s\n' "$*" >&2; }
e2e_die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# Resolves the Supabase CLI, preferring one already on PATH and falling back to
# the backend repository's own devDependency so local and CI agree on a version.
e2e_supabase() {
  if command -v supabase >/dev/null 2>&1; then
    supabase "$@"
  elif [ -x "$E2E_BACKEND_DIR/node_modules/.bin/supabase" ]; then
    "$E2E_BACKEND_DIR/node_modules/.bin/supabase" "$@"
  else
    npx --yes supabase "$@"
  fi
}

e2e_require_backend() {
  [ -d "$E2E_BACKEND_DIR/supabase" ] ||
    e2e_die "backend repository not found at '$E2E_BACKEND_DIR'. Set E2E_BACKEND_DIR to its path."
  docker info >/dev/null 2>&1 || e2e_die "Docker is not running."
}

# The Supabase config points auth at ./signing_key.json, which is gitignored
# because it holds an EC private key. Generate one on first use.
#
# Generation starts by writing an empty "[]" array for the CLI to append to, so
# a run that fails partway leaves a file that exists but holds no key. Testing
# for a key rather than for a non-empty file keeps that leftover from being
# mistaken for success, and the file is removed on failure so the next run
# retries instead of bringing auth up with no signing key at all.
e2e_ensure_signing_key() {
  local key_file="$E2E_BACKEND_DIR/supabase/signing_key.json"
  grep -q '"kty"' "$key_file" 2>/dev/null && return 0
  e2e_log "Generating auth signing key"
  printf '[]\n' >"$key_file"
  if ! (cd "$E2E_BACKEND_DIR" && e2e_supabase gen signing-key --algorithm ES256 --append) ||
    ! grep -q '"kty"' "$key_file" 2>/dev/null; then
    rm -f "$key_file"
    e2e_die "could not generate the auth signing key."
  fi
}

# powersync/.env is gitignored and holds a locally generated API token. Tests
# for a real token rather than mere file existence, and removes the file on
# failure, for the same reason as e2e_ensure_signing_key above: a write that
# fails partway (missing .env.example, disk full, openssl failing) would
# otherwise leave a file that exists but holds no usable token, and the next
# run would see it exists and skip regenerating it.
e2e_ensure_powersync_env() {
  local env_file="$E2E_BACKEND_DIR/powersync/.env"
  grep -q '^PS_API_TOKEN=.\+' "$env_file" 2>/dev/null && return 0
  e2e_log "Creating powersync/.env with a generated PS_API_TOKEN"
  sed "s|^PS_API_TOKEN=.*|PS_API_TOKEN=$(openssl rand -hex 32)|" \
    "$E2E_BACKEND_DIR/powersync/.env.example" >"$env_file"
  grep -q '^PS_API_TOKEN=.\+' "$env_file" 2>/dev/null || {
    rm -f "$env_file"
    e2e_die "could not generate powersync/.env."
  }
}

# Gates an action that destroys data. The target is the isolated E2E project,
# so this protects only whatever the E2E stack itself has accumulated — the
# seeders will not restore anything that was not seeded. CI sets
# E2E_ASSUME_YES because a runner has nothing of its own to lose.
e2e_confirm_destructive() {
  local action="$1"
  [ "${E2E_ASSUME_YES:-}" = "1" ] && return 0
  [ -t 0 ] ||
    e2e_die "$action This is not an interactive terminal; pass --yes or set E2E_ASSUME_YES=1 to proceed."
  printf '%s\nContinue? [y/N] ' "$action" >&2
  local reply=""
  read -r reply
  case "$reply" in
    [yY] | [yY][eE][sS]) return 0 ;;
    *) e2e_die "Aborted." ;;
  esac
}

e2e_powersync_compose() {
  docker compose --project-directory "$E2E_BACKEND_DIR/powersync" \
    -f "$E2E_BACKEND_DIR/powersync/compose.yaml" "$@"
}

# Polls until the URL answers or the timeout expires.
e2e_wait_for_http() {
  local url="$1" label="$2" timeout="${3:-120}" waited=0
  e2e_log "Waiting for $label ($url)"
  while ! curl -fsS -o /dev/null "$url" 2>/dev/null; do
    waited=$((waited + 2))
    [ "$waited" -ge "$timeout" ] && e2e_die "$label did not become ready within ${timeout}s."
    sleep 2
  done
}

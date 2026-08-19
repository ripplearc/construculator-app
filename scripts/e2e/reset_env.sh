#!/usr/bin/env bash
#
# Returns the E2E environment to its seeded state.
#
# `supabase db reset` recreates the database, so rows written during a test run
# — including accounts registered through GoTrue — do not survive it. PowerSync
# is cycled around the reset: it must release the replication slot first, and
# its MongoDB bucket storage is discarded afterwards because those buckets still
# describe the database that was just replaced.
#
# WARNING: locally this resets the same Supabase project used for ordinary
# development, not a separate one. Everything in that database is destroyed and
# only the seeded fixtures come back.
#
# TODO(CA-991): isolate via a distinct backend project_id instead of relying on
# this confirmation gate.
#
# Usage: scripts/e2e/reset_env.sh [--yes]
#
#   --yes  Skip the confirmation prompt. Equivalent to E2E_ASSUME_YES=1, which
#          is how CI runs it.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

for arg in "$@"; do
  case "$arg" in
    --yes) E2E_ASSUME_YES=1 ;;
    *) e2e_die "unknown argument '$arg'. Usage: reset_env.sh [--yes]" ;;
  esac
done

e2e_require_backend
e2e_ensure_powersync_env

e2e_confirm_destructive \
  "This will destroy every row in the local '$E2E_DB_PROJECT' database and restore only the seeded fixtures."

e2e_log "Stopping PowerSync"
e2e_powersync_compose down --volumes

e2e_log "Resetting database"
(cd "$E2E_BACKEND_DIR" && e2e_supabase db reset)

e2e_log "Starting PowerSync"
e2e_powersync_compose up -d

e2e_wait_for_http "http://127.0.0.1:${E2E_POWERSYNC_PORT}/api/health" "PowerSync"

e2e_log "E2E environment reset to its seeded state"

#!/usr/bin/env bash
#
# Starts the E2E backend: Supabase (API, Postgres, auth, Mailpit) plus the
# self-hosted PowerSync stack that attaches to Supabase's network.
#
# This starts the isolated E2E Supabase project (see lib.sh), not a developer's
# ordinary local dev stack. Starting is harmless; see reset_env.sh and
# stop_env.sh --purge for the operations that destroy that project's data.
#
# Usage: scripts/e2e/start_env.sh
#
# Environment:
#   E2E_BACKEND_DIR  Path to the construculator-backend checkout.
#                    Defaults to a sibling of this repository.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

e2e_require_backend
e2e_ensure_signing_key
e2e_ensure_powersync_env

e2e_log "Starting Supabase"
(cd "$E2E_BACKEND_DIR" && e2e_supabase start)

e2e_wait_for_http "http://127.0.0.1:${E2E_SUPABASE_API_PORT}/auth/v1/health" "Supabase auth"
e2e_wait_for_http "http://127.0.0.1:${E2E_MAILPIT_PORT}/api/v1/messages" "Mailpit"

e2e_log "Starting PowerSync"
e2e_powersync_compose up -d

e2e_wait_for_http "http://127.0.0.1:${E2E_POWERSYNC_PORT}/api/health" "PowerSync"

e2e_log "E2E environment is ready"
printf '    Supabase API : http://127.0.0.1:%s\n' "$E2E_SUPABASE_API_PORT"
printf '    Postgres     : postgresql://postgres:postgres@127.0.0.1:%s/postgres\n' "$E2E_SUPABASE_DB_PORT"
printf '    Mailpit      : http://127.0.0.1:%s\n' "$E2E_MAILPIT_PORT"
printf '    PowerSync    : http://127.0.0.1:%s\n' "$E2E_POWERSYNC_PORT"

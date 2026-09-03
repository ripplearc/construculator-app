#!/usr/bin/env bash
#
# Writes the app env file that points the Flutter client at the running E2E
# stack, reading the anon key straight out of `supabase status` so it never has
# to be copied by hand.
#
# The app resolves env files from the ENVIRONMENT dart-define (dev|qa|prod), so
# E2E runs reuse the dev slot:
#   flutter run --dart-define=ENVIRONMENT=dev
#
# Usage: scripts/e2e/generate_e2e_env.sh
#
# Environment:
#   E2E_ENV_FILE  Target env file. Defaults to assets/env/.env.dev.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

E2E_ENV_FILE="${E2E_ENV_FILE:-$E2E_APP_DIR/assets/env/.env.dev}"

e2e_require_backend

status_json="$(cd "$E2E_BACKEND_DIR" && e2e_supabase status -o json)" ||
  e2e_die "could not read Supabase status. Start the stack with scripts/e2e/start_env.sh first."

anon_key="$(printf '%s' "$status_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["ANON_KEY"])')"
[ -n "$anon_key" ] || e2e_die "Supabase status did not report an ANON_KEY."

# The dev slot may already hold a developer's own configuration.
if [ -f "$E2E_ENV_FILE" ] && ! grep -q '^APP_ENV="e2e"$' "$E2E_ENV_FILE"; then
  cp "$E2E_ENV_FILE" "$E2E_ENV_FILE.bak"
  e2e_warn "existing $E2E_ENV_FILE backed up to $E2E_ENV_FILE.bak"
fi

mkdir -p "$(dirname "$E2E_ENV_FILE")"
cat >"$E2E_ENV_FILE" <<EOF
APP_ENV="e2e"
APP_NAME=Construculator
API_URL=http://localhost:${E2E_SUPABASE_API_PORT}
SUPABASE_URL=http://localhost:${E2E_SUPABASE_API_PORT}
SUPABASE_ANON_KEY=${anon_key}
POWERSYNC_URL=http://localhost:${E2E_POWERSYNC_PORT}
DEBUG_MODE=true
ANALYTICS_ENABLED=false
SENTRY_DSN=
POSTHOG_API_KEY=
POSTHOG_HOST=
POSTHOG_DEBUG=false
EOF

e2e_log "Wrote $E2E_ENV_FILE"

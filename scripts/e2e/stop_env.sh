#!/usr/bin/env bash
#
# Stops the E2E backend. PowerSync is stopped first so it releases the Postgres
# replication slot before Supabase goes away.
#
# Usage: scripts/e2e/stop_env.sh [--purge] [--yes]
#
#   --purge  Also delete the PowerSync bucket storage volume and the Supabase
#            database volume of whatever project E2E_BACKEND_DIR's config.toml
#            names (see lib.sh), so the next start begins from empty. It
#            still asks for confirmation first.
#   --yes    Skip that confirmation. Equivalent to E2E_ASSUME_YES=1.
#
# Without --purge this is non-destructive: the containers stop and the data
# volumes are left alone.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

purge=false
for arg in "$@"; do
  case "$arg" in
    --purge) purge=true ;;
    --yes) E2E_ASSUME_YES=1 ;;
    *) e2e_die "unknown argument '$arg'. Usage: stop_env.sh [--purge] [--yes]" ;;
  esac
done

if [ "$purge" = true ]; then
  e2e_confirm_destructive \
    "This will delete the local '$E2E_DB_PROJECT' database volume and PowerSync's bucket storage."
fi

if [ -f "$E2E_BACKEND_DIR/powersync/.env" ]; then
  e2e_log "Stopping PowerSync"
  if [ "$purge" = true ]; then
    e2e_powersync_compose down --volumes
  else
    e2e_powersync_compose down
  fi
fi

e2e_log "Stopping Supabase"
if [ "$purge" = true ]; then
  (cd "$E2E_BACKEND_DIR" && e2e_supabase stop --no-backup)
else
  (cd "$E2E_BACKEND_DIR" && e2e_supabase stop)
fi

e2e_log "E2E environment stopped"

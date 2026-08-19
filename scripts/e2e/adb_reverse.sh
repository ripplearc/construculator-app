#!/usr/bin/env bash
#
# Maps the E2E stack's host ports into a connected Android device or emulator.
#
# The generated env file points at localhost, which on a device means the device
# itself. `adb reverse` forwards those ports back to the host, so the same env
# file works on host and device without a second set of URLs.
#
# Usage: scripts/e2e/adb_reverse.sh
#
# Environment:
#   ANDROID_SERIAL  Target a specific device when several are attached.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

command -v adb >/dev/null 2>&1 || e2e_die "adb not found on PATH."

[ "$(adb devices | grep -c -w 'device')" -gt 0 ] ||
  e2e_die "no Android device or emulator is attached."

for port in "$E2E_SUPABASE_API_PORT" "$E2E_MAILPIT_PORT" "$E2E_POWERSYNC_PORT"; do
  adb reverse "tcp:$port" "tcp:$port" >/dev/null
  e2e_log "Reversed tcp:$port"
done

e2e_log "Device can now reach the E2E stack on localhost"

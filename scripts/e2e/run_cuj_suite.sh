#!/usr/bin/env bash
#
# Runs the Patrol CUJ suite on the attached Android emulator, with one retry to
# absorb known GitHub-hosted-emulator flake (see docs/Testing/E2E-CI.md#retry).
#
# Invoked from the "Run CUJ suite on Android emulator" step of
# .github/workflows/e2e_cuj.yml. It lives in a script rather than an inline
# `script:` block because reactivecircus/android-emulator-runner runs that block
# under /usr/bin/sh (dash), which does not support `set -o pipefail`.
set -euo pipefail

# Ports the E2E stack publishes. adb_reverse.sh forwards these onto the emulator;
# TestConfig.mailpitUrl is a compile-time dart-define, so CUJ-2's Mailpit client
# only reaches the catcher if E2E_MAILPIT_URL is passed here with the same port.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

scripts/e2e/adb_reverse.sh

adb shell screenrecord --time-limit 180 /sdcard/e2e.mp4 &
recorder_pid=$!

max_attempts=2
attempt=1
success=0
while [ "$attempt" -le "$max_attempts" ]; do
  # Each attempt starts from the seeded database. Registration (CUJ-2) writes a
  # users row with a UNIQUE phone, so a second attempt against a dirty database
  # collides on users_phone_key.
  scripts/e2e/reset_env.sh --yes

  if patrol test \
    --target integration_test/patrol_test.dart \
    --flavor fishfood \
    --dart-define=ENVIRONMENT=dev \
    --dart-define=E2E_MAILPIT_URL="http://localhost:${E2E_MAILPIT_PORT}"; then
    success=1
    break
  fi
  echo "::warning::CUJ suite failed on attempt $attempt of $max_attempts"
  attempt=$((attempt + 1))
done

kill "$recorder_pid" 2>/dev/null || true
sleep 1
adb pull /sdcard/e2e.mp4 e2e-recording.mp4 || true
adb exec-out screencap -p > e2e-final-state.png || true
adb logcat -d > e2e-logcat.txt || true

[ "$success" -eq 1 ]

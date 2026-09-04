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

# Patrol's own --record-video starts a fresh `adb shell screenrecord` per Dart
# test (Android's screenrecord caps a single recording at 180s), rather than
# one recording spanning the whole script the way a hand-rolled `adb shell
# screenrecord` at the top of this file would. Build+install alone has taken
# up to ~213s in CI, which would exhaust a single 180s recording before the
# app is even on screen -- this is why the previous approach only ever
# captured a stuck home screen.
VIDEO_DIR="build/e2e-videos"

max_attempts=2
attempt=1
success=0
while [ "$attempt" -le "$max_attempts" ]; do
  # Each attempt starts from the seeded database. Registration (CUJ-2) writes a
  # users row with a UNIQUE phone, so a second attempt against a dirty database
  # collides on users_phone_key.
  scripts/e2e/reset_env.sh --yes

  # Discard the previous attempt's videos so only the kept (last) attempt's
  # recordings survive, matching Gradle's own results-dir overwrite behaviour.
  rm -rf "$VIDEO_DIR"
  mkdir -p "$VIDEO_DIR"

  if patrol test \
    --target integration_test/patrol_test.dart \
    --flavor fishfood \
    --dart-define=ENVIRONMENT=dev \
    --dart-define=E2E_MAILPIT_URL="http://localhost:${E2E_MAILPIT_PORT}" \
    --record-video \
    --video-output-dir "$VIDEO_DIR"; then
    success=1
    break
  fi
  echo "::warning::CUJ suite failed on attempt $attempt of $max_attempts"
  attempt=$((attempt + 1))
done

adb logcat -d > e2e-logcat.txt || true

# A screenshot of each test's last recorded frame -- the state closest to
# wherever it stopped -- only when the suite is about to be reported as
# failed. A passing run has no "point of failure" to capture.
if [ "$success" -ne 1 ]; then
  if command -v ffmpeg >/dev/null 2>&1; then
    for video in "$VIDEO_DIR"/*.mp4; do
      [ -e "$video" ] || continue
      # Decodes the whole clip rather than seeking from the end: `-sseof`
      # landed past the last decodable frame on a ~55s recording and
      # silently produced a zero-byte output. These recordings are short
      # enough (one CUJ each) that decoding start-to-finish is cheap, and
      # `-update 1` keeps overwriting the same file, so what's left once
      # ffmpeg reaches the end is exactly the last frame.
      ffmpeg -y -i "$video" -vsync 0 -update 1 -q:v 2 "${video%.mp4}.png" \
        2>/dev/null || e2e_warn "could not extract a screenshot from $video"
    done
  else
    e2e_warn "ffmpeg not found; skipping failure screenshots"
  fi
fi

[ "$success" -eq 1 ]

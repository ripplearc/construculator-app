#!/usr/bin/env bash
#
# Runs every CUJ under integration_test/features on the attached Android
# emulator, each as its own independent `patrol test` invocation with its own
# up-to-2-attempt retry (see docs/Testing/E2E-CI.md#retry) and its own fresh
# database. A CUJ file needs nothing beyond existing at
# integration_test/features/**/cuj_*_test.dart to be picked up here — there is
# no shared aggregator file to edit.
#
# One `patrol test` invocation per CUJ, rather than one invocation covering
# every CUJ, is deliberate: a shared invocation's native test dispatch has
# been observed (in CI) to drop a registered CUJ entirely without erroring —
# JUnit reports it as "instrumentation process crashed" even though nothing
# crashed, it simply never received a request to run. Giving each CUJ its own
# invocation, launch and teardown makes that class of failure structurally
# impossible: there is no shared session across CUJs left to lose a CUJ from.
# It also means a CUJ that writes data (CUJ-2's registration) always starts
# from a fresh database, not just a fresh database per retry of the whole
# batch.
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

# Patrol's own --record-video starts a fresh `adb shell screenrecord` per
# invocation (Android's screenrecord caps a single recording at 180s), so each
# CUJ's own video only spans its own execution, not the build+install time
# ahead of it. Persistent across CUJs (one subdirectory per CUJ, so a later
# CUJ's run can never touch an earlier CUJ's saved video); cleared per-CUJ at
# the top of each of its own attempts, so only that CUJ's kept (last) attempt
# survives, matching Gradle's own results-dir overwrite behaviour.
VIDEO_DIR="build/e2e-videos"
rm -rf "$VIDEO_DIR"
mkdir -p "$VIDEO_DIR"

# Gradle overwrites build/app/outputs/androidTest-results/connected on every
# `patrol test` invocation that reaches its instrumented-test phase, so with
# one invocation per CUJ — and one per retry — the next run would silently
# erase the previous result. Two trees are snapshotted from that directory
# before it is overwritten:
#
#   RESULTS_DIR (build/e2e-results/<cuj>.xml)  -- each CUJ's last attempt only.
#     The human-facing view: the job-summary step and the cuj-e2e-junit
#     artifact read this.
#
#   ATTEMPTS_DIR (build/e2e-attempts/attempt-<n>/<cuj>.xml)  -- every attempt of
#     every CUJ, one directory per attempt number. The machine input:
#     scripts/e2e/build_e2e_report.dart reduces this whole tree to
#     build/e2e/e2e-run.json, classifying a CUJ that was red on attempt <n> and
#     green on a later attempt as `flaked` — the only flake signal this suite
#     produces.
#
# run_cuj clears that Gradle directory at the start of each CUJ, so a CUJ that
# never reaches its instrumented-test phase (its build died, or its env reset
# never came back) cannot snapshot the previous CUJ's XML as its own.
RESULTS_DIR="build/e2e-results"
rm -rf "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

ATTEMPTS_DIR="build/e2e-attempts"
rm -rf "$ATTEMPTS_DIR"
mkdir -p "$ATTEMPTS_DIR"

max_attempts=2

# Path to the JUnit XML Gradle wrote for the most recent `patrol test`
# invocation, or empty if none exists yet. A CUJ whose build fails outright
# never creates the directory, and `find` on a missing path is a non-zero exit
# that `pipefail` + `set -e` would turn into a whole-script abort — so check the
# directory first and swallow find's own status.
_current_junit_xml() {
  [ -d build/app/outputs/androidTest-results ] || return 0
  find build/app/outputs/androidTest-results -name '*.xml' 2>/dev/null | head -1 || true
}

# run_cuj CUJ_FILE
#
# Runs one CUJ file to completion: its own retry loop, a fresh seeded database
# per attempt, its own video directory, a snapshot of its JUnit XML, and — only
# if it failed — a screenshot pulled from its last recorded frame. Prints
# nothing a caller needs to parse; exit status is 0 if the CUJ passed and 1 if
# it did not (including if it never built).
#
# Every step that is *expected* to fail sometimes (a `patrol test` that fails,
# an env reset that does not come back, a build that dies before it writes a
# results directory) is checked explicitly here so it turns into a warning and,
# where it makes sense, a retry. The call site additionally runs this in a
# subshell, so even an unforeseen fatal error stops at this one CUJ instead of
# aborting the script and robbing every later CUJ of its run.
run_cuj() {
  local cuj_file="$1"
  local cuj_name cuj_video_dir attempt cuj_success xml_src video
  local device_args patrol_rc last_snapshot

  cuj_name="$(basename "$cuj_file" .dart)"
  cuj_video_dir="$VIDEO_DIR/$cuj_name"

  # A CUJ whose env reset fails both attempts, or whose build dies before the
  # connectedAndroidTest task starts, never has `patrol test` reach the point
  # where Gradle overwrites its shared results directory. Clearing it here
  # stops such a CUJ from snapshotting a stale JUnit XML left by an earlier
  # CUJ and uploading it mislabeled as its own.
  rm -rf build/app/outputs/androidTest-results

  attempt=1
  cuj_success=0
  last_snapshot=""
  while [ "$attempt" -le "$max_attempts" ]; do
    # Each attempt starts from the seeded database. Registration (CUJ-2) writes
    # a users row with a UNIQUE phone, so a second attempt against a dirty
    # database collides on users_phone_key. A reset that does not come back is
    # a spent attempt, not a reason to abandon this CUJ or the ones after it.
    if ! scripts/e2e/reset_env.sh --yes; then
      e2e_warn "$cuj_name: E2E env reset failed on attempt $attempt of $max_attempts"
      attempt=$((attempt + 1))
      continue
    fi

    rm -rf "$cuj_video_dir"
    mkdir -p "$cuj_video_dir"

    # CI's runner has exactly one device (the emulator), so patrol auto-selects
    # it with no flag needed. A local dev machine can see several (a phone, the
    # desktop, a browser), where patrol instead blocks on an interactive
    # "select a device" prompt -- fatal under a non-interactive invocation like
    # this script's. PATROL_DEVICE lets local runs disambiguate without
    # hardcoding any one device into the script itself.
    device_args=()
    [ -n "${PATROL_DEVICE:-}" ] && device_args=(-d "$PATROL_DEVICE")

    patrol_rc=0
    patrol test \
      --target "$cuj_file" \
      --flavor fishfood \
      --dart-define=ENVIRONMENT=dev \
      --dart-define=E2E_MAILPIT_URL="http://localhost:${E2E_MAILPIT_PORT}" \
      --record-video \
      --video-output-dir "$cuj_video_dir" \
      "${device_args[@]}" || patrol_rc=$?

    # Snapshot this attempt's JUnit XML now: the next `patrol test` invocation
    # — this CUJ's own retry, or the first attempt of the next CUJ — overwrites
    # Gradle's shared results directory. Captured pass or fail, because a CUJ
    # that was red here and green on its retry is exactly what makes the run
    # `flaked` rather than `passed` in build_e2e_report.dart.
    xml_src="$(_current_junit_xml)"
    if [ -n "$xml_src" ]; then
      mkdir -p "$ATTEMPTS_DIR/attempt-$attempt"
      cp "$xml_src" "$ATTEMPTS_DIR/attempt-$attempt/$cuj_name.xml"
      last_snapshot="$ATTEMPTS_DIR/attempt-$attempt/$cuj_name.xml"
    fi

    if [ "$patrol_rc" -eq 0 ]; then
      cuj_success=1
      break
    fi
    echo "::warning::$cuj_name failed on attempt $attempt of $max_attempts"
    attempt=$((attempt + 1))
  done

  # Each CUJ's last attempt, for the job summary and the cuj-e2e-junit
  # artifact. Copied from the per-attempt snapshot taken inside the loop rather
  # than re-read from Gradle's directory, so a CUJ whose retry never built
  # still keeps its earlier attempt's result here. Empty only when no attempt
  # reached its instrumented-test phase at all.
  if [ -n "$last_snapshot" ]; then
    cp "$last_snapshot" "$RESULTS_DIR/$cuj_name.xml"
  else
    e2e_warn "$cuj_name produced no JUnit XML"
  fi

  if [ "$cuj_success" -eq 1 ]; then
    return 0
  fi

  # A screenshot of this CUJ's last recorded frame -- the state closest to
  # wherever it stopped. Only extracted on failure: a passing CUJ has no
  # "point of failure" to capture.
  if command -v ffmpeg >/dev/null 2>&1; then
    for video in "$cuj_video_dir"/*.mp4; do
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
    e2e_warn "ffmpeg not found; skipping failure screenshot for $cuj_name"
  fi
  return 1
}

mapfile -t cuj_files < <(find integration_test/features -type f -name 'cuj_*_test.dart' | sort)
if [ "${#cuj_files[@]}" -eq 0 ]; then
  e2e_die "no CUJ files found under integration_test/features (expected cuj_*_test.dart)"
fi
e2e_log "Discovered ${#cuj_files[@]} CUJ(s): ${cuj_files[*]}"

overall_success=1
for cuj_file in "${cuj_files[@]}"; do
  # Subshell: one CUJ's failure — even a fatal, unhandled one — exits only its
  # own subshell under `set -e`, so the loop still reaches every CUJ after it.
  if ! ( run_cuj "$cuj_file" ); then
    overall_success=0
  fi
done

adb logcat -d > e2e-logcat.txt || true

[ "$overall_success" -eq 1 ]

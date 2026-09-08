#!/bin/bash
#
# Captures one performance run against a single attached Android device.
#
# Emits raw artifacts only. Turning them into a perf-run.json record is the job
# of scripts/perf/build_perf_report.dart, so this script stays re-runnable and
# leaves every judgement about medians and thresholds to the reporting step.
#
# Usage:
#   scripts/perf/capture_perf_run.sh --device-id <id> --output-dir <dir> \
#     [--iterations <n>] [--flavor <flavor>]
#
# Layout of --output-dir after a successful run:
#   meta.json                         run provenance (device, sdk, commit)
#   cold/run-<n>/start_up_info.json   one per cold iteration
#   warm/run-<n>/start_up_info.json   one per warm iteration
#   jank/<journey>.timeline_summary.json
#   memory/memory_profile.json
#
set -euo pipefail

# Journey identifier. Must match preLoginJourneyId in the journey test, since it
# names both the emitted timeline files and the series in the trend history.
JOURNEY="pre_login_v1"
JOURNEY_TARGET="integration_test/perf/pre_login_journey_test.dart"
DRIVER="test_driver/perf_driver.dart"

DEVICE_ID=""
OUTPUT_DIR=""
ITERATIONS=5
FLAVOR="fishfood"

while [[ $# -gt 0 ]]; do
  case $1 in
    --device-id) DEVICE_ID="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --iterations) ITERATIONS="$2"; shift 2 ;;
    --flavor) FLAVOR="$2"; shift 2 ;;
    *) echo "❌ Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$DEVICE_ID" || -z "$OUTPUT_DIR" ]]; then
  echo "❌ --device-id and --output-dir are required" >&2
  exit 1
fi

if ! [[ "$ITERATIONS" =~ ^[0-9]+$ ]] || [[ "$ITERATIONS" -lt 1 ]]; then
  echo "❌ --iterations must be a positive integer, got: $ITERATIONS" >&2
  exit 1
fi

if ! fvm flutter devices --machine \
  | grep -qE "\"id\"[[:space:]]*:[[:space:]]*\"${DEVICE_ID}\""; then
  echo "❌ Device '$DEVICE_ID' is not attached. Attached devices:" >&2
  fvm flutter devices >&2
  exit 1
fi

# All capture happens in a staging directory outside the repo tree, and only the
# finished set is copied to --output-dir at the end.
#
# The reason is the two `flutter clean`s below. This script runs two entry-point
# targets against the same tree: lib/main.dart for the startup legs, then the
# integration_test journey for the drive legs. flutter's build system does not
# rebuild when only the --target changes, so it will run whichever program it
# compiled last unless the tree is cleaned between the phases. A clean deletes
# build/, which is where --output-dir usually lives, so the artifacts cannot be
# captured there directly.
OUTPUT_DIR="$(mkdir -p "$OUTPUT_DIR" && cd "$OUTPUT_DIR" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK"/{cold,warm,jank,memory}

# Runs the app once with startup tracing, writing start_up_info.json into $1.
#
# The remaining arguments are passed through to `flutter run`, which is how the
# cold variant adds --purge-persistent-cache. `flutter run --trace-startup` is
# used rather than `flutter drive` because only the run path downloads the
# startup trace; flutter drive produces no start_up_info.json.
capture_startup() {
  local destination="$1"
  shift
  mkdir -p "$destination"
  FLUTTER_TEST_OUTPUTS_DIR="$destination" fvm flutter run \
    --profile \
    --trace-startup \
    --flavor "$FLAVOR" \
    --dart-define=ENVIRONMENT=dev \
    -d "$DEVICE_ID" \
    "$@"
}

# Runs one `flutter drive` leg of the journey, with $1 as PERF_OUTPUT_DIR and the
# rest passed through. Retries a few times because the drive legs occasionally
# fail on a transient VM-service race (a rerun clears it).
#
# The jank leg passes --no-dds: the integration_test binding's traceAction opens
# its own VM-service connection to record the timeline, and DDS in front of the
# service refuses it. The memory leg does the opposite - it keeps DDS (which
# `--profile-memory` polls through) and passes PERF_TRACE_TIMELINE=false so the
# journey runs without traceAction.
#
# Each leg starts with `flutter clean`: the two legs compile different programs
# (the jank leg the plain journey, the memory leg the journey with an extra
# --dart-define), and flutter reuses the last build unless the tree is cleaned.
# The stale adb forwards from the startup legs are cleared at the same time.
drive_journey() {
  local perf_out="$1"
  shift
  fvm flutter clean
  adb -s "$DEVICE_ID" forward --remove-all || true
  local attempt
  for attempt in 1 2 3; do
    if PERF_OUTPUT_DIR="$perf_out" fvm flutter drive \
      --profile \
      --flavor "$FLAVOR" \
      --dart-define=ENVIRONMENT=dev \
      --driver="$DRIVER" \
      --target="$JOURNEY_TARGET" \
      -d "$DEVICE_ID" \
      "$@"; then
      return 0
    fi
    echo "⚠️  drive leg attempt $attempt/3 failed; resetting forwards and retrying..." >&2
    adb -s "$DEVICE_ID" forward --remove-all || true
  done
  echo "❌ drive leg failed after 3 attempts" >&2
  return 1
}

echo "🧽 Cleaning the build tree for the startup phase (lib/main.dart)..."
fvm flutter clean

echo "🏗️  Building profile APK (flavor: $FLAVOR)..."
fvm flutter build apk \
  --profile \
  --flavor "$FLAVOR" \
  --dart-define=ENVIRONMENT=dev

# The first launch after an install pays one-off costs (dex optimisation, first
# Impeller shader warm-up) that never recur, so it is captured to a scratch
# directory and thrown away rather than polluting the medians.
echo "🔥 Discarding first-launch warm-up..."
capture_startup "$WORK/.warmup" --purge-persistent-cache
rm -rf "$WORK/.warmup"

for ((i = 1; i <= ITERATIONS; i++)); do
  echo "❄️  Cold start $i/$ITERATIONS..."
  capture_startup "$WORK/cold/run-$i" --purge-persistent-cache
done

for ((i = 1; i <= ITERATIONS; i++)); do
  echo "♨️  Warm start $i/$ITERATIONS..."
  capture_startup "$WORK/warm/run-$i"
done

echo "📊 Capturing jank timeline for journey '$JOURNEY'..."
drive_journey "$WORK/jank" --no-dds

echo "🧠 Capturing memory profile..."
drive_journey "$WORK/memory" \
  --dart-define=PERF_TRACE_TIMELINE=false \
  --profile-memory="$WORK/memory/memory_profile.json"

cat > "$WORK/meta.json" <<EOF
{
  "journey": "$JOURNEY",
  "device_id": "$DEVICE_ID",
  "flavor": "$FLAVOR",
  "iterations": $ITERATIONS,
  "flutter_version": "$(fvm flutter --version | head -1)",
  "commit": "$(git rev-parse HEAD)",
  "captured_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

mkdir -p "$OUTPUT_DIR"
cp -a "$WORK"/. "$OUTPUT_DIR"/
echo "✅ Raw artifacts written to $OUTPUT_DIR"

#!/bin/bash
#
# Golden replayer (CA-1116, H2): replays the prototype's scenarios against
# the app's CalculatorBloc and reports how many pass.
#
# Runs the replay test and prints its score line ("Golden replay: N/T
# scenarios pass (…, D differ on purpose, …)") for the build log. The gate
# is soft until G3, the last Engine ticket, lands: set GOLDEN_REPLAY_GATE=1
# to fail the build unless every scenario passes or is listed in
# test/golden/intended_differences.json (N + D = T). "T of T" would only
# mean "same as the prototype", and the prototype has had bugs of its own.
# A listed check that holds anyway makes the list stale; the gate fails on
# that too, so a listed difference is always a real one. A broken test run
# (the test itself errors, or prints no score) fails the build in either
# mode, because that is not a low score but no score at all.
#
# Usage:
#   scripts/ci/run_golden_replay.sh
#   GOLDEN_REPLAY_GATE=1 scripts/ci/run_golden_replay.sh
#   FLUTTER_CMD="flutter" scripts/ci/run_golden_replay.sh   # outside fvm

set -uo pipefail

FLUTTER_CMD="${FLUTTER_CMD:-fvm flutter}"
TEST_FILE="test/tools/golden/units/bloc_replay_test.dart"
GATE="${GOLDEN_REPLAY_GATE:-0}"

OUTPUT="$($FLUTTER_CMD test "$TEST_FILE" 2>&1)"
STATUS=$?

SCORE="$(printf '%s\n' "$OUTPUT" | grep -m1 '^Golden replay:')"

if [ "$STATUS" -ne 0 ] || [ -z "$SCORE" ]; then
  echo "❌ The golden replay did not run to a score."
  printf '%s\n' "$OUTPUT" | tail -40
  exit 1
fi

echo "📼 $SCORE"
PASSED="$(printf '%s' "$SCORE" | sed -E 's/^Golden replay: ([0-9]+)\/([0-9]+).*/\1/')"
TOTAL="$(printf '%s' "$SCORE" | sed -E 's/^Golden replay: ([0-9]+)\/([0-9]+).*/\2/')"
DIFFER="$(printf '%s' "$SCORE" | sed -nE 's/.*, ([0-9]+) differ on purpose,.*/\1/p')"
DIFFER="${DIFFER:-0}"
STALE="$(printf '%s\n' "$OUTPUT" | grep '^Golden replay: stale intended difference:')"

if [ -n "$STALE" ]; then
  echo "⚠️ A listed difference holds anyway; remove it from test/golden/intended_differences.json:"
  printf '%s\n' "$STALE"
fi

if [ "$GATE" = "1" ]; then
  if [ $((PASSED + DIFFER)) -ne "$TOTAL" ]; then
    echo "❌ Golden replay gate: $PASSED passed + $DIFFER differ on purpose = $((PASSED + DIFFER)), needs $TOTAL/$TOTAL."
    printf '%s\n' "$OUTPUT" | grep -A3 -E '^S[0-9]+ .* — (FAILED|UNSUPPORTED)' | head -60
    exit 1
  fi
  if [ -n "$STALE" ]; then
    echo "❌ Golden replay gate: the intended-differences list is stale."
    exit 1
  fi
fi

echo "✅ Golden replay reported ($PASSED/$TOTAL, $DIFFER differ on purpose, gate ${GATE})."
exit 0

#!/bin/bash
#
# Resolve Build Features (CA-925)
#
# `config/flavors/<flavor>.json` is a human-edited list of enabled feature
# names, e.g. {"features": ["calculator"]}. `flutter build` cannot consume
# that shape directly: `--dart-define-from-file` needs one `ENABLE_X: bool`
# entry per known feature, matched against the `Feature` enum in
# lib/libraries/config/feature_availability.dart. This script does that
# resolution ahead of the build, writing the resolved file to
# build/generated/flavors/<flavor>.json for `--dart-define-from-file` to
# point at. Doing this before `flutter build` runs (rather than inside the
# app) keeps BuildFeatures' compile-time guarantee intact.
#
# Usage:
#   scripts/ci/resolve_build_features.sh <flavor>
#
# Exits 0 and writes build/generated/flavors/<flavor>.json on success; exits
# non-zero with a specific message if the flavor file is missing or lists an
# unrecognized feature name.

set -euo pipefail

FLAVOR="${1:-}"

if [ -z "$FLAVOR" ]; then
  echo "❌ ERROR: Usage: $0 <flavor>"
  exit 1
fi

SOURCE_FILE="config/flavors/${FLAVOR}.json"
OUTPUT_DIR="build/generated/flavors"
OUTPUT_FILE="${OUTPUT_DIR}/${FLAVOR}.json"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "❌ ERROR: No flavor manifest found at ${SOURCE_FILE}"
  exit 1
fi

# An empty file or `{}` has no "features" key at all, and the sed extraction
# below prints the whole file back out when it finds no match -- with no
# other quoted text in that output, the listed-features loop below sees an
# empty list and every feature silently resolves to false. Fail loudly here
# instead, before that extraction ever runs.
if ! grep -q '"features"[[:space:]]*:[[:space:]]*\[' "$SOURCE_FILE"; then
  echo "❌ ERROR: ${SOURCE_FILE} has no \"features\" list"
  exit 1
fi

# Mirrors the Feature enum in lib/libraries/config/feature_availability.dart.
# This is a manual bash-side mirror -- if a case is added, renamed, or
# removed on the Dart enum, update this table and the mapping below to match.
KNOWN_FEATURES=(calculator)

# Maps a known feature name to the ENABLE_X key BuildFeatures reads via
# bool.fromEnvironment. Mirrors lib/libraries/config/build_features.dart.
feature_env_key() {
  case "$1" in
    calculator) echo "ENABLE_CALCULATOR" ;;
    *) return 1 ;;
  esac
}

# Extract the contents of the "features" array without a jq dependency, to
# stay consistent with the rest of scripts/ci (generate_env_file.sh and
# assert_flavor_environment.sh also avoid jq).
FEATURES_BLOCK="$(tr -d '\n' <"$SOURCE_FILE" | sed -E 's/.*"features"[[:space:]]*:[[:space:]]*\[([^]]*)\].*/\1/')"

LISTED_FEATURES=()
while IFS= read -r feature; do
  [ -n "$feature" ] && LISTED_FEATURES+=("$feature")
done < <(printf '%s' "$FEATURES_BLOCK" | grep -o '"[^"]*"' | tr -d '"' || true)

# Validate every listed feature against the known set.
for listed in "${LISTED_FEATURES[@]+"${LISTED_FEATURES[@]}"}"; do
  if ! feature_env_key "$listed" >/dev/null 2>&1; then
    echo "❌ ERROR: Unknown feature '${listed}' in ${SOURCE_FILE}"
    echo "   Known features: ${KNOWN_FEATURES[*]}"
    exit 1
  fi
done

is_listed() {
  local target="$1"
  local listed
  for listed in "${LISTED_FEATURES[@]+"${LISTED_FEATURES[@]}"}"; do
    if [ "$listed" = "$target" ]; then
      return 0
    fi
  done
  return 1
}

mkdir -p "$OUTPUT_DIR"

{
  echo "{"
  feature_count=${#KNOWN_FEATURES[@]}
  index=0
  for feature in "${KNOWN_FEATURES[@]}"; do
    index=$((index + 1))
    env_key="$(feature_env_key "$feature")"
    if is_listed "$feature"; then
      value=true
    else
      value=false
    fi
    if [ "$index" -eq "$feature_count" ]; then
      echo "  \"${env_key}\": ${value}"
    else
      echo "  \"${env_key}\": ${value},"
    fi
  done
  echo "}"
} >"$OUTPUT_FILE"

echo "✅ Resolved build features for flavor '${FLAVOR}' -> ${OUTPUT_FILE}"

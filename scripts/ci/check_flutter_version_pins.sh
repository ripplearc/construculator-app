#!/bin/bash
set -euo pipefail

# Fail if CI carries a Flutter version of its own that .fvmrc should decide.
# Usage: ./scripts/ci/check_flutter_version_pins.sh [repo-root]
#
# Checks:
#   - codemagic.yaml sets no numeric Flutter version under `flutter:`, even one equal to .fvmrc.
#   - every `flutter-version:` in .github/workflows/*.yml and *.yaml equals .fvmrc.

ROOT="${1:-.}"
FVMRC="$ROOT/.fvmrc"

if [ ! -f "$FVMRC" ]; then
  echo "❌ $FVMRC not found."
  exit 1
fi

EXPECTED=$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$FVMRC")
if [ -z "$EXPECTED" ]; then
  echo "❌ No \"flutter\" version found in $FVMRC."
  exit 1
fi

FAILURES=0

CODEMAGIC="$ROOT/codemagic.yaml"
if [ -f "$CODEMAGIC" ]; then
  PINS=$(grep -n -E '^[[:space:]]+flutter:[[:space:]]*["'"'"']?v?[0-9]' "$CODEMAGIC" || true)
  if [ -n "$PINS" ]; then
    echo "❌ codemagic.yaml pins a Flutter version. The version comes from .fvmrc ($EXPECTED):"
    echo "$PINS"
    FAILURES=$((FAILURES + 1))
  fi
fi

for WORKFLOW in "$ROOT"/.github/workflows/*.yml "$ROOT"/.github/workflows/*.yaml; do
  [ -f "$WORKFLOW" ] || continue
  MISMATCHES=$(awk -v expected="$EXPECTED" '
    /^[[:space:]]*#/ { next }
    /flutter-version:/ {
      value = $0
      sub(/[[:space:]]+#.*/, "", value)
      sub(/.*flutter-version:[[:space:]]*/, "", value)
      gsub(/["'"'"'[:space:]]/, "", value)
      if (value != expected) { print FNR ": flutter-version " value }
    }' "$WORKFLOW")
  if [ -n "$MISMATCHES" ]; then
    echo "❌ $WORKFLOW differs from .fvmrc ($EXPECTED):"
    echo "$MISMATCHES"
    FAILURES=$((FAILURES + 1))
  fi
done

if [ "$FAILURES" -gt 0 ]; then
  exit 1
fi
echo "✅ Every CI Flutter version matches .fvmrc ($EXPECTED)"

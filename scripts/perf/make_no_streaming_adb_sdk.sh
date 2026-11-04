#!/bin/bash
#
# Builds an Android SDK folder whose `adb` installs APKs with `--no-streaming`.
#
# On the lab phone a streamed `adb install` stalls about half the time, while
# `adb install --no-streaming` and `adb push` do not. `flutter run` and
# `flutter drive` call `<ANDROID_HOME>/platform-tools/adb install -t -r <apk>`
# and offer no way to add a flag, so this folder holds an `adb` that adds it.
#
# Every other file in the SDK is linked to the real one, so Gradle and Flutter
# see a normal SDK. Only `platform-tools/adb` is replaced by a small wrapper
# that puts `--no-streaming` after the first `install` it is given.
#
# Usage:
#   scripts/perf/make_no_streaming_adb_sdk.sh <output-dir>
#
# Prints the output directory on stdout, ready for ANDROID_HOME and
# ANDROID_SDK_ROOT.
#
# Environment (optional):
#   ANDROID_HOME   real SDK to copy from (default: ANDROID_SDK_ROOT, then the
#                  folder two levels above the `adb` on PATH)
set -euo pipefail

if [[ $# -ne 1 || -z "$1" ]]; then
  echo "❌ Usage: $0 <output-dir>" >&2
  exit 1
fi

REAL_SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [[ -z "$REAL_SDK" ]]; then
  REAL_ADB="$(command -v adb || true)"
  [[ -n "$REAL_ADB" ]] || { echo "❌ No Android SDK: set ANDROID_HOME or put adb on PATH" >&2; exit 1; }
  REAL_SDK="$(cd "$(dirname "$REAL_ADB")/.." && pwd)"
fi
REAL_ADB="$REAL_SDK/platform-tools/adb"
if [[ ! -x "$REAL_ADB" ]]; then
  echo "❌ $REAL_ADB is not an executable adb" >&2
  exit 1
fi

OUTPUT_DIR="$(mkdir -p "$1" && cd "$1" && pwd)"
if [[ "$OUTPUT_DIR" == "$REAL_SDK" ]]; then
  echo "❌ The output folder must not be the real SDK: $REAL_SDK" >&2
  exit 1
fi

for entry in "$REAL_SDK"/* "$REAL_SDK"/.[!.]*; do
  [[ -e "$entry" ]] || continue
  name="$(basename "$entry")"
  [[ "$name" == platform-tools ]] && continue
  ln -sfn "$entry" "$OUTPUT_DIR/$name"
done

rm -rf "$OUTPUT_DIR/platform-tools"
mkdir -p "$OUTPUT_DIR/platform-tools"
for entry in "$REAL_SDK/platform-tools"/*; do
  name="$(basename "$entry")"
  [[ "$name" == adb ]] && continue
  ln -sfn "$entry" "$OUTPUT_DIR/platform-tools/$name"
done

cat >"$OUTPUT_DIR/platform-tools/adb" <<EOF
#!/bin/bash
args=()
inserted=false
for arg in "\$@"; do
  args+=("\$arg")
  if [[ "\$inserted" == false && "\$arg" == install ]]; then
    args+=(--no-streaming)
    inserted=true
  elif [[ "\$arg" == shell ]]; then
    inserted=true
  fi
done
exec "$REAL_ADB" "\${args[@]}"
EOF
chmod +x "$OUTPUT_DIR/platform-tools/adb"

echo "$OUTPUT_DIR"

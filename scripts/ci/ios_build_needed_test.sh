#!/bin/bash
#
# Manual test harness for scripts/ci/ios_build_needed.sh (CA-1240).
#
# Follows the repo's bash test convention (see resolve_build_features_test.sh):
# no shell-test framework, non-zero exit if any case fails. curl is replaced by
# a fake on PATH. The last cases run against the real repository: every
# top-level path must be classified in ios_build_paths.conf, so a new top-level
# directory cannot silently skip the iOS build.
#
# Usage:
#   scripts/ci/ios_build_needed_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET="${SCRIPT_DIR}/ios_build_needed.sh"

FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/fake"

# A "check-runs" URL gets checks.json. A "pulls/<n>/files?...page=<k>" URL gets
# files_<k>.json. A missing or empty file makes the fake fail the way
# curl --fail-with-body does (exit 22 with a body).
cat >"${WORK_DIR}/bin/curl" <<'EOF2'
#!/bin/bash
url=""
for arg in "$@"; do url="$arg"; done
echo "$url" >>"$FAKE_DIR/urls"
case "$url" in
  *check-runs*) body_file="$FAKE_DIR/checks.json" ;;
  *pulls/*/files*page=*) page="${url##*page=}"; body_file="$FAKE_DIR/files_${page}.json" ;;
  *) echo "unexpected url $url" >&2; exit 2 ;;
esac
if [ ! -s "$body_file" ]; then
  echo '{"message":"Server Error"}'
  exit 22
fi
cat "$body_file"
EOF2
chmod +x "${WORK_DIR}/bin/curl"

reset_fake() {
  rm -f "${WORK_DIR}"/fake/*
  printf '{"check_runs":[]}' >"${WORK_DIR}/fake/checks.json"
}

# set_files <page> <name>...   one page of the pull request file list
set_files() {
  local page="$1"
  shift
  local json="[" first=true name
  for name in "$@"; do
    $first || json="$json,"
    first=false
    json="$json{\"filename\":\"$name\"}"
  done
  printf '%s]' "$json" >"${WORK_DIR}/fake/files_${page}.json"
}

run_target() {
  STDOUT_TEXT="$(
    cd "$WORK_DIR" &&
      PATH="${WORK_DIR}/bin:${PATH}" \
      FAKE_DIR="${WORK_DIR}/fake" \
      GH_REPO="owner/repo" GITHUB_TOKEN="token" PR_NUMBER="7" HEAD_SHA="sha1" \
      COMMENT_BODY="${COMMENT_BODY:-#RunCheck}" \
      "$TARGET" "$@" 2>&1
  )"
  EXIT_CODE=$?
}

assert_true() {
  local description="$1"
  shift
  if "$@"; then
    echo "✅ PASS: ${description}"
  else
    echo "❌ FAIL: ${description}"
    echo "   output: ${STDOUT_TEXT}"
    FAILURES=$((FAILURES + 1))
  fi
}

output_is() { [ "$STDOUT_TEXT" = "$1" ]; }
starts_with() { case "$STDOUT_TEXT" in "$1"*) return 0 ;; esac; return 1; }
contains() { echo "$STDOUT_TEXT" | grep -Fq -- "$1"; }
exit_code_is() { [ "$EXIT_CODE" -eq "$1" ]; }

reset_fake
set_files 1 lib/a.dart test/a_test.dart docs/x.md scripts/run_check.sh
run_target
assert_true "skips a Dart, test, docs and script change" starts_with "skip:"
assert_true "exits 0" exit_code_is 0

for ios_file in ios/Podfile pubspec.yaml pubspec.lock pubspec_overrides.yaml .fvmrc codemagic.yaml \
  .github/workflows/run_c_check.yml assets/env/.env.dev config/flavors/fishfood.json \
  scripts/ci/generate_env_file.sh l10n.yaml build.yaml flutter_launcher_icons-prod.yaml; do
  reset_fake
  set_files 1 lib/a.dart "$ios_file"
  run_target
  assert_true "runs iOS when $ios_file changes" starts_with "run: $ios_file matches"
done

reset_fake
set_files 1 lib/a.dart .github/workflows/e2e_cuj.yml scripts/perf/x.sh scripts/dashboard/y.dart android/app/build.gradle
run_target
assert_true "skips other workflows, scripts/perf, scripts/dashboard and android/" starts_with "skip:"

reset_fake
printf '[{"filename":"lib/moved.dart","previous_filename":"ios/Runner/old.swift"}]' >"${WORK_DIR}/fake/files_1.json"
run_target
assert_true "runs iOS when a file was renamed out of ios/" contains "ios/Runner/old.swift matches ios/"

reset_fake
set_files 1 lib/a.dart brand_new_dir/file.txt
run_target
assert_true "runs iOS for a file the list does not mention" contains "not listed in ios_build_paths.conf"

reset_fake
set_files 1 lib/a.dart
COMMENT_BODY="please #RunCheck ios now" run_target
assert_true "runs iOS when the comment says #RunCheck ios" contains "asks for it with #RunCheck ios"

reset_fake
set_files 1 lib/a.dart
COMMENT_BODY="#runcheck   IOS" run_target
assert_true "reads the force word case-insensitively" starts_with "run:"

reset_fake
set_files 1 lib/a.dart
COMMENT_BODY="#RunCheck iosx" run_target
assert_true "does not read #RunCheck iosx as the force word" starts_with "skip:"

reset_fake
set_files 1 lib/a.dart
COMMENT_BODY="see issue#RunCheck ios" run_target
assert_true "does not read a word glued to #RunCheck as the force word" starts_with "skip:"

reset_fake
set_files 1 lib/a.dart
COMMENT_BODY="#RunCheck force" run_target
assert_true "does not read #RunCheck force as the iOS word" starts_with "skip:"

reset_fake
set_files 1 lib/a.dart
COMMENT_BODY=$'#RunCheck\nios' run_target
assert_true "does not read the word on the next line as the force word" starts_with "skip:"

reset_fake
FIRST_PAGE=()
i=0
while [ "$i" -lt 100 ]; do FIRST_PAGE+=("lib/f$i.dart"); i=$((i + 1)); done
set_files 1 "${FIRST_PAGE[@]}"
set_files 2 lib/last.dart ios/Podfile
run_target
assert_true "finds an iOS file on the second page" contains "ios/Podfile matches ios/"

reset_fake
set_files 1 "${FIRST_PAGE[@]}"
set_files 2 lib/last.dart
run_target
assert_true "skips when no page has an iOS file" starts_with "skip:"
assert_true "counts every file it checked" contains "101 files checked"

reset_fake
set_files 1 "${FIRST_PAGE[@]}"
i=2
while [ "$i" -le 30 ]; do set_files "$i" "${FIRST_PAGE[@]}"; i=$((i + 1)); done
set_files 31 lib/x.dart
run_target
assert_true "runs iOS when the file list may be cut off at 3000 files" contains "at most 3000 files"

reset_fake
rm -f "${WORK_DIR}/fake/files_1.json"
run_target
assert_true "runs iOS when the file list cannot be read" contains "could not list the files"
assert_true "still exits 0 when the file list cannot be read" exit_code_is 0

reset_fake
printf 'not json' >"${WORK_DIR}/fake/files_1.json"
run_target
assert_true "runs iOS when the file list is not JSON" contains "could not be read"

reset_fake
set_files 1 lib/a.dart
printf '' >"${WORK_DIR}/fake/checks.json"
run_target
assert_true "runs iOS when the check runs cannot be read" contains "could not read the check runs"

reset_fake
set_files 1 lib/a.dart
printf '{"check_runs":[{"name":"Ios Debug Build","conclusion":"failure","app":{"slug":"codemagic-ci-cd"}}]}' >"${WORK_DIR}/fake/checks.json"
run_target
assert_true "runs iOS when Codemagic already reported on this commit" contains "already reported an iOS result"

reset_fake
set_files 1 lib/a.dart
printf '{"check_runs":[{"name":"Ios Debug Build","conclusion":null,"status":"in_progress","app":{"slug":"codemagic-ci-cd"}}]}' >"${WORK_DIR}/fake/checks.json"
run_target
assert_true "runs iOS while a Codemagic iOS build is running" contains "already reported an iOS result"

reset_fake
set_files 1 lib/a.dart
printf '{"check_runs":[{"name":"Ios Debug Build","conclusion":"cancelled","app":{"slug":"codemagic-ci-cd"}}]}' >"${WORK_DIR}/fake/checks.json"
run_target
assert_true "a canceled Codemagic run does not block the skip" starts_with "skip:"

reset_fake
set_files 1 lib/a.dart
printf '{"check_runs":[{"name":"Ios Debug Build","conclusion":"success","app":{"slug":"github-actions"}}]}' >"${WORK_DIR}/fake/checks.json"
run_target
assert_true "a same-named check run from another app does not block the skip" starts_with "skip:"

# Classification against the real repository
for entry in $(cd "$REPO_ROOT" && git ls-tree --name-only HEAD); do
  [ -d "$REPO_ROOT/$entry" ] && entry="$entry/"
  run_target --classify "$entry"
  assert_true "classifies the top-level path $entry" bash -c "[ '$STDOUT_TEXT' != unknown ]"
done

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"

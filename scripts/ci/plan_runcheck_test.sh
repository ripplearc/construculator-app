#!/bin/bash
#
# Manual test harness for scripts/ci/plan_runcheck.sh (CA-1240).
#
# Follows the repo's bash test convention (see resolve_build_features_test.sh):
# no shell-test framework, non-zero exit if any case fails. curl is replaced by
# a fake GitHub on PATH:
#   .../commits/<sha>/check-runs  answers from $FAKE_DIR/runs_<sha>.json
#   .../pulls/<n>/commits         answers from $FAKE_DIR/commits.json
# A missing file makes the fake fail the way curl --fail-with-body does.
#
# Usage:
#   scripts/ci/plan_runcheck_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/plan_runcheck.sh"

FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/fake"

cat >"${WORK_DIR}/bin/curl" <<'EOF2'
#!/bin/bash
url=""
for arg in "$@"; do url="$arg"; done
echo "$url" >>"$FAKE_DIR/urls"
case "$url" in
  */commits/*/check-runs*)
    sha="${url#*/commits/}"
    body_file="$FAKE_DIR/runs_${sha%%/*}.json"
    ;;
  */pulls/*/commits*) body_file="$FAKE_DIR/commits.json" ;;
  *) echo "unexpected url $url" >&2; exit 2 ;;
esac
if [ ! -s "$body_file" ]; then
  echo '{"message":"Server Error"}'
  exit 22
fi
cat "$body_file"
EOF2
chmod +x "${WORK_DIR}/bin/curl"

reset_fake() { rm -f "${WORK_DIR}"/fake/*; }

# run_json <app> <name> <status> <conclusion|null> <build id>
run_json() {
  local conclusion="$4"
  [ "$conclusion" != "null" ] && conclusion="\"$conclusion\""
  printf '{"name":"%s","status":"%s","conclusion":%s,"external_id":"%s","details_url":"https://cm.test/build/%s","app":{"slug":"%s"}}' \
    "$2" "$3" "$conclusion" "$5" "$5" "$1"
}

# set_runs <sha> <run json>...
set_runs() {
  local sha="$1"
  shift
  local joined="" run
  for run in "$@"; do joined="${joined:+$joined,}$run"; done
  printf '{"check_runs":[%s]}' "$joined" >"${WORK_DIR}/fake/runs_${sha}.json"
}

# set_commits <sha>...   (oldest first)
set_commits() {
  local json="[" first=true sha
  for sha in "$@"; do
    $first || json="$json,"
    first=false
    json="$json{\"sha\":\"$sha\"}"
  done
  printf '%s]' "$json" >"${WORK_DIR}/fake/commits.json"
}

run_target() {
  rm -f "${WORK_DIR}/fake/urls"
  STDOUT_TEXT="$(
    cd "$WORK_DIR" &&
      PATH="${WORK_DIR}/bin:${PATH}" FAKE_DIR="${WORK_DIR}/fake" \
      GH_REPO="owner/repo" GITHUB_TOKEN="token" PR_NUMBER="7" HEAD_SHA="headsha0123456" \
      COMMENT_BODY="${COMMENT_BODY:-#RunCheck}" \
      "$TARGET" "$@" 2>"${WORK_DIR}/stderr"
  )"
  EXIT_CODE=$?
  STDERR_TEXT="$(cat "${WORK_DIR}/stderr")"
}

assert_true() {
  local description="$1"
  shift
  if "$@"; then
    echo "✅ PASS: ${description}"
  else
    echo "❌ FAIL: ${description}"
    echo "   stdout: ${STDOUT_TEXT}"
    echo "   stderr: ${STDERR_TEXT}"
    FAILURES=$((FAILURES + 1))
  fi
}

field_is() { [ "$(jq -c "$1" <<< "$STDOUT_TEXT")" = "$2" ]; }
comment_contains() { jq -r .comment <<< "$STDOUT_TEXT" | grep -Fq -- "$1"; }
stderr_contains() { echo "$STDERR_TEXT" | grep -Fq -- "$1"; }
asked_for() { grep -Fq -- "$1" "${WORK_DIR}/fake/urls"; }
did_not_ask_for() { ! grep -Fq -- "$1" "${WORK_DIR}/fake/urls"; }
asked_times() { [ "$(grep -Fc -- "$1" "${WORK_DIR}/fake/urls")" -eq "$2" ]; }
exit_code_is() { [ "$EXIT_CODE" -eq "$1" ]; }

CM=codemagic-ci-cd

reset_fake
set_runs headsha0123456
set_commits headsha0123456
run_target
assert_true "plans nothing for a commit with no results" field_is . '{"skip":[],"cancel":[],"comment":""}'
assert_true "exits 0" exit_code_is 0

set_runs headsha0123456 "$(run_json $CM 'Comprehensive Check' completed success b1)"
run_target
assert_true "skips a workflow that already passed on the head commit" field_is .skip '["comprehensive-check"]'
assert_true "names the check and its result in the comment" comment_contains "Comprehensive Check: success"
assert_true "links to the build" comment_contains "https://cm.test/build/b1"
assert_true "shows a short commit id" comment_contains "headsha"
assert_true "tells the reader how to run again" comment_contains "#RunCheck force"

set_runs headsha0123456 "$(run_json $CM 'Comprehensive Check' completed failure b1)"
run_target
assert_true "skips a workflow that already failed on the head commit" field_is .skip '["comprehensive-check"]'

set_runs headsha0123456 "$(run_json $CM 'Ios Debug Build' in_progress null b2)"
run_target
assert_true "skips a workflow that is still running" field_is .skip '["ios-debug-build"]'
assert_true "says it is still running" comment_contains "Ios Debug Build: still running"

set_runs headsha0123456 "$(run_json $CM 'Pre-check' queued null b3)"
run_target
assert_true "skips a workflow that is queued" field_is .skip '["pre-check"]'

set_runs headsha0123456 "$(run_json $CM 'Comprehensive Check' completed cancelled b1)"
run_target
assert_true "a canceled run is not a result" field_is .skip '[]'

set_runs headsha0123456 "$(run_json $CM 'Comprehensive Check' completed timed_out b1)"
run_target
assert_true "a timed-out run is not a result" field_is .skip '[]'

for conclusion in neutral stale skipped action_required; do
  set_runs headsha0123456 "$(run_json $CM 'Comprehensive Check' completed "$conclusion" b1)"
  run_target
  assert_true "a run that ended $conclusion is not a result" field_is .skip '[]'
done

set_runs headsha0123456 "$(run_json github-actions 'Comprehensive Check' completed success b1)"
run_target
assert_true "ignores a same-named check run from another app" field_is .skip '[]'

set_runs headsha0123456 "$(run_json $CM 'Comprehensive Check' completed cancelled b0)" "$(run_json $CM 'Comprehensive Check' completed success b1)"
run_target
assert_true "skips when any run on the commit finished, even after a canceled one" field_is .skip '["comprehensive-check"]'

set_runs headsha0123456 "$(run_json $CM 'Pre-check' completed success b4)" "$(run_json $CM 'Ios Debug Build' completed failure b5)"
run_target
assert_true "decides each workflow on its own result" field_is .skip '["pre-check","ios-debug-build"]'

run_target comprehensive-check
assert_true "only considers the workflows it is given" field_is .skip '[]'

run_target mystery-workflow
assert_true "never skips a workflow it does not know" field_is .skip '[]'

set_runs headsha0123456 "$(run_json $CM 'Comprehensive Check' completed success b1)"
COMMENT_BODY="#RunCheck force" run_target
assert_true "force starts a finished workflow again" field_is .skip '[]'

set_runs headsha0123456 "$(run_json $CM 'Comprehensive Check' in_progress null b1)"
COMMENT_BODY="#runcheck FORCE" run_target
assert_true "force never starts a second copy of a running workflow" field_is .skip '["comprehensive-check"]'

set_runs headsha0123456 "$(run_json $CM 'Comprehensive Check' completed success b1)"
COMMENT_BODY="#RunCheck forced" run_target
assert_true "does not read #RunCheck forced as the force word" field_is .skip '["comprehensive-check"]'

rm "${WORK_DIR}/fake/runs_headsha0123456.json"
run_target
assert_true "skips nothing when the head commit cannot be read" field_is .skip '[]'
assert_true "says it skips nothing" stderr_contains "Nothing is skipped"
assert_true "exits 0 when the head commit cannot be read" exit_code_is 0

printf 'not json' >"${WORK_DIR}/fake/runs_headsha0123456.json"
run_target
assert_true "skips nothing when the answer is not JSON" field_is .skip '[]'

reset_fake
set_runs headsha0123456
set_runs old1 "$(run_json $CM 'Comprehensive Check' in_progress null bOld1)"
set_runs old2 "$(run_json $CM 'Ios Debug Build' queued null bOld2)" "$(run_json $CM 'Pre-check' completed success bDone)"
set_runs old3 "$(run_json github-actions 'Comprehensive Check' in_progress null bOther)"
set_commits old1 old2 old3 headsha0123456
run_target
assert_true "cancels running and queued builds on older commits" field_is .cancel '["bOld1","bOld2"]'
assert_true "reads the head commit once, not again as an older commit" asked_times "commits/headsha0123456/check-runs" 1
assert_true "leaves finished builds alone" field_is '.cancel | index("bDone")' null
assert_true "leaves other apps' runs alone" field_is '.cancel | index("bOther")' null

reset_fake
set_runs headsha0123456 "$(run_json $CM 'Comprehensive Check' in_progress null bHead)"
set_runs old1 "$(run_json $CM 'Comprehensive Check' in_progress null bOld1)"
set_commits old1 headsha0123456
run_target
assert_true "never cancels the build on the head commit" field_is .cancel '["bOld1"]'

reset_fake
set_runs headsha0123456
shas=()
i=1
while [ "$i" -le 12 ]; do shas+=("c$i"); set_runs "c$i"; i=$((i + 1)); done
set_commits "${shas[@]}" headsha0123456
run_target
assert_true "checks only the 10 most recent older commits" did_not_ask_for "commits/c2/check-runs"
assert_true "still checks the newest older commit" asked_for "commits/c12/check-runs"
assert_true "checks the oldest of the 10" asked_for "commits/c3/check-runs"

reset_fake
set_runs headsha0123456
set_runs old2 "$(run_json $CM 'Comprehensive Check' in_progress null bOld2)"
set_commits old1 old2 headsha0123456
run_target
assert_true "keeps going when one older commit cannot be read" field_is .cancel '["bOld2"]'
assert_true "says which commit it could not read" stderr_contains "Could not read the check runs on old1"

reset_fake
set_runs headsha0123456 "$(run_json $CM 'Comprehensive Check' completed success b1)"
run_target
assert_true "cancels nothing when the commit list cannot be read" field_is .cancel '[]'
assert_true "still skips from the head commit's results" field_is .skip '["comprehensive-check"]'

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"

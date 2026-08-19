#!/bin/bash
#
# Appends one perf-run.json to the append-only perf-data branch.
#
# perf-data is an orphan branch: it shares no history with main, so the trend
# store grows without adding commits or files to the source tree.
#
# Usage:
#   scripts/perf/publish_perf_run.sh --run-file <perf-run.json> [--push]
#
# Publishing is a two-step split: this script owns the branch mechanics and
# delegates file placement and index rebuilding to publish_perf_run.dart, which
# is unit tested without needing a git remote.
#
set -euo pipefail

RUN_FILE=""
BRANCH="perf-data"
REMOTE="origin"
PUSH=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --run-file) RUN_FILE="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --push) PUSH=true; shift ;;
    *) echo "❌ Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$RUN_FILE" ]]; then
  echo "❌ --run-file is required" >&2
  exit 1
fi

if [[ ! -f "$RUN_FILE" ]]; then
  echo "❌ Run file not found: $RUN_FILE" >&2
  exit 1
fi

RUN_FILE_ABS="$(cd "$(dirname "$RUN_FILE")" && pwd)/$(basename "$RUN_FILE")"
WORKTREE="$(mktemp -d)"
cleanup() {
  git worktree remove --force "$WORKTREE" 2>/dev/null || rm -rf "$WORKTREE"
}
trap cleanup EXIT

git fetch "$REMOTE" "$BRANCH" 2>/dev/null || true

if git rev-parse --verify "$REMOTE/$BRANCH" >/dev/null 2>&1; then
  echo "📥 Checking out existing $BRANCH..."
  git worktree add --force -B "$BRANCH" "$WORKTREE" "$REMOTE/$BRANCH"
else
  # First ever run: start the branch with no history from main so the trend
  # store never carries a copy of the source tree.
  echo "🌱 Creating orphan $BRANCH..."
  git worktree add --force --detach "$WORKTREE" HEAD
  git -C "$WORKTREE" checkout --orphan "$BRANCH"
  git -C "$WORKTREE" rm -rq --cached . 2>/dev/null || true
  find "$WORKTREE" -mindepth 1 -maxdepth 1 -not -name .git -exec rm -rf {} +
fi

fvm dart run scripts/perf/publish_perf_run.dart \
  --run-file "$RUN_FILE_ABS" \
  --data-dir "$WORKTREE"

git -C "$WORKTREE" add -A
if git -C "$WORKTREE" diff --cached --quiet; then
  echo "ℹ️  Run already present, nothing to publish."
  exit 0
fi

git -C "$WORKTREE" commit -q -m "perf: record run from $(git rev-parse --short HEAD)"

if [[ "$PUSH" == true ]]; then
  git -C "$WORKTREE" push "$REMOTE" "$BRANCH"
  echo "✅ Published to $REMOTE/$BRANCH"
else
  echo "✅ Committed to local $BRANCH (pass --push to publish)"
fi

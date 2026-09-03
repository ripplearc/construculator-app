#!/bin/bash
#
# Copies one file into data/ on the gh-pages branch and commits it (optionally
# pushes). gh-pages is the store CA-978's dashboard reads from; this script is
# the generic append primitive any CI job in this repo can call.
#
# gh-pages is checked out into a throwaway git worktree, so this never touches
# the caller's own checkout or branch.
#
# Usage:
#   scripts/dashboard/publish_artifact.sh --file <path> --dest <rel-path-under-data> [--push]
#
set -euo pipefail

FILE=""
DEST=""
BRANCH="gh-pages"
REMOTE="origin"
PUSH=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --file) FILE="$2"; shift 2 ;;
    --dest) DEST="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --push) PUSH=true; shift ;;
    *) echo "❌ Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$FILE" || -z "$DEST" ]]; then
  echo "❌ --file and --dest are required" >&2
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "❌ File not found: $FILE" >&2
  exit 1
fi

FILE_ABS="$(cd "$(dirname "$FILE")" && pwd)/$(basename "$FILE")"
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
  # Safety net only: CA-988 seeds gh-pages once up front, so this branch is
  # expected to already exist. Falling back to an orphan checkout keeps the
  # script usable if the branch is ever recreated from scratch.
  echo "🌱 $BRANCH not found on $REMOTE, creating orphan..."
  git worktree add --force --detach "$WORKTREE" HEAD
  git -C "$WORKTREE" checkout --orphan "$BRANCH"
  git -C "$WORKTREE" rm -rq --cached . 2>/dev/null || true
  find "$WORKTREE" -mindepth 1 -maxdepth 1 -not -name .git -exec rm -rf {} +
  mkdir -p "$WORKTREE/data"
fi

DEST_ABS="$WORKTREE/data/$DEST"
mkdir -p "$(dirname "$DEST_ABS")"
cp "$FILE_ABS" "$DEST_ABS"

git -C "$WORKTREE" add -A
if git -C "$WORKTREE" diff --cached --quiet; then
  echo "ℹ️  $DEST already present and unchanged, nothing to publish."
  exit 0
fi

git -C "$WORKTREE" commit -q -m "dashboard: publish data/$DEST"

if [[ "$PUSH" == true ]]; then
  # gh-pages can move under us between our fetch and our push when another CI
  # run publishes concurrently. Retry a few times, rebasing our lone commit
  # onto the updated branch each time, before giving up.
  MAX_PUSH_ATTEMPTS=3
  attempt=1
  while true; do
    if git -C "$WORKTREE" push "$REMOTE" "$BRANCH"; then
      echo "✅ Published to $REMOTE/$BRANCH"
      break
    fi
    if [[ "$attempt" -ge "$MAX_PUSH_ATTEMPTS" ]]; then
      echo "❌ Push to $REMOTE/$BRANCH rejected after $MAX_PUSH_ATTEMPTS attempts" >&2
      exit 1
    fi
    echo "🔄 Push rejected, rebasing onto $REMOTE/$BRANCH and retrying (attempt $attempt/$MAX_PUSH_ATTEMPTS)..."
    git -C "$WORKTREE" fetch "$REMOTE" "$BRANCH"
    git -C "$WORKTREE" rebase "$REMOTE/$BRANCH"
    attempt=$((attempt + 1))
  done
else
  echo "✅ Committed to local $BRANCH (pass --push to publish)"
fi

#!/bin/bash
#
# Builds the trend dashboard from both raw stores and publishes the rendered
# page to the gh-pages data store.
#
# The raw stores (perf-data, e2e-data) are the archives of every run ever
# recorded; gh-pages holds only the rendered page. This script is the one place
# that crosses between them, and it reads the raw stores without ever writing
# to them.
#
# Usage:
#   scripts/dashboard/build_and_publish_dashboard.sh [--push]
#
set -euo pipefail

REMOTE="origin"
PERF_BRANCH="perf-data"
E2E_BRANCH="e2e-data"
DEST="dashboard/index.html"
OUTPUT="build/dashboard/index.html"
PUSH=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --push) PUSH=true; shift ;;
    --dest) DEST="$2"; shift 2 ;;
    *) echo "❌ Unknown option: $1. Usage: build_and_publish_dashboard.sh [--push]" >&2; exit 1 ;;
  esac
done

WORKTREES=()
cleanup() {
  for worktree in "${WORKTREES[@]:-}"; do
    [[ -n "$worktree" ]] || continue
    git worktree remove --force "$worktree" 2>/dev/null || rm -rf "$worktree"
  done
}
trap cleanup EXIT

# Checks a store branch out read-only, setting STORE_DIR to the checkout.
#
# The result is returned via a global rather than stdout because the cleanup
# trap needs the directory recorded in WORKTREES, and a command substitution
# would run the append in a subshell that discards it.
#
# A branch that does not exist yet yields an empty directory, which the builder
# renders as "nothing recorded yet" rather than failing — the dashboard has to
# work before the first run lands.
STORE_DIR=""
checkout_store() {
  local branch="$1"
  STORE_DIR="$(mktemp -d)"
  WORKTREES+=("$STORE_DIR")

  git fetch "$REMOTE" "$branch" 2>/dev/null || true
  if git rev-parse --verify "$REMOTE/$branch" >/dev/null 2>&1; then
    git worktree add --force --detach "$STORE_DIR" "$REMOTE/$branch" >/dev/null
    echo "📥 Read $branch"
  else
    echo "ℹ️  $branch does not exist yet; rendering it as empty"
  fi
}

checkout_store "$PERF_BRANCH"
PERF_DIR="$STORE_DIR"
checkout_store "$E2E_BRANCH"
E2E_DIR="$STORE_DIR"

# The perf harness runs on an fvm-provisioned runner; the E2E and Pages
# workflows provision Flutter directly, which puts `dart` on PATH without fvm.
if command -v fvm >/dev/null 2>&1; then
  DART=(fvm dart)
else
  DART=(dart)
fi

"${DART[@]}" run scripts/dashboard/build_dashboard.dart \
  --perf-store "$PERF_DIR" \
  --e2e-store "$E2E_DIR" \
  --output "$OUTPUT"

PUBLISH_ARGS=(--file "$OUTPUT" --dest "$DEST")
if [[ "$PUSH" == true ]]; then
  PUBLISH_ARGS+=(--push)
fi

bash scripts/dashboard/publish_artifact.sh "${PUBLISH_ARGS[@]}"

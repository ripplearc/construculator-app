---
name: cost-codemagic
description: Audits CodeMagic CI cost overhead by finding PRs where people manually re-triggered CI via `#RunCheck`/`#runcheck` PR comments, and ranks both the worst PRs and the authors most responsible. Run this monthly, or whenever someone asks about CodeMagic/CI spend, build costs, why the CI bill went up, who's re-running checks a lot, or wants a "cost report" / "CI cost audit" for a ripplearc repo. Also trigger on `/cost-codemagic`. Default window is the past calendar month and default repo is ripplearc/construculator-app, but both are overridable — e.g. "/cost-codemagic 2026-07", "/cost-codemagic last-quarter", or "/cost-codemagic ripplearc/coreui".
---

# CodeMagic cost audit (`#RunCheck` triggers)

## Why this exists

CodeMagic bills by CI minutes, and this repo's pipeline (`codemagic.yaml`) can be re-triggered manually by posting a `#RunCheck` (or `#runcheck` — case-insensitive) comment on a PR (see `.github/workflows/run_c_check.yml` and `docs/Testing/CI-Scripts.md`). Every one of those comments fires a **full paid pipeline run** — `pre-check` and `comprehensive-check`, some of it on `mac_mini_m2` instances, which are billed at a much higher per-minute rate than the `linux_x2` instances used elsewhere. Push-triggered CI is unavoidable overhead; `#RunCheck` spam is discretionary and is the one lever a contributor directly controls. This skill finds who's pulling that lever a lot without addressing the root cause (long stacked-PR chains that need repeated rebuild-and-recheck, flaky branches left open too long, or just habitually re-running instead of investigating a failure).

This is a **PR-comment proxy for CI spend**, not a read of CodeMagic's own billing dashboard (this skill has no CodeMagic API access). It's directionally reliable and cheap to compute from GitHub alone, but if the user wants the actual dollar figure, point them at their CodeMagic usage page for the same window — this skill tells you *where* to look, not the invoice total.

## Inputs and defaults

- **Window**: default is the past full calendar month (if today is within month M, the window is the entirety of month M-1). Accept overrides: a specific month (`2026-07`), a named range (`last-quarter`, `last-30-days`), or an explicit date range. Always state the resolved window (start/end dates) at the top of the report so there's no ambiguity about what was measured.
- **Repo**: default `ripplearc/construculator-app`. Accept an override to point at any other `owner/repo` the user names (e.g. `ripplearc/coreui`). If the user says "all ripplearc repos," run the whole procedure once per repo and either combine into one report or present per-repo sections — ask which they'd prefer only if it's not obvious from context.
- **Top-N**: default 20 PRs in the leaderboard table. Accept an override (e.g. "/cost-codemagic top 10").

## Procedure

### 1. Find candidate PRs

Use `mcp__github__search_issues` with a query like:

```
repo:<owner>/<repo> is:pr "#RunCheck" in:comments
```

Note this searches for the literal substring across the PR's comments and returns a `comments` field — **that field is the PR's total comment count, not a count of `#RunCheck` occurrences.** It's a cheap way to rank candidates before doing the expensive part, nothing more. Sort by `comments` descending (`sort: "comments", order: "desc"`) and pull enough pages to cover every PR whose `created_at` or `updated_at` could plausibly overlap the window — comments can land on a PR opened well before the window, so don't filter by the PR's own dates at this stage, only use them to prioritize.

If `total_count` is large, deep-checking every single one isn't worth it — the `#RunCheck` comments concentrate heavily on a small number of PRs (in past runs of this audit, the top 10-15 candidates by comment count captured essentially all of the actual repeat-trigger activity). Deep-check the **top 40-60 candidates** by comment count, and say in the report how many candidates you checked out of the total match count so the reader knows this is a bounded sample, not exhaustive. If the resulting leaderboard looks thin (e.g., fewer than Top-N PRs found with 2+ triggers), widen the candidate pool before concluding there's nothing more to find.

### 2. Verify each candidate: count real `#RunCheck` occurrences in-window

For each candidate PR, call `mcp__github__pull_request_read` with `method: "get_comments"` (`perPage: 100`, paginate if a PR somehow has more). For each comment:

- Match if the comment body, trimmed of whitespace, case-insensitively equals or starts with `#runcheck` (people occasionally add trailing whitespace or a stray newline; the token itself is always what triggers the workflow, per `run_c_check.yml`'s `contains(github.event.comment.body, '#RunCheck')` check — so `contains`, not exact-equals, is the correct match).
- Only count matches whose `created_at` falls inside the resolved window. A PR opened two months ago with a fresh `#RunCheck` comment this month still counts — the trigger cost was incurred this month, regardless of when the PR itself was opened.

Keep a running count per PR. Discard PRs with a 0 in-window count (they matched the search but the actual `#RunCheck` activity fell outside the window).

### 3. Get each PR's author

Call `mcp__github__pull_request_read` with `method: "get"` for every PR that has a non-zero in-window count, and record `user.login` (the PR author) plus the title and `html_url`. The author matters more than whoever physically posted the `#RunCheck` comment — a reviewer or bot occasionally posts on someone else's PR, but the PR's author is the one who left CI needing repeated re-runs (unresolved feedback, an unrebuilt branch, a flaky change), so the leaderboard is about authorship, not comment authorship. It's fine — worth a one-line footnote — if the same person happens to be both.

### 4. Build the report

Produce two things:

**A. Top-N PR table**, ranked by in-window `#RunCheck` count, descending:

| Rank | PR | Title | Author | `#RunCheck` count (window) | Link |
|---|---|---|---|---|---|

**B. Author leaderboard** — sum each author's in-window `#RunCheck` count across *all* their PRs found in step 2 (not just the ones that made the Top-N table), sorted descending:

| Rank | Author | Total `#RunCheck` triggers (window) | # PRs involved | Top PR |

The author leaderboard is the more important artifact for a monthly review: a single outlier PR is a one-off (a rough upgrade, a flaky migration), but an author who accumulates triggers across many separate PRs is the "not paying attention" signal the user is after — someone habitually re-running CI instead of fixing the underlying cause before pushing.

### 5. Add interpretation, not just numbers

Skim the actual comment bodies you already fetched (not just the `#RunCheck` lines — the surrounding review/gate comments) and call out the pattern behind the top few entries, because the same raw count can mean very different things:

- **A stacked-PR chain** (titles like "CA-XXX (N/M): ...", a "Stack: k/n" line in the PR description, or several sibling PRs all spiking in the same window): a review finding upstream forces re-verification cascades down every dependent PR, and a full-stack rebase invalidates prior gate results across all of them at once. This is a process/tooling problem more than an individual-carelessness problem — flag it as such rather than just blaming the author.
- **A single long-lived or flaky PR**: a framework/dependency upgrade, a merge-conflict-prone branch left open a long time, or a genuinely flaky test suite. Re-runs here are more defensible — note it, but don't lump it in with habitual spam.
- **An author with a wide, flat spread** across many unrelated PRs (1-3 triggers each, but many of them): this is the "not paying attention" case — no single PR looks alarming, but the aggregate is real, recurring, avoidable cost. This is what the author leaderboard is for; call it out explicitly if you see it.

### 6. Close with a recommendation, not just a diagnosis

End the report with 2-4 concrete, low-friction suggestions tied to what you actually found — e.g., "rebase a stack once and let CI run at the tip rather than `#RunCheck`-ing every sibling," "investigate before re-running — N% of triggers here followed no visible code change," or "this month's spend was concentrated in one stacked feature; consider it a one-time cost of that project's shape rather than a trend." Keep it short. The goal is a report someone can act on in the next standup, not a lecture.

## Output format

Lead with the resolved window and repo, then the two tables, then interpretation, then recommendations. If the user didn't ask for a saved file, a chat-native report is fine — use the Artifact tool only if the user asks for something shareable/dashboard-like. Don't pad the report with the full raw comment data; link PR numbers so the reader can go look themselves.

## Known limitations to disclose in the report

State these plainly rather than letting the reader assume more precision than exists:
- This measures re-trigger *comments*, not actual CodeMagic minutes/dollars — it's a strong proxy, not the invoice.
- Only the top N candidates by total-comment-count were deep-checked (state how many out of how many matched); a PR with a very chatty review thread but low comment-count *could* theoretically be missed if it falls outside that cutoff, though in practice `#RunCheck` activity strongly correlates with comment volume.
- Counts only comments literally containing `#RunCheck`/`#runcheck`; it doesn't know about pushes to the PR branch that triggered CI automatically (those are the "unavoidable" baseline cost this skill is deliberately excluding).

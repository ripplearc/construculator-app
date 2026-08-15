---
name: analytics-event
description: |
  Governs the PostHog analytics event taxonomy in docs/Logging/PostHog-Event-Tracking.md — the
  single source of truth for event names, categories, owners, and status. Adds, updates, lists,
  validates, and deprecates events against the `{object}_{action}` snake_case naming convention
  and PII data-safety rules so the catalog stays consistent as the app scales.

  Trigger: "add an analytics event", "add a posthog event for X", "track event X", "validate
  event name X", "list analytics events", "list events for <category>", "deprecate event X".
disable-model-invocation: false
allowed-tools: Read Edit Grep
---

# Analytics Event Skill

**Verb:** Govern the PostHog event taxonomy.

Single source of truth: `docs/Logging/PostHog-Event-Tracking.md`. Always read the full file
before any operation below — never edit from a stale partial view — and re-read it after
editing to confirm the write landed correctly.

## Input

| Field | Required | Notes |
|-------|----------|-------|
| `operation` | yes | `add-event` \| `update-event` \| `list-events` \| `validate-event` \| `deprecate-event` |
| `name` | for add/update/validate/deprecate | proposed or existing event name |
| `category` | for add-event | one of the `## Event Categories` headings, or a new one |
| `properties` | optional | comma-separated property names the event carries |
| `owner` | optional | team or handle responsible for the event |
| `migration_note` | for deprecate-event | what replaces this event and why |

## Naming Convention

Pattern: `{object}_{action}` in `snake_case` — e.g. `estimation_created`, `project_switched`.

A name is valid only if **all** of the following hold:
- Matches `^[a-z][a-z0-9]*(_[a-z0-9]+)+$` (lowercase snake_case, 2+ segments — an object and at
  least one action)
- Not a bare verb (`created`, `clicked`) — must be prefixed by the object it happened to
- Not already present in the registry (case-insensitive), under any category

## PII / Data Safety Rule

Reject any event name or property whose tokens suggest raw PII, per the registry's Data Safety
Rules table: `email`, `phone`, `ssn`, `address`, `password`, `token`, `card`, `full_name` (or
similar free-text identity fields). IDs, enums, booleans, counters, and durations are fine.

## Operations

### `list-events`
Read the registry, filter `## Event Categories` bullets by `category` and/or `status` (active =
no `status: deprecated` annotation; deprecated = listed under `## Deprecated Events`). Return a
markdown table: Event | Category | Owner | Properties | Status.

### `validate-event`
Check `name` against the Naming Convention and PII rule above. Return `{ valid: bool, reasons:
[...] }` — list every failed check, not just the first.

### `add-event`
1. Run `validate-event` on `name` first — refuse to add on any failure and report why.
2. If `category` doesn't exist as a `###` heading under `## Event Categories`, ask the user
   whether to create it — never invent a new category silently.
3. Append the bullet under the target category, alphabetically among existing entries, with
   inline metadata if `owner`/`properties` were given (see `## Event Metadata` in the registry
   for the format).
4. Save and echo the new line back to the user.

### `update-event`
Find the bullet by exact name match. Update its category (move the bullet), properties, or
owner in place. Re-run `validate-event` if the name itself is changing.

### `deprecate-event`
1. Locate the bullet under its current category and remove it from there.
2. Append it under `## Deprecated Events` as `~~name~~` with today's date and `migration_note`.
3. If no `migration_note` was given, ask for one before proceeding — a deprecation with no
   migration path leaves instrumentation dangling.

## Output

- `add-event` / `update-event` / `deprecate-event`: confirm the exact line(s) changed and their
  location in the file.
- `list-events`: the filtered markdown table.
- `validate-event`: pass/fail plus every reason for failure.

## Examples

**Add an event**
```
operation: add-event
name: estimation_exported_as_pdf
category: Estimation
owner: "@estimation-team"
properties: estimation_id, format
```
→ Validates the name (passes), appends under `### Estimation`:
`- \`estimation_exported_as_pdf\` — owner: \`@estimation-team\`; properties: estimation_id, format`

**Validate a bad name**
```
operation: validate-event
name: userEmailCaptured
```
→ `{ valid: false, reasons: ["not snake_case (found camelCase)", "property/name token 'Email' suggests PII"] }`

## References

- Registry: `docs/Logging/PostHog-Event-Tracking.md`
- Naming/PII source of truth: same file, `## Event Naming Convention` and `## Data Safety Rules` sections
- Integration guide: `docs/Logging/Posthog-Integration.md` § Event Tracking Strategy

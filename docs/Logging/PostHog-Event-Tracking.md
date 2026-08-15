# PostHog — Event Tracking Reference

> Extracted from the [PostHog Integration Guide](Posthog-Integration.md) per reviewer request.
> These are **examples and samples**, not a finalized plan of record. Events must be reviewed and approved during implementation.
>
> Governed by the [`analytics-event`](../../skills/analytics-event/SKILL.md) skill ([CA-695](https://ripplearc.youtrack.cloud/issue/CA-695)) — use it to add, update, list, validate, or deprecate events rather than editing this file by hand.

---

## Event Naming Convention

**Pattern:** `{object}_{action}` in `snake_case` — e.g., `estimation_created`, `project_switched`

## Event Metadata

An event may carry optional inline metadata after a ` — ` separator: `owner` and `properties`.
Events with no metadata are undocumented examples pending a real owner. Example:

- `estimation_created` — owner: `@estimation-team`; properties: estimation_id, project_id

---

## Event Categories

### Authentication
- `user_registered`
- `user_registration_failed` — properties: `reason` (typed, see Data Safety Rules; derived from `AuthErrorType`, never the raw exception)
- `user_logged_in`
- `user_login_failed` — properties: `reason` (typed, see Data Safety Rules; derived from `AuthErrorType`, never the raw exception)
- `user_logged_out`
- `user_password_reset`
- `otp_verified`

### Estimation
- `estimation_created`
- `estimation_viewed`
- `estimation_renamed`
- `estimation_deleted`
- `estimation_locked` / `estimation_unlocked`
- `estimation_duplicated`
- `estimation_exported`

### Project
- `project_created`
- `project_switched`
- `project_viewed`
- `project_archived` / `project_restored` / `project_deleted`

### Search *(future — see [Analytics Future Features](Analytics-Future-Features.md))*
- `search_performed`
- `search_result_clicked`
- `global_search_used`

### File *(future — see [Analytics Future Features](Analytics-Future-Features.md))*
- `file_uploaded` / `file_downloaded` / `file_deleted`
- `attachment_added`

### Collaboration
- `estimation_shared`
- `user_invited`
- `comment_added`

### Navigation
- `screen_viewed`
- `tab_switched`
- `navigation_clicked`

### Performance & Reliability
- `screen_loaded`
- `error_occurred`
- `api_call_completed`

---

## Deprecated Events

_None yet._ When an event is retired, move its bullet here with a migration note:

- `~~old_event_name~~` — deprecated `<date>`; migrated to `new_event_name`. `<reason>`

---

## Data Safety Rules (Required)

Keep event cardinality bounded — avoid unbounded strings in properties used as breakdown dimensions.

| Property Type | Allowed | Forbidden |
|--------------|---------|-----------|
| Event props | IDs, enums, booleans, counters, duration ms | Email, phone, raw free text with PII, tokens |
| User props | Plan type, role, company tier, account age bucket | Passwords, card data, SSN |
| Group props | Project status, size bucket | Free-form notes, confidential doc names |

---

## Standard Properties

Attached automatically to every event by `AnalyticsRepositoryImpl.track()` — callers never set these themselves:

```dart
{
  'app_version': '1.0.0',      // resolved once at bootstrap via package_info_plus
  'platform': 'ios',           // derived from defaultTargetPlatform
  'screen_name': '/estimation/details', // from the shared CurrentScreenTracker,
                                         // updated by AnalyticsNavigatorObserver
                                         // on every navigation; null before the
                                         // first navigation
}
```

Event-specific properties passed to `track()` take precedence over these on key collision.

> Do **not** include a client-side `timestamp`. PostHog assigns server-side timestamps — injecting `DateTime.now()` causes clock-skew bugs and inconsistent analytics across timezones.

> **TODO [CA-696](https://ripplearc.youtrack.cloud/issue/CA-696):** Design a `session_id` to correlate client-side events with backend service logs for cross-system debugging.

---

## Sample Event Schema

How a fully-formed event looks when received by PostHog (use Live Events view to validate):

```json
{
  "event": "estimation_created",
  "properties": {
    "estimation_id": "550e8400-e29b-41d4-a716-446655440000",
    "estimation_name": "Kitchen Remodel",
    "project_id": "660e8400-e29b-41d4-a716-446655440000",
    "total_cost": 15000.50,
    "item_count": 25,
    "is_locked": false,
    "creation_method": "manual",
    "$groups": {
      "project": "660e8400-e29b-41d4-a716-446655440000"
    }
  },
  "timestamp": "2026-03-23T10:30:00Z",
  "distinct_id": "user-123",
  "$set": {
    "plan_type": "premium"
  }
}
```

> `timestamp` is **server-assigned by PostHog** — do NOT set it from the client.
> `$groups` maps group types to their keys. The original `$group_project` notation used in earlier drafts was incorrect.

# CA-XXX: [Feature Name]

## Why
One sentence: what user problem does this solve? Cite the YouTrack issue or the conversation that motivated it.

## Scope
### In scope
- <item>
### Out of scope (explicit)
- <item>

## Figma
- Idle state: [node-id]
- Result state: [node-id]
- Error state: [node-id]

(Omit this section if the feature has no visual surface.)

## Surfaces touched
- Files / feature slices / BLoCs / usecases / repositories / domain entities / Supabase tables / PowerSync queries this change reaches.

## Interfaces
Events:
- <EventName>(<params>)
States:
- <StateName>(<fields>)
Usecase / repository signatures:
- <method>(<params>) -> Either<Failure, T>
Supabase request / response shapes, widget props:
- <shape>
Computation rules:
- <rule>
Side effects: none / <describe>

## UX flow
- Screen-by-screen for UI; event -> state transitions for BLoC.

## State management
- Which BLoC(s) own this state; event -> state transitions; stream disposal path; broadcast vs. single-listener.

## PowerSync / Supabase split
- Which reads use PowerSync watches vs. direct Supabase calls; which mutations go via Supabase.

## CoreUI Components
- <ComponentName> from ripplearc_coreui

## RBAC / auth
- Which roles can trigger which events; is the route guarded by AuthGuard().

## Platform considerations
- iOS / Android divergence, if any.

## Edge Cases + Failure Modes
- What the user sees when each thing breaks; what Either<Failure, T> returns on each error path. Cover network errors, unauthenticated users, empty state, partial saves, stale data, retries, offline / PowerSync edge cases.

## Test Contract (95% gate)
Scenarios the test suite must assert (unit, BLoC, widget, integration_test, manual simulator steps):
1. <scenario>

## Out-of-scope follow-ups
- Noted, not built.

## Dependencies
- Depends on: CA-XXX (what it needs)
- Blocks: CA-YYY (what depends on it)

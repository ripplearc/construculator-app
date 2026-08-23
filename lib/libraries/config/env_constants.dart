const String devEnv = 'dev';
const String qaEnv = 'qa';
const String prodEnv = 'prod';

const String devReadableName = 'Development';
const String qaReadableName = 'QA';
const String prodReadableName = 'Production';

const String devAlias = 'Fishfood';
const String qaAlias = 'Dogfood';
const String prodAlias = '';

const String sentryDsnKey = 'SENTRY_DSN';

/// Single kill switch for PostHog (analytics and feature flags alike) —
/// no separate `POSTHOG_ENABLED` flag exists.
const String analyticsEnabledKey = 'ANALYTICS_ENABLED';

const String posthogApiKeyKey = 'POSTHOG_API_KEY';
const String posthogHostKey = 'POSTHOG_HOST';
const String posthogDebugKey = 'POSTHOG_DEBUG';

/// Env key controlling whether the consent gate's route guard is registered
/// on the shell (see `ShellModule._shellGuards`), and whether signup records
/// an initial acceptance (see `CreateAccountBloc._onSubmitted`).
///
/// Off until every precondition below holds, not just the one this comment
/// used to name:
/// - a persistent local consent store lands (CA-971) -- with the current
///   in-memory stand-in and this on, a user would be re-prompted on every
///   cold start, and any device that has not synced would be blocked
///   outright;
/// - the consent-write path reaches the server, not just local storage --
///   `ConsentRecorder` has no route to `RemoteConsentDataSource` today, so
///   even a durable local store would produce no attributable record;
/// - the parse-boundary fix (CA-963/CA-964, #539/#543) has landed -- a
///   corrupt published-version row must not resolve as "nothing required";
/// - the watch-stream subscription race fix (#542/#554) has landed;
/// - the UI lockout cluster (#547-#550: reachable terms/privacy links, a
///   scroll fallback at large text scale, a golden for every gate state) has
///   landed -- none of that is behind this flag, so it ships regardless, but
///   it must ship *before* this flag ever does.
///
/// Everything below the guard ships and is tested regardless of this flag.
const String consentGateEnabledKey = 'CONSENT_GATE_ENABLED';

enum Environment { dev, qa, prod }

const Duration debounceTime = Duration(milliseconds: 300);

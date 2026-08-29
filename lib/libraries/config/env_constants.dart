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

/// Env key opting this build into the consent gate: the route guard on the
/// shell (`ShellModule._shellGuards`) and the initial acceptance signup
/// records (`CreateAccountBloc._onSubmitted`).
///
/// Necessary but not sufficient, and deliberately so. `consentGateEnabled`
/// in `consent_gate_readiness.dart` ands this with `consentPersistenceReady`,
/// a compile-time const that is false until CA-971 lands both a durable local
/// store and a consent-write path that reaches the server. Setting this key
/// `true` in any `.env` does nothing on its own -- a gate that collects an
/// acceptance it cannot durably record must not be one config edit away.
///
/// Still to land before flipping the const, none of it behind this flag:
/// - the parse-boundary fix (CA-963/CA-964, #539/#543) -- a corrupt
///   published-version row must not resolve as "nothing required";
/// - the watch-stream subscription race fix (#542/#554);
/// - the UI lockout cluster (#547-#550: reachable terms/privacy links, a
///   scroll fallback at large text scale, a golden for every gate state).
///
/// Everything below the guard ships and is tested regardless of this flag.
const String consentGateEnabledKey = 'CONSENT_GATE_ENABLED';

enum Environment { dev, qa, prod }

const Duration debounceTime = Duration(milliseconds: 300);

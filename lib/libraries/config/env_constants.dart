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

/// Env key controlling whether [ConsentGuard] is registered on the shell.
///
/// Off until CA-971 provides a persistent local consent store. With the
/// in-memory stand-in live and this on, a user would be re-prompted on every
/// cold start, and any device that has not synced would be blocked outright.
/// Everything below the guard ships and is tested regardless of this flag.
const String consentGateEnabledKey = 'CONSENT_GATE_ENABLED';

enum Environment { dev, qa, prod }

const Duration debounceTime = Duration(milliseconds: 300);

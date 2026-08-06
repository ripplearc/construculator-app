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

const String posthogApiKeyKey = 'POSTHOG_API_KEY';
const String posthogHostKey = 'POSTHOG_HOST';
const String posthogDebugKey = 'POSTHOG_DEBUG';

enum Environment { dev, qa, prod }

const Duration debounceTime = Duration(milliseconds: 300);

#!/bin/bash
#
# Codemagic Pre-Build Script: Generate Environment File
#
# This script generates the appropriate .env file for the current build environment
# using environment variables from Codemagic environment groups.
#
# Required environment variables (set in Codemagic environment groups):
#   - ENVIRONMENT: The environment name (dev, qa, prod)
#   - SENTRY_DSN: The Sentry Data Source Name for error tracking
#   - SUPABASE_URL: The Supabase project URL
#   - SUPABASE_ANON_KEY: The Supabase anonymous/public key
#   - API_URL: The API base URL
#   - POSTHOG_API_KEY: The PostHog project API key (dev only for now)
#   - POSTHOG_HOST: The PostHog ingestion host (dev only for now)
#
# Usage:
#   This script is automatically run by Codemagic before the build.
#   It should be added to the "Pre-build script" section of your workflow.
#

set -euo pipefail

# Validate required environment variables
if [ -z "${ENVIRONMENT:-}" ]; then
  echo "❌ ERROR: ENVIRONMENT variable is not set"
  exit 1
fi

if [ -z "${SENTRY_DSN:-}" ]; then
  echo "⚠️  WARNING: SENTRY_DSN is not set (Sentry will be disabled)"
fi

if [ -z "${POSTHOG_API_KEY:-}" ]; then
  echo "⚠️  WARNING: POSTHOG_API_KEY is not set (PostHog will be disabled)"
fi

if [ -z "${POSTHOG_HOST:-}" ]; then
  echo "⚠️  WARNING: POSTHOG_HOST is not set (PostHog will be disabled)"
fi

# Set default values for optional variables
APP_NAME="${APP_NAME:-Construculator}"
API_URL="${API_URL:-}"
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
DEBUG_MODE="${DEBUG_MODE:-false}"
ANALYTICS_ENABLED="${ANALYTICS_ENABLED:-false}"
SENTRY_DSN="${SENTRY_DSN:-}"
POSTHOG_API_KEY="${POSTHOG_API_KEY:-}"
POSTHOG_HOST="${POSTHOG_HOST:-}"
POSTHOG_DEBUG="${POSTHOG_DEBUG:-false}"

# Determine environment-specific values
case "${ENVIRONMENT}" in
  dev)
    ENV_FILE="assets/env/.env.dev"
    DEBUG_MODE="true"
    ANALYTICS_ENABLED="true"
    POSTHOG_DEBUG="true"
    ;;
  qa)
    ENV_FILE="assets/env/.env.qa"
    DEBUG_MODE="false"
    ANALYTICS_ENABLED="false"
    POSTHOG_DEBUG="false"
    ;;
  prod)
    ENV_FILE="assets/env/.env.prod"
    DEBUG_MODE="false"
    ANALYTICS_ENABLED="false"
    POSTHOG_DEBUG="false"
    ;;
  perf)
    # Writes .env.dev because AppConfigImpl resolves Environment.dev to that
    # file and the Environment enum has no perf member. The performance harness
    # therefore builds with --dart-define=ENVIRONMENT=dev and relies on this
    # case having already stripped the telemetry out of the file it loads.
    #
    # Telemetry is disabled so that network calls and event batching do not
    # perturb the measurements or publish lab runs as if they were field data.
    ENV_FILE="assets/env/.env.dev"
    DEBUG_MODE="false"
    ANALYTICS_ENABLED="false"
    SENTRY_DSN=""
    POSTHOG_DEBUG="false"
    ;;
  *)
    echo "❌ ERROR: Invalid ENVIRONMENT value: ${ENVIRONMENT}"
    echo "   Valid values: dev, qa, prod, perf"
    exit 1
    ;;
esac

# Create the env file
echo "📝 Generating ${ENV_FILE} for environment: ${ENVIRONMENT}"

# Ensure directory exists
mkdir -p "$(dirname "${ENV_FILE}")"

cat > "${ENV_FILE}" <<EOF
APP_ENV="${ENVIRONMENT}"
APP_NAME="${APP_NAME}"
API_URL="${API_URL}"
SUPABASE_URL="${SUPABASE_URL}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"
DEBUG_MODE="${DEBUG_MODE}"
ANALYTICS_ENABLED="${ANALYTICS_ENABLED}"
SENTRY_DSN="${SENTRY_DSN}"
POSTHOG_API_KEY="${POSTHOG_API_KEY}"
POSTHOG_HOST="${POSTHOG_HOST}"
POSTHOG_DEBUG="${POSTHOG_DEBUG}"
EOF

echo "✅ Environment file created successfully: ${ENV_FILE}"
echo ""
echo "📋 Configuration:"
echo "   Environment: ${ENVIRONMENT}"
echo "   Debug Mode: ${DEBUG_MODE}"
echo "   Analytics: ${ANALYTICS_ENABLED}"
echo "   Sentry: $([ -n "${SENTRY_DSN}" ] && echo "Enabled" || echo "Disabled")"
echo "   PostHog: $([ -n "${POSTHOG_API_KEY}" ] && echo "Enabled" || echo "Disabled")"
echo ""

# Verify the file was created
if [ ! -f "${ENV_FILE}" ]; then
  echo "❌ ERROR: Failed to create ${ENV_FILE}"
  exit 1
fi

echo "✅ Pre-build script completed successfully"

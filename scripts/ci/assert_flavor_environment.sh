#!/bin/bash
#
# Assert Flavor/Environment Pairing (CA-926)
#
# `--flavor` (Android product flavor) and `--dart-define=ENVIRONMENT=` are
# two separate build inputs that must always agree, or the build ships a
# binary branded for one environment while pointed at another's backend
# (e.g. a prod-branded binary talking to the dev backend).
#
# The expected pairing mirrors the display-alias mapping already declared in
# lib/libraries/config/env_constants.dart (devAlias='Fishfood',
# qaAlias='Dogfood', prodAlias=''). That mapping is Dart, read at runtime
# from the generated .env file, so it cannot be imported here directly --
# this table is a bash-side mirror of the same convention. If a flavor or
# environment is ever added/renamed in either place, update both.
#
# Usage:
#   scripts/ci/assert_flavor_environment.sh <flavor> <environment>
#
# Exits 0 when the pair matches; exits non-zero with a specific message on
# a mismatch or on an unrecognized flavor/environment value.

set -euo pipefail

FLAVOR="${1:-}"
ENVIRONMENT="${2:-}"

if [ -z "$FLAVOR" ] || [ -z "$ENVIRONMENT" ]; then
  echo "❌ ERROR: Usage: $0 <flavor> <environment>"
  exit 1
fi

# Mirrors lib/libraries/config/env_constants.dart's alias mapping.
case "$FLAVOR" in
  fishfood) EXPECTED_ENVIRONMENT="dev" ;;
  dogfood) EXPECTED_ENVIRONMENT="qa" ;;
  prod) EXPECTED_ENVIRONMENT="prod" ;;
  *)
    echo "❌ ERROR: Unknown flavor '${FLAVOR}'"
    echo "   Known flavors: fishfood, dogfood, prod"
    exit 1
    ;;
esac

case "$ENVIRONMENT" in
  dev | qa | prod) ;;
  *)
    echo "❌ ERROR: Unknown environment '${ENVIRONMENT}'"
    echo "   Known environments: dev, qa, prod"
    exit 1
    ;;
esac

if [ "$ENVIRONMENT" != "$EXPECTED_ENVIRONMENT" ]; then
  echo "❌ ERROR: Flavor/environment mismatch"
  echo "   --flavor ${FLAVOR} requires --dart-define=ENVIRONMENT=${EXPECTED_ENVIRONMENT}"
  echo "   but got --dart-define=ENVIRONMENT=${ENVIRONMENT}"
  exit 1
fi

echo "✅ Flavor/environment pairing OK: --flavor ${FLAVOR} <-> ENVIRONMENT=${ENVIRONMENT}"

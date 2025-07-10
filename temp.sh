#!/bin/bash

# Check if a feature name was provided
if [ -z "$1" ]; then
  echo "Usage: ./gt_add_feature.sh <feature_base_name>"
  exit 1
fi

FEATURE="$1"

# Define base paths
APP_PATH="lib/features/auth/presentation/pages/${FEATURE}_page.dart"
WIDGET_TEST="test/widgets/auth/pages/${FEATURE}_page_test.dart"
SCREENSHOT_TEST="test/screenshots/auth/${FEATURE}_page_screenshot_test.dart"
GOLDENS_DIR="test/screenshots/auth/goldens/${FEATURE}/"
MUTATIONS_FILE="test/mutations/features/auth/${FEATURE}_page_mutations.xml"

# Add all files/directories if they exist
gt add "$APP_PATH"
gt add "$WIDGET_TEST"
gt add "$SCREENSHOT_TEST"
gt add "$GOLDENS_DIR"
gt add "$MUTATIONS_FILE"

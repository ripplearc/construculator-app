// coverage:ignore-file
// Thin pass-through to the static PostHog SDK entry points, which rely on
// native platform channels and a running host app and therefore cannot be
// exercised in unit tests.

import 'package:construculator/libraries/analytics/interfaces/posthog_sdk.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Production [PosthogSdk] that delegates to the `Posthog()` singleton.
class PosthogSdkImpl implements PosthogSdk {
  @override
  Future<void> setup(PostHogConfig config) {
    return Posthog().setup(config);
  }

  @override
  Future<void> capture({
    required String eventName,
    Map<String, dynamic>? properties,
  }) {
    return Posthog().capture(
      eventName: eventName,
      properties: properties?.cast<String, Object>(),
    );
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, dynamic>? userProperties,
  }) {
    return Posthog().identify(
      userId: userId,
      userProperties: userProperties?.cast<String, Object>(),
    );
  }

  @override
  Future<void> reset() {
    return Posthog().reset();
  }

  @override
  Future<void> setPersonProperties({
    Map<String, dynamic>? userPropertiesToSet,
  }) {
    return Posthog().setPersonProperties(
      userPropertiesToSet: userPropertiesToSet?.cast<String, Object>(),
    );
  }

  @override
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? groupProperties,
  }) {
    // False positive: the lint's test-block detector matches any call named
    // `group`, including this SDK method of the same name.
    return Posthog().group(
      groupType: groupType,
      groupKey: groupKey,
      // ignore: no_optional_operators_in_tests
      groupProperties: groupProperties?.cast<String, Object>(),
    );
  }

  @override
  Future<bool> isFeatureEnabled(String key) {
    return Posthog().isFeatureEnabled(key);
  }

  @override
  Future<void> reloadFeatureFlags() {
    return Posthog().reloadFeatureFlags();
  }

  @override
  Future<Object?> getFeatureFlag(String key) {
    return Posthog().getFeatureFlag(key);
  }

  @override
  Future<Object?> getFeatureFlagPayload(String key) {
    // ignore: deprecated_member_use
    return Posthog().getFeatureFlagPayload(key);
  }
}

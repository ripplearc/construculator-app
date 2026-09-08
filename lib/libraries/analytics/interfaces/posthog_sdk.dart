// coverage:ignore-file
import 'package:posthog_flutter/posthog_flutter.dart';

/// Thin boundary over the static PostHog SDK entry points.
///
/// `PosthogWrapperImpl` talks to this interface instead of the `Posthog()`
/// singleton directly so its gate logic and lifecycle can be unit-tested
/// against a fake boundary.
abstract class PosthogSdk {
  /// Initializes the PostHog SDK; mirrors `Posthog().setup`.
  ///
  /// [config] the PostHog configuration to initialize the SDK with.
  Future<void> setup(PostHogConfig config);

  /// Captures a custom event; mirrors `Posthog().capture`.
  ///
  /// [eventName] identifies the event, and [properties] are optional
  /// key/value pairs attached to it.
  Future<void> capture({required String eventName, Map<String, dynamic>? properties});

  /// Associates events with a user; mirrors `Posthog().identify`.
  ///
  /// [userId] identifies the user, and [userProperties] are optional
  /// key/value pairs set on that user.
  Future<void> identify({
    required String userId,
    Map<String, dynamic>? userProperties,
  });

  /// Resets all cached identity; mirrors `Posthog().reset`.
  Future<void> reset();

  /// Sets person properties without changing identity; mirrors
  /// `Posthog().setPersonProperties`.
  ///
  /// [userPropertiesToSet] are the key/value pairs to set on the current
  /// user.
  Future<void> setPersonProperties({Map<String, dynamic>? userPropertiesToSet});

  /// Associates the current user with a group; mirrors `Posthog().group`.
  ///
  /// [groupType] the kind of group (e.g. `company`), [groupKey] identifies
  /// the specific group, and [groupProperties] are optional key/value pairs
  /// set on that group.
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? groupProperties,
  });

  /// Returns whether a boolean feature flag is enabled; mirrors
  /// `Posthog().isFeatureEnabled`.
  ///
  /// Returns `false` when [key] is disabled, missing, or not a boolean
  /// flag — the underlying SDK has no null case.
  Future<bool> isFeatureEnabled(String key);

  /// Reloads feature flags for the current user; mirrors
  /// `Posthog().reloadFeatureFlags`.
  Future<void> reloadFeatureFlags();

  /// Returns the raw flag value; mirrors `Posthog().getFeatureFlag`.
  ///
  /// A `bool` means a simple on/off flag; a `String` means a multivariate
  /// flag's variant key. Returns `null` if [key] is unset or evaluation
  /// failed.
  Future<Object?> getFeatureFlag(String key);

  /// Returns the JSON payload for a feature flag; mirrors
  /// `Posthog().getFeatureFlagPayload`.
  ///
  /// Returns `null` if [key] has no payload or evaluation failed.
  Future<Object?> getFeatureFlagPayload(String key);
}

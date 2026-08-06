import 'package:posthog_flutter/posthog_flutter.dart';

/// Thin boundary over the static PostHog SDK entry points.
///
/// `PosthogWrapperImpl` talks to this interface instead of the `Posthog()`
/// singleton directly so its gate logic and lifecycle can be unit-tested
/// against a fake boundary.
abstract class PosthogSdk {
  /// Initializes the PostHog SDK; mirrors `Posthog().setup`.
  Future<void> setup(PostHogConfig config);

  /// Captures a custom event; mirrors `Posthog().capture`.
  Future<void> capture({required String eventName, Map<String, dynamic>? properties});

  /// Associates events with a user; mirrors `Posthog().identify`.
  Future<void> identify({
    required String userId,
    Map<String, dynamic>? userProperties,
  });

  /// Resets all cached identity; mirrors `Posthog().reset`.
  Future<void> reset();

  /// Sets person properties without changing identity; mirrors
  /// `Posthog().setPersonProperties`.
  Future<void> setPersonProperties({Map<String, dynamic>? userPropertiesToSet});

  /// Associates the current user with a group; mirrors `Posthog().group`.
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? groupProperties,
  });
}

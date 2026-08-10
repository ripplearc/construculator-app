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
}

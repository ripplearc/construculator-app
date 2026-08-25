// coverage:ignore-file
/// Interface that wraps PostHog functionality.
///
/// This allows for easier testing by providing a clean abstraction layer,
/// and is the single point where analytics capture is gated on being
/// enabled — see [PosthogWrapper.initialize].
abstract class PosthogWrapper {
  /// Initializes PostHog with the given [apiKey] and [host].
  ///
  /// This is the single gate for whether anything is captured: if [apiKey]
  /// is empty, the SDK is never set up and every other method on this
  /// wrapper silently no-ops. Consent is currently satisfied by signup
  /// acceptance; if an explicit opt-in is required later, this is the one
  /// place to wire it — call sites never need to change.
  ///
  /// [debug] enables verbose PostHog SDK logging.
  Future<void> initialize({
    required String apiKey,
    required String host,
    bool debug = false,
  });

  /// Captures a custom event named [eventName] with optional [properties].
  Future<void> capture({required String eventName, Map<String, dynamic>? properties});

  /// Associates subsequent events with [userId], setting [userProperties] on
  /// their person profile.
  Future<void> identify({
    required String userId,
    Map<String, dynamic>? userProperties,
  });

  /// Resets all cached identity, reverting to an anonymous session.
  Future<void> reset();

  /// Updates the current user's person properties without changing identity.
  Future<void> setPersonProperties({Map<String, dynamic>? userProperties});

  /// Associates the current user with a group of type [groupType] identified
  /// by [groupKey], optionally setting group [groupProperties].
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? groupProperties,
  });

  /// Returns whether [flagKey] is enabled for the current user, or `null`
  /// if this wrapper isn't enabled (see [initialize]).
  ///
  /// Evaluated from the client-side cache populated by [reloadFeatureFlags],
  /// not a live network call.
  Future<bool?> isFeatureEnabled(String flagKey);

  /// Requests a refresh of the client-side feature flag cache for the
  /// current identity. The returned Future resolves once the refresh has
  /// been queued — not once the cache is confirmed updated, so a
  /// subsequent [isFeatureEnabled] call is not guaranteed to reflect it
  /// immediately.
  Future<void> reloadFeatureFlags();
}

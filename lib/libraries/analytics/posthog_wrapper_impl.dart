import 'package:construculator/libraries/analytics/interfaces/posthog_sdk.dart';
import 'package:construculator/libraries/analytics/interfaces/posthog_wrapper.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class PosthogWrapperImpl implements PosthogWrapper {
  final PosthogSdk _posthogSdk;
  // Guarded by _isEnabled — the single gate; every capture/identify/reset
  // method below no-ops until initialize() sets this true.
  bool _isEnabled = false;

  PosthogWrapperImpl({required this._posthogSdk});

  @override
  Future<void> initialize({
    required String apiKey,
    required String host,
    bool debug = false,
  }) async {
    // Skip PostHog initialization if the API key is not configured.
    // This prevents silent no-op scenarios where PostHog accepts an empty
    // token but drops all events without indication.
    if (apiKey.isEmpty) {
      return;
    }

    final config = PostHogConfig(apiKey)
      ..host = host
      ..debug = debug
      ..personProfiles = PostHogPersonProfiles.identifiedOnly;

    await _posthogSdk.setup(config);
    _isEnabled = true;
  }

  @override
  Future<void> capture({
    required String eventName,
    Map<String, dynamic>? properties,
  }) async {
    if (!_isEnabled) return;

    await _posthogSdk.capture(eventName: eventName, properties: properties);
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, dynamic>? userProperties,
  }) async {
    if (!_isEnabled) return;

    await _posthogSdk.identify(userId: userId, userProperties: userProperties);
  }

  @override
  Future<void> reset() async {
    if (!_isEnabled) return;

    await _posthogSdk.reset();
  }

  @override
  Future<void> setPersonProperties({
    Map<String, dynamic>? userProperties,
  }) async {
    if (!_isEnabled) return;

    await _posthogSdk.setPersonProperties(userPropertiesToSet: userProperties);
  }

  @override
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? groupProperties,
  }) async {
    if (!_isEnabled) return;

    await _posthogSdk.group(
      groupType: groupType,
      groupKey: groupKey,
      groupProperties: groupProperties,
    );
  }

  @override
  Future<bool?> isFeatureEnabled(String flagKey) async {
    if (!_isEnabled) return null;

    return _posthogSdk.isFeatureEnabled(flagKey);
  }

  @override
  Future<void> reloadFeatureFlags() async {
    if (!_isEnabled) return;

    await _posthogSdk.reloadFeatureFlags();
  }
}

// coverage:ignore-file

import 'package:construculator/libraries/analytics/interfaces/posthog_sdk.dart';
import 'package:equatable/equatable.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Fake [PosthogSdk] boundary that records calls for unit tests.
class FakePosthogSdk implements PosthogSdk {
  /// Number of times [setup] was called.
  int setupCallCount = 0;

  /// The config passed to the last [setup] call.
  PostHogConfig? lastConfig;

  /// Recorded calls to [capture].
  final List<CaptureCall> capturedEvents = [];

  /// Recorded calls to [identify].
  final List<IdentifyCall> identifyCalls = [];

  /// Number of times [reset] was called.
  int resetCallCount = 0;

  /// Recorded calls to [setPersonProperties].
  final List<SetPersonPropertiesCall> setPersonPropertiesCalls = [];

  /// Recorded calls to [group].
  final List<GroupCall> groupCalls = [];

  /// Recorded calls to [isFeatureEnabled], in order of the flag key passed.
  final List<String> isFeatureEnabledCalls = [];

  /// Value returned by [isFeatureEnabled].
  bool isFeatureEnabledResult = false;

  /// Number of times [reloadFeatureFlags] was called.
  int reloadFeatureFlagsCallCount = 0;

  /// Recorded calls to [getFeatureFlag], in order of the flag key passed.
  final List<String> getFeatureFlagCalls = [];

  /// Value returned by [getFeatureFlag].
  Object? getFeatureFlagResult;

  /// Recorded calls to [getFeatureFlagPayload], in order of the flag key
  /// passed.
  final List<String> getFeatureFlagPayloadCalls = [];

  /// Value returned by [getFeatureFlagPayload].
  Object? getFeatureFlagPayloadResult;

  /// Restores the fake to its initial state.
  ///
  /// Named to avoid colliding with [reset], the interface method under test.
  void resetFake() {
    setupCallCount = 0;
    lastConfig = null;
    capturedEvents.clear();
    identifyCalls.clear();
    resetCallCount = 0;
    setPersonPropertiesCalls.clear();
    groupCalls.clear();
    isFeatureEnabledCalls.clear();
    isFeatureEnabledResult = false;
    reloadFeatureFlagsCallCount = 0;
    getFeatureFlagCalls.clear();
    getFeatureFlagResult = null;
    getFeatureFlagPayloadCalls.clear();
    getFeatureFlagPayloadResult = null;
  }

  @override
  Future<void> setup(PostHogConfig config) async {
    setupCallCount++;
    lastConfig = config;
  }

  @override
  Future<void> capture({
    required String eventName,
    Map<String, dynamic>? properties,
  }) async {
    capturedEvents.add(
      CaptureCall(eventName: eventName, properties: properties),
    );
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, dynamic>? userProperties,
  }) async {
    identifyCalls.add(
      IdentifyCall(userId: userId, userProperties: userProperties),
    );
  }

  @override
  Future<void> reset() async {
    resetCallCount++;
  }

  @override
  Future<void> setPersonProperties({
    Map<String, dynamic>? userPropertiesToSet,
  }) async {
    setPersonPropertiesCalls.add(
      SetPersonPropertiesCall(userPropertiesToSet: userPropertiesToSet),
    );
  }

  @override
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? groupProperties,
  }) async {
    groupCalls.add(
      GroupCall(
        groupType: groupType,
        groupKey: groupKey,
        groupProperties: groupProperties,
      ),
    );
  }

  @override
  Future<bool> isFeatureEnabled(String key) async {
    isFeatureEnabledCalls.add(key);
    return isFeatureEnabledResult;
  }

  @override
  Future<void> reloadFeatureFlags() async {
    reloadFeatureFlagsCallCount++;
  }

  @override
  Future<Object?> getFeatureFlag(String key) async {
    getFeatureFlagCalls.add(key);
    return getFeatureFlagResult;
  }

  @override
  Future<Object?> getFeatureFlagPayload(String key) async {
    getFeatureFlagPayloadCalls.add(key);
    return getFeatureFlagPayloadResult;
  }
}

/// Represents a call to [FakePosthogSdk.capture].
class CaptureCall extends Equatable {
  /// Creates a recorded capture call.
  const CaptureCall({required this.eventName, this.properties});

  /// Captured event name.
  final String eventName;

  /// Optional event properties.
  final Map<String, dynamic>? properties;

  @override
  List<Object?> get props => [eventName, properties];
}

/// Represents a call to [FakePosthogSdk.identify].
class IdentifyCall extends Equatable {
  /// Creates a recorded identify call.
  const IdentifyCall({required this.userId, this.userProperties});

  /// Identified user id.
  final String userId;

  /// Optional user properties.
  final Map<String, dynamic>? userProperties;

  @override
  List<Object?> get props => [userId, userProperties];
}

/// Represents a call to [FakePosthogSdk.setPersonProperties].
class SetPersonPropertiesCall extends Equatable {
  /// Creates a recorded setPersonProperties call.
  const SetPersonPropertiesCall({this.userPropertiesToSet});

  /// Optional user properties to set.
  final Map<String, dynamic>? userPropertiesToSet;

  @override
  List<Object?> get props => [userPropertiesToSet];
}

/// Represents a call to [FakePosthogSdk.group].
class GroupCall extends Equatable {
  /// Creates a recorded group call.
  const GroupCall({
    required this.groupType,
    required this.groupKey,
    this.groupProperties,
  });

  /// Group type, e.g. `project`.
  final String groupType;

  /// Group key.
  final String groupKey;

  /// Optional group properties.
  final Map<String, dynamic>? groupProperties;

  @override
  List<Object?> get props => [groupType, groupKey, groupProperties];
}

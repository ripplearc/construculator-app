// coverage:ignore-file
import 'package:construculator/libraries/analytics/interfaces/posthog_wrapper.dart';
import 'package:equatable/equatable.dart';

/// Fake implementation of [PosthogWrapper] for testing purposes.
///
/// Always records calls, regardless of whether [initialize] was called —
/// unlike the real implementation, this fake does not gate on being
/// enabled. Use it to test repository-layer mapping logic in isolation from
/// the gate, which is covered by the real wrapper's own tests instead.
class FakePosthogWrapper implements PosthogWrapper {
  /// Recorded calls to [initialize].
  final List<InitializeCall> initializeCalls = [];

  /// Recorded calls to [capture].
  final List<CaptureCall> capturedEvents = [];

  /// Recorded calls to [identify].
  final List<IdentifyCall> identifyCalls = [];

  /// Number of times [reset] was called.
  int resetCallCount = 0;

  /// Recorded calls to [setPersonProperties].
  final List<Map<String, dynamic>?> setPersonPropertiesCalls = [];

  /// Recorded calls to [group].
  final List<GroupCall> groupCalls = [];

  /// If set, [capture], [identify], [reset], [setPersonProperties], and
  /// [group] throw this instead of recording the call.
  Object? errorToThrow;

  @override
  Future<void> initialize({
    required String apiKey,
    required String host,
    bool debug = false,
  }) async {
    final error = errorToThrow;
    if (error != null) throw error;
    initializeCalls.add(
      InitializeCall(apiKey: apiKey, host: host, debug: debug),
    );
  }

  @override
  Future<void> capture({
    required String eventName,
    Map<String, dynamic>? properties,
  }) async {
    final error = errorToThrow;
    if (error != null) throw error;
    capturedEvents.add(
      CaptureCall(eventName: eventName, properties: properties),
    );
  }

  @override
  Future<void> identify({
    required String userId,
    Map<String, dynamic>? userProperties,
  }) async {
    final error = errorToThrow;
    if (error != null) throw error;
    identifyCalls.add(
      IdentifyCall(userId: userId, userProperties: userProperties),
    );
  }

  @override
  Future<void> reset() async {
    final error = errorToThrow;
    if (error != null) throw error;
    resetCallCount++;
  }

  @override
  Future<void> setPersonProperties({
    Map<String, dynamic>? userProperties,
  }) async {
    final error = errorToThrow;
    if (error != null) throw error;
    setPersonPropertiesCalls.add(userProperties);
  }

  @override
  Future<void> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? groupProperties,
  }) async {
    final error = errorToThrow;
    if (error != null) throw error;
    groupCalls.add(
      GroupCall(
        groupType: groupType,
        groupKey: groupKey,
        groupProperties: groupProperties,
      ),
    );
  }

  /// Clears all recorded calls and any configured error.
  ///
  /// Named to avoid colliding with [reset], the interface method under test.
  void resetFake() {
    initializeCalls.clear();
    capturedEvents.clear();
    identifyCalls.clear();
    resetCallCount = 0;
    setPersonPropertiesCalls.clear();
    groupCalls.clear();
    errorToThrow = null;
  }
}

/// Represents a call to [FakePosthogWrapper.initialize].
class InitializeCall extends Equatable {
  /// Creates a recorded initialize call.
  const InitializeCall({
    required this.apiKey,
    required this.host,
    required this.debug,
  });

  /// The API key passed in.
  final String apiKey;

  /// The host passed in.
  final String host;

  /// The debug flag passed in.
  final bool debug;

  @override
  List<Object?> get props => [apiKey, host, debug];
}

/// Represents a call to [FakePosthogWrapper.capture].
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

/// Represents a call to [FakePosthogWrapper.identify].
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

/// Represents a call to [FakePosthogWrapper.group].
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

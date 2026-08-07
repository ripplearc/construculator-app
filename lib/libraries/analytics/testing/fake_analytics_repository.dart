import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_user_properties.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';

/// Fake implementation of [AnalyticsRepository] for testing purposes.
///
/// Tracks all method calls and their parameters so tests can verify
/// that the correct methods are called with the expected arguments,
/// without going through the PostHog SDK boundary.
class FakeAnalyticsRepository implements AnalyticsRepository {
  /// Recorded calls to [track].
  final List<AnalyticsEvent> trackedEvents = [];

  /// Recorded calls to [identify].
  final List<IdentifyCall> identifyCalls = [];

  /// Number of times [reset] was called.
  int resetCallCount = 0;

  /// Recorded calls to [setUserProperties].
  final List<AnalyticsUserProperties> setUserPropertiesCalls = [];

  /// Recorded calls to [group].
  final List<GroupCall> groupCalls = [];

  @override
  Future<Either<Failure, void>> track(AnalyticsEvent event) async {
    trackedEvents.add(event);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> identify({
    required String userId,
    required AnalyticsUserProperties properties,
  }) async {
    identifyCalls.add(IdentifyCall(userId: userId, properties: properties));
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> reset() async {
    resetCallCount++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> setUserProperties(
    AnalyticsUserProperties properties,
  ) async {
    setUserPropertiesCalls.add(properties);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? properties,
  }) async {
    groupCalls.add(
      GroupCall(groupType: groupType, groupKey: groupKey, properties: properties),
    );
    return const Right(null);
  }

  /// Clears all recorded calls.
  ///
  /// Named to avoid colliding with [reset], the interface method under test.
  void resetFake() {
    trackedEvents.clear();
    identifyCalls.clear();
    resetCallCount = 0;
    setUserPropertiesCalls.clear();
    groupCalls.clear();
  }
}

/// Represents a call to [FakeAnalyticsRepository.identify].
class IdentifyCall extends Equatable {
  /// Creates a recorded identify call.
  const IdentifyCall({required this.userId, required this.properties});

  /// Identified user id.
  final String userId;

  /// User properties passed alongside identification.
  final AnalyticsUserProperties properties;

  @override
  List<Object?> get props => [userId, properties];
}

/// Represents a call to [FakeAnalyticsRepository.group].
class GroupCall extends Equatable {
  /// Creates a recorded group call.
  const GroupCall({
    required this.groupType,
    required this.groupKey,
    this.properties,
  });

  /// Group type, e.g. `project`.
  final String groupType;

  /// Group key.
  final String groupKey;

  /// Optional group properties.
  final Map<String, dynamic>? properties;

  @override
  List<Object?> get props => [groupType, groupKey, properties];
}

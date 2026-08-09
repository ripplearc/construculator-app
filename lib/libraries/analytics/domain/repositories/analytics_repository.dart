// coverage:ignore-file
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_user_properties.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Abstract contract for product analytics.
///
/// SDK lifecycle methods (initialize, flush) are infrastructure concerns
/// handled by the implementation and app bootstrap, not part of this
/// domain-only contract.
///
/// Details can be found in the design doc: docs/Logging/Posthog-Integration.md
abstract class AnalyticsRepository {
  /// Tracks [event].
  Future<Either<Failure, void>> track(AnalyticsEvent event);

  /// Associates subsequent events with [userId] and sets [properties] on
  /// their person profile.
  Future<Either<Failure, void>> identify({
    required String userId,
    required AnalyticsUserProperties properties,
  });

  /// Clears the current user's identity, reverting to an anonymous session.
  ///
  /// Call on logout.
  Future<Either<Failure, void>> reset();

  /// Updates the current user's person properties without changing identity.
  Future<Either<Failure, void>> setUserProperties(
    AnalyticsUserProperties properties,
  );

  /// Associates the current user with a group of type [groupType] identified
  /// by [groupKey], optionally setting group [properties].
  ///
  /// Call once per group type — a user may belong to several group types
  /// simultaneously (e.g. both `project` and `company`).
  Future<Either<Failure, void>> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? properties,
  });
}

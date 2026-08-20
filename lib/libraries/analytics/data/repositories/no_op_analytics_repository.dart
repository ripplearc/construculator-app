import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_user_properties.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Production no-op used when `POSTHOG_ENABLED=false`.
///
/// Not a test double — for tests, inject `FakePosthogWrapper` into
/// [AnalyticsRepositoryImpl] instead.
class NoOpAnalyticsRepository implements AnalyticsRepository {
  const NoOpAnalyticsRepository();

  @override
  Future<Either<Failure, void>> track(AnalyticsEvent event) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> identify({
    required String userId,
    required AnalyticsUserProperties properties,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> reset() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> setUserProperties(
    AnalyticsUserProperties properties,
  ) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? properties,
  }) async {
    return const Right(null);
  }
}

import 'package:construculator/libraries/analytics/domain/repositories/feature_flag_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Production no-op used when `ANALYTICS_ENABLED=false`.
///
/// Not a test double — for tests, inject `FakePosthogWrapper` into
/// [FeatureFlagRepositoryImpl] instead, or use `FakeFeatureFlagRepository`
/// to control the repository-level result directly.
class NoOpFeatureFlagRepository implements FeatureFlagRepository {
  const NoOpFeatureFlagRepository();

  @override
  Future<Either<Failure, bool?>> isFeatureEnabled(
    String featureFlagKey,
  ) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> reloadFeatureFlags() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, String?>> getFeatureFlagVariant(
    String featureFlagKey,
  ) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getFeatureFlagPayload(
    String featureFlagKey,
  ) async {
    return const Right(null);
  }
}

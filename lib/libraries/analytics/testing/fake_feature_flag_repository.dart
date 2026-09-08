import 'package:construculator/libraries/analytics/domain/repositories/feature_flag_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Fake implementation of [FeatureFlagRepository] for testing purposes.
///
/// Lets tests fix a deterministic flag result (`true`/`false`/`null`)
/// without going through `PosthogWrapper`, per the testing approach in
/// docs/Logging/PostHog-Feature-Flags.md.
class FakeFeatureFlagRepository implements FeatureFlagRepository {
  /// Recorded calls to [isFeatureEnabled], in order of the flag key passed.
  final List<String> isFeatureEnabledCalls = [];

  /// Per-key return values for [isFeatureEnabled]; a key absent from this
  /// map behaves the same as an unset flag (`null`).
  final Map<String, bool?> flagOverrides = {};

  /// Number of times [reloadFeatureFlags] was called.
  int reloadFeatureFlagsCallCount = 0;

  /// Recorded calls to [getFeatureFlagVariant], in order of the flag key
  /// passed.
  final List<String> getFeatureFlagVariantCalls = [];

  /// Per-key return values for [getFeatureFlagVariant]; a key absent from
  /// this map behaves the same as an unset/non-multivariate flag (`null`).
  final Map<String, String?> variantOverrides = {};

  /// Recorded calls to [getFeatureFlagPayload], in order of the flag key
  /// passed.
  final List<String> getFeatureFlagPayloadCalls = [];

  /// Per-key return values for [getFeatureFlagPayload]; a key absent from
  /// this map behaves the same as a flag with no payload (`null`).
  final Map<String, Map<String, dynamic>?> payloadOverrides = {};

  @override
  Future<Either<Failure, bool?>> isFeatureEnabled(
    String featureFlagKey,
  ) async {
    isFeatureEnabledCalls.add(featureFlagKey);
    return Right(flagOverrides[featureFlagKey]);
  }

  @override
  Future<Either<Failure, void>> reloadFeatureFlags() async {
    reloadFeatureFlagsCallCount++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, String?>> getFeatureFlagVariant(
    String featureFlagKey,
  ) async {
    getFeatureFlagVariantCalls.add(featureFlagKey);
    return Right(variantOverrides[featureFlagKey]);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getFeatureFlagPayload(
    String featureFlagKey,
  ) async {
    getFeatureFlagPayloadCalls.add(featureFlagKey);
    return Right(payloadOverrides[featureFlagKey]);
  }

  /// Clears all recorded calls and flag overrides.
  void resetFake() {
    isFeatureEnabledCalls.clear();
    flagOverrides.clear();
    reloadFeatureFlagsCallCount = 0;
    getFeatureFlagVariantCalls.clear();
    variantOverrides.clear();
    getFeatureFlagPayloadCalls.clear();
    payloadOverrides.clear();
  }
}

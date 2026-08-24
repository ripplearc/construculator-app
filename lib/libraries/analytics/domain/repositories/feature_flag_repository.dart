// coverage:ignore-file
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Abstract contract for PostHog Feature Flags.
///
/// Evaluation reads a client-side cache populated by [reloadFeatureFlags];
/// there is no per-call network round trip. Every method fails closed: a
/// [Left] is never returned, and a `null` right-hand value (whether from a
/// real evaluation failure or an unset flag) must be treated as "off" by
/// callers. This applies uniformly across every method on this contract,
/// including [reloadFeatureFlags] — see its own doc comment for how that
/// applies to a cache-refresh call specifically.
///
/// Details can be found in the design doc: docs/Logging/PostHog-Feature-Flags.md
abstract class FeatureFlagRepository {
  /// Returns whether [featureFlagKey] is enabled for the current user, or
  /// `null` if the flag is unset or evaluation failed.
  Future<Either<Failure, bool?>> isFeatureEnabled(String featureFlagKey);

  /// Returns the variant key for a multivariate [featureFlagKey], or `null`
  /// if the flag is unset, not multivariate, or evaluation failed.
  Future<Either<Failure, String?>> getFeatureFlagVariant(
    String featureFlagKey,
  );

  /// Returns the JSON payload associated with [featureFlagKey], or `null`
  /// if the flag has no payload or evaluation failed.
  Future<Either<Failure, Map<String, dynamic>?>> getFeatureFlagPayload(
    String featureFlagKey,
  );

  /// Refreshes the client-side flag cache against the current identity.
  ///
  /// Call after app start (post `PosthogWrapper.initialize`); the design
  /// doc also calls for refreshing after `identify()`/`reset()`, which is
  /// deferred to whoever implements that trigger.
  ///
  /// Fails closed like every other method on this contract: a SDK failure
  /// while refreshing (e.g. timeout, connection error) is mapped to a
  /// [FeatureFlagFailure] and logged internally by the implementation, but
  /// is never returned as [Left] here — the cache simply keeps its
  /// last-known state and the call still resolves `Right`. Callers cannot
  /// distinguish "refreshed successfully" from "refresh failed, cache
  /// unchanged" through the return value.
  Future<Either<Failure, void>> reloadFeatureFlags();
}

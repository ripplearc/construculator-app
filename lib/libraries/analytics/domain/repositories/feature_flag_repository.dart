// coverage:ignore-file
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Abstract contract for PostHog Feature Flags.
///
/// Evaluation reads a client-side cache populated by [reloadFeatureFlags];
/// there is no per-call network round trip. Every method fails closed: a
/// [Left] is never returned, and a `null` right-hand value (whether from a
/// real evaluation failure or an unset flag) must be treated as "off" by
/// callers.
///
/// Details can be found in the design doc: docs/Logging/PostHog-Feature-Flags.md
abstract class FeatureFlagRepository {
  /// Returns whether [featureFlagKey] is enabled for the current user, or
  /// `null` if the flag is unset or evaluation failed.
  Future<Either<Failure, bool?>> isFeatureEnabled(String featureFlagKey);

  /// Refreshes the client-side flag cache against the current identity.
  ///
  /// Call after app start (post `PosthogWrapper.initialize`); the design
  /// doc also calls for refreshing after `identify()`/`reset()`, which is
  /// deferred to whoever implements that trigger.
  Future<Either<Failure, void>> reloadFeatureFlags();
}

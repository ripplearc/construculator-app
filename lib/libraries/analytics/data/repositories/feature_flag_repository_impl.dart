import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/analytics/domain/repositories/feature_flag_repository.dart';
import 'package:construculator/libraries/analytics/interfaces/posthog_wrapper.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

/// PostHog-backed implementation of [FeatureFlagRepository].
///
/// Fails closed: every error path is logged and mapped to `Right(null)`,
/// never `Left` — flag reads must never surface as a blocking error a
/// screen has to handle, per docs/Logging/PostHog-Feature-Flags.md.
class FeatureFlagRepositoryImpl implements FeatureFlagRepository {
  final PosthogWrapper _posthogWrapper;
  static final _logger = AppLogger().tag('FeatureFlagRepositoryImpl');

  /// Creates a [FeatureFlagRepositoryImpl] with the given [_posthogWrapper].
  FeatureFlagRepositoryImpl({required this._posthogWrapper});

  void _logMappedError(Object error, String operation) {
    if (error is TimeoutException) {
      _logger.warning('Timeout error $operation: message=${error.message}');
    } else if (error is SocketException) {
      _logger.warning(
        'Connection error $operation: message=${error.message}',
      );
    } else {
      _logger.error('Unexpected error $operation: $error');
    }
  }

  @override
  Future<Either<Failure, bool?>> isFeatureEnabled(
    String featureFlagKey,
  ) async {
    try {
      return Right(await _posthogWrapper.isFeatureEnabled(featureFlagKey));
    } catch (e) {
      _logMappedError(e, 'evaluating feature flag $featureFlagKey');
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> reloadFeatureFlags() async {
    try {
      await _posthogWrapper.reloadFeatureFlags();
      return const Right(null);
    } catch (e) {
      _logMappedError(e, 'reloading feature flags');
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, String?>> getFeatureFlagVariant(
    String featureFlagKey,
  ) async {
    try {
      return Right(
        await _posthogWrapper.getFeatureFlagVariant(featureFlagKey),
      );
    } catch (e) {
      _logMappedError(e, 'evaluating feature flag variant $featureFlagKey');
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getFeatureFlagPayload(
    String featureFlagKey,
  ) async {
    try {
      return Right(
        await _posthogWrapper.getFeatureFlagPayload(featureFlagKey),
      );
    } catch (e) {
      _logMappedError(e, 'evaluating feature flag payload $featureFlagKey');
      return const Right(null);
    }
  }
}

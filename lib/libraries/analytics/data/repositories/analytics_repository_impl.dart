import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/analytics/current_screen_tracker.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_user_properties.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:construculator/libraries/analytics/domain/types/analytics_error_type.dart';
import 'package:construculator/libraries/analytics/interfaces/posthog_wrapper.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:flutter/foundation.dart';

/// PostHog-backed implementation of [AnalyticsRepository].
///
/// Delegates all operations to [PosthogWrapper] and maps any thrown
/// exceptions to typed [Failure] values so callers never have to catch.
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final EnvLoader _envLoader;
  final PosthogWrapper _posthogWrapper;
  final CurrentScreenTracker _currentScreenTracker;
  final String _appVersion;
  static final _logger = AppLogger().tag('AnalyticsRepositoryImpl');

  /// Creates an [AnalyticsRepositoryImpl].
  ///
  /// [currentScreenTracker] must be the same instance given to
  /// `AnalyticsNavigatorObserver` so `track()` can attach the currently
  /// active screen to every event. [appVersion] is resolved once at
  /// bootstrap (e.g. via `package_info_plus`) since it never changes at
  /// runtime.
  AnalyticsRepositoryImpl({
    required this._envLoader,
    required this._posthogWrapper,
    required this._currentScreenTracker,
    required this._appVersion,
  });

  /// Standard properties attached to every [track]ed event, per
  /// `docs/Logging/PostHog-Event-Tracking.md`'s "Standard Properties"
  /// contract.
  Map<String, dynamic> get _standardProperties => {
    'app_version': _appVersion,
    'platform': _platformName,
    'screen_name': _currentScreenTracker.screenName,
  };

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /// Reads PostHog configuration from [_envLoader] and initializes the
  /// underlying wrapper.
  ///
  /// Infrastructure concern — called once during app bootstrap, not part of
  /// the [AnalyticsRepository] domain contract.
  Future<Either<Failure, void>> initialize() async {
    try {
      await _posthogWrapper.initialize(
        apiKey: _envLoader.get(posthogApiKeyKey) ?? '',
        host: _envLoader.get(posthogHostKey) ?? '',
        debug: (_envLoader.get(posthogDebugKey) ?? '').toLowerCase() ==
            'true',
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e, 'initializing analytics'));
    }
  }

  Failure _handleError(Object error, String operation) {
    if (error is TimeoutException) {
      _logger.warning('Timeout error $operation: message=${error.message}');
      return const AnalyticsFailure(errorType: AnalyticsErrorType.timeoutError);
    }

    if (error is SocketException) {
      _logger.warning(
        'Connection error $operation: message=${error.message}',
      );
      return const AnalyticsFailure(
        errorType: AnalyticsErrorType.connectionError,
      );
    }

    _logger.error('Unexpected error $operation: $error');
    return UnexpectedFailure();
  }

  @override
  Future<Either<Failure, void>> track(AnalyticsEvent event) async {
    try {
      await _posthogWrapper.capture(
        eventName: event.name,
        properties: {..._standardProperties, ...event.properties},
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e, 'tracking event ${event.name}'));
    }
  }

  @override
  Future<Either<Failure, void>> identify({
    required String userId,
    required AnalyticsUserProperties properties,
  }) async {
    try {
      await _posthogWrapper.identify(
        userId: userId,
        userProperties: properties.toMap(),
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e, 'identifying user $userId'));
    }
  }

  @override
  Future<Either<Failure, void>> reset() async {
    try {
      await _posthogWrapper.reset();
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e, 'resetting analytics identity'));
    }
  }

  @override
  Future<Either<Failure, void>> setUserProperties(
    AnalyticsUserProperties properties,
  ) async {
    try {
      await _posthogWrapper.setPersonProperties(
        userProperties: properties.toMap(),
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e, 'setting user properties'));
    }
  }

  @override
  Future<Either<Failure, void>> group({
    required String groupType,
    required String groupKey,
    Map<String, dynamic>? properties,
  }) async {
    try {
      await _posthogWrapper.group(
        groupType: groupType,
        groupKey: groupKey,
        groupProperties: properties,
      );
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e, 'setting group $groupType:$groupKey'));
    }
  }
}

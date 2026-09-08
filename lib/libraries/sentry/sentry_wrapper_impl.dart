import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/sentry/interfaces/sentry_sdk.dart';
import 'package:construculator/libraries/sentry/interfaces/sentry_wrapper.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryWrapperImpl implements SentryWrapper {
  static const double _prodTracesSampleRate = 0.1;
  static const double _nonProdTracesSampleRate = 1.0;

  final EnvLoader _envLoader;
  final Config _config;
  final SentrySdk _sentrySdk;
  // Guarded by _isInitialized; all callers are expected to call initialize() first.
  bool _isInitialized = false;

  SentryWrapperImpl({
    required this._envLoader,
    required this._config,
    required this._sentrySdk,
  });

  @override
  Future<void> initialize(void Function() appRunner) async {
    final dsn = _envLoader.get(sentryDsnKey) ?? '';

    // Skip Sentry initialization if DSN is not configured
    // This prevents silent no-op scenarios where Sentry accepts empty DSN
    // but drops all events without indication
    if (dsn.isEmpty) {
      appRunner();
      return;
    }

    await _sentrySdk.init((options) {
      options.dsn = dsn;
      options.environment = _config.getEnvironmentName(_config.environment);

      options.tracesSampleRate = _config.isProd
          ? _prodTracesSampleRate
          : _nonProdTracesSampleRate;
      options.enableAutoPerformanceTracing = true;
      options.attachScreenshot = false;
      options.enableAutoSessionTracking = true;
      options.captureFailedRequests = true;
    }, appRunner: appRunner);

    _isInitialized = true;
  }

  @override
  Future<void> addBreadcrumb({
    required String message,
    required SentryEventLevel level,
    String? category,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) return;

    await _sentrySdk.addBreadcrumb(
      Breadcrumb(
        message: message,
        level: _getSentryLevel(level),
        category: category,
        data: data,
      ),
    );
  }

  @override
  Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
    Map<String, String>? tags,
    Map<String, dynamic>? contexts,
  }) async {
    if (!_isInitialized) return;

    await _sentrySdk.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (tags != null) {
          tags.forEach((key, value) => scope.setTag(key, value));
        }
        if (contexts != null) {
          contexts.forEach((key, value) => scope.setContexts(key, value));
        }
      },
    );
  }

  @override
  Future<void> captureMessage(
    String message, {
    required SentryEventLevel level,
    Map<String, String>? tags,
  }) async {
    if (!_isInitialized) return;

    await _sentrySdk.captureMessage(
      message,
      level: _getSentryLevel(level),
      withScope: (scope) {
        if (tags != null) {
          tags.forEach((key, value) => scope.setTag(key, value));
        }
      },
    );
  }

  /// Sets the Sentry user context for all subsequent events.
  ///
  /// Configures the active Sentry scope with [userId]. Passing `null`
  /// clears the user context on logout. No-ops if [_isInitialized] is
  /// false (e.g. DSN not configured in environment).
  @override
  Future<void> setUser(String? userId) async {
    if (!_isInitialized) return;

    await _sentrySdk.configureScope((scope) {
      if (userId != null) {
        scope.setUser(SentryUser(id: userId));
      } else {
        scope.setUser(null);
      }
    });
  }

  SentryLevel _getSentryLevel(SentryEventLevel level) {
    return switch (level) {
      SentryEventLevel.debug => SentryLevel.debug,
      SentryEventLevel.info => SentryLevel.info,
      SentryEventLevel.warning => SentryLevel.warning,
      SentryEventLevel.error => SentryLevel.error,
      SentryEventLevel.fatal => SentryLevel.fatal,
    };
  }
}

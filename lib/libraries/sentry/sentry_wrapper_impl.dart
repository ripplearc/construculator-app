// coverage:ignore-file
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/sentry/interfaces/sentry_wrapper.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryWrapperImpl implements SentryWrapper {
  final EnvLoader _envLoader;
  final Config _config;
  bool _isInitialized = false;

  SentryWrapperImpl({required EnvLoader envLoader, required Config config})
    : _envLoader = envLoader,
      _config = config;

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

    await SentryFlutter.init((options) {
      options.dsn = dsn;
      options.environment = _config.getEnvironmentName(_config.environment);

      // TODO: https://ripplearc.youtrack.cloud/issue/CA-566 (Enable performance tracing once baseline is established).
      options.tracesSampleRate = 0.0;
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

    await Sentry.addBreadcrumb(
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
    dynamic exception, {
    dynamic stackTrace,
    Map<String, String>? tags,
    Map<String, dynamic>? contexts,
  }) async {
    if (!_isInitialized) return;

    await Sentry.captureException(
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

    await Sentry.captureMessage(
      message,
      level: _getSentryLevel(level),
      withScope: (scope) {
        if (tags != null) {
          tags.forEach((key, value) => scope.setTag(key, value));
        }
      },
    );
  }

  @override
  Future<void> setUser(String? userId) async {
    if (!_isInitialized) return;

    await Sentry.configureScope((scope) {
      scope.setUser(userId != null ? SentryUser(id: userId) : null);
    });
  }

  SentryLevel _getSentryLevel(SentryEventLevel level) {
    return switch (level) {
      SentryDebugLevel() => SentryLevel.debug,
      SentryInfoLevel() => SentryLevel.info,
      SentryWarningLevel() => SentryLevel.warning,
      SentryErrorLevel() => SentryLevel.error,
      SentryFatalLevel() => SentryLevel.fatal,
    };
  }
}

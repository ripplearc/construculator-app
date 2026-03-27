// coverage:ignore-file
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/sentry/interfaces/sentry_wrapper.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryWrapperImpl implements SentryWrapper {
  final EnvLoader _envLoader;
  final Config _config;

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
  }
}

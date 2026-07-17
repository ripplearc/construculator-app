// coverage:ignore-file
// Thin pass-through to the static Sentry SDK entry points, which rely on
// native platform channels and a running host app and therefore cannot be
// exercised in unit tests.

import 'package:construculator/libraries/sentry/interfaces/sentry_sdk.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Production [SentrySdk] that delegates to the static Sentry SDK APIs.
class SentrySdkImpl implements SentrySdk {
  @override
  Future<void> init(
    FlutterOptionsConfiguration optionsConfiguration, {
    required void Function() appRunner,
  }) {
    return SentryFlutter.init(optionsConfiguration, appRunner: appRunner);
  }

  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) {
    return Sentry.addBreadcrumb(breadcrumb);
  }

  @override
  Future<SentryId> captureException(
    Object throwable, {
    StackTrace? stackTrace,
    ScopeCallback? withScope,
  }) {
    return Sentry.captureException(
      throwable,
      stackTrace: stackTrace,
      withScope: withScope,
    );
  }

  @override
  Future<SentryId> captureMessage(
    String message, {
    SentryLevel? level,
    ScopeCallback? withScope,
  }) {
    return Sentry.captureMessage(message, level: level, withScope: withScope);
  }

  @override
  Future<void> configureScope(ScopeCallback callback) async {
    await Sentry.configureScope(callback);
  }
}

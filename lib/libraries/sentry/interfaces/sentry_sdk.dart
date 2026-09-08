import 'package:sentry_flutter/sentry_flutter.dart';

/// Boundary over the static Sentry SDK entry points.
///
/// `SentryWrapperImpl` talks to this interface instead of the static
/// [SentryFlutter] / [Sentry] APIs so its initialization guard and level
/// mapping logic can be unit-tested against a fake boundary.
abstract class SentrySdk {
  /// Initializes the Sentry SDK; mirrors [SentryFlutter.init].
  ///
  /// [optionsConfiguration] configures the [SentryFlutterOptions] before the
  /// SDK starts, and [appRunner] runs the Flutter app once the SDK is ready.
  Future<void> init(
    FlutterOptionsConfiguration optionsConfiguration, {
    required void Function() appRunner,
  });

  /// Adds a breadcrumb to the current scope; mirrors [Sentry.addBreadcrumb].
  ///
  /// [breadcrumb] the breadcrumb to record.
  Future<void> addBreadcrumb(Breadcrumb breadcrumb);

  /// Captures an exception event; mirrors [Sentry.captureException].
  ///
  /// [throwable] the exception to capture, [stackTrace] its optional stack
  /// trace, and [withScope] an optional callback to customize the event scope.
  Future<SentryId> captureException(
    Object throwable, {
    StackTrace? stackTrace,
    ScopeCallback? withScope,
  });

  /// Captures a message event; mirrors [Sentry.captureMessage].
  ///
  /// [message] the message to capture, [level] its severity, and [withScope]
  /// an optional callback to customize the event scope.
  Future<SentryId> captureMessage(
    String message, {
    SentryLevel? level,
    ScopeCallback? withScope,
  });

  /// Configures the current scope; mirrors [Sentry.configureScope].
  ///
  /// [callback] receives the active scope to mutate.
  Future<void> configureScope(ScopeCallback callback);
}

import 'package:construculator/libraries/sentry/interfaces/sentry_sdk.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Fake [SentrySdk] boundary that records calls for unit tests.
///
/// Mirrors the real [SentrySdk] contract: [init] runs the options
/// configuration against a fresh [SentryFlutterOptions] (exposed via
/// [lastConfiguredOptions]) and then invokes the app runner, matching the
/// real SDK's behavior.
class FakeSentrySdk implements SentrySdk {
  /// Number of times [init] was called.
  int initCallCount = 0;

  /// The options produced by the configuration callback of the last [init].
  SentryFlutterOptions? lastConfiguredOptions;

  /// Breadcrumbs recorded via [addBreadcrumb].
  final List<Breadcrumb> addedBreadcrumbs = [];

  /// Exceptions recorded via [captureException].
  final List<Object> capturedExceptions = [];

  /// Stack traces recorded via [captureException], aligned by index.
  final List<StackTrace?> capturedExceptionStackTraces = [];

  /// Scope callbacks recorded via [captureException], aligned by index.
  final List<ScopeCallback?> capturedExceptionScopeCallbacks = [];

  /// Messages recorded via [captureMessage].
  final List<String> capturedMessages = [];

  /// Levels recorded via [captureMessage], aligned by index.
  final List<SentryLevel?> capturedMessageLevels = [];

  /// Scope callbacks recorded via [captureMessage], aligned by index.
  final List<ScopeCallback?> capturedMessageScopeCallbacks = [];

  /// Scope callbacks recorded via [configureScope].
  final List<ScopeCallback> configureScopeCallbacks = [];

  /// Restores the fake to its initial state.
  void reset() {
    initCallCount = 0;
    lastConfiguredOptions = null;
    addedBreadcrumbs.clear();
    capturedExceptions.clear();
    capturedExceptionStackTraces.clear();
    capturedExceptionScopeCallbacks.clear();
    capturedMessages.clear();
    capturedMessageLevels.clear();
    capturedMessageScopeCallbacks.clear();
    configureScopeCallbacks.clear();
  }

  @override
  Future<void> init(
    FlutterOptionsConfiguration optionsConfiguration, {
    required void Function() appRunner,
  }) async {
    initCallCount++;
    final options = SentryFlutterOptions();
    await optionsConfiguration(options);
    lastConfiguredOptions = options;
    appRunner();
  }

  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {
    addedBreadcrumbs.add(breadcrumb);
  }

  @override
  Future<SentryId> captureException(
    Object throwable, {
    StackTrace? stackTrace,
    ScopeCallback? withScope,
  }) async {
    capturedExceptions.add(throwable);
    capturedExceptionStackTraces.add(stackTrace);
    capturedExceptionScopeCallbacks.add(withScope);
    return SentryId.newId();
  }

  @override
  Future<SentryId> captureMessage(
    String message, {
    SentryLevel? level,
    ScopeCallback? withScope,
  }) async {
    capturedMessages.add(message);
    capturedMessageLevels.add(level);
    capturedMessageScopeCallbacks.add(withScope);
    return SentryId.newId();
  }

  @override
  Future<void> configureScope(ScopeCallback callback) async {
    configureScopeCallbacks.add(callback);
  }
}

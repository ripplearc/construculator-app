import 'package:construculator/libraries/sentry/interfaces/sentry_wrapper.dart';
import 'package:equatable/equatable.dart';

/// Fake implementation of SentryWrapper for testing purposes.
///
/// Tracks all method calls and their parameters so tests can verify
/// that the correct methods are called with the expected arguments.
class FakeSentryWrapper implements SentryWrapper {
  /// Recorded calls to [addBreadcrumb].
  final List<BreadcrumbCall> breadcrumbs = [];

  /// Recorded calls to [captureException].
  final List<ExceptionCall> exceptions = [];

  /// Recorded calls to [captureMessage].
  final List<MessageCall> messages = [];

  /// Current user ID set via [setUser].
  String? userId;

  /// Executes [appRunner] immediately for tests.
  @override
  Future<void> initialize(void Function() appRunner) async {
    appRunner();
  }

  /// Stores breadcrumb details so tests can assert on them.
  @override
  Future<void> addBreadcrumb({
    required String message,
    required SentryEventLevel level,
    String? category,
    Map<String, dynamic>? data,
  }) async {
    breadcrumbs.add(
      BreadcrumbCall(
        message: message,
        level: level,
        category: category,
        data: data,
      ),
    );
  }

  /// Stores exception details so tests can assert on them.
  @override
  Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
    Map<String, String>? tags,
    Map<String, dynamic>? contexts,
  }) async {
    exceptions.add(
      ExceptionCall(
        exception: exception,
        stackTrace: stackTrace,
        tags: tags,
        contexts: contexts,
      ),
    );
  }

  /// Stores message details so tests can assert on them.
  @override
  Future<void> captureMessage(
    String message, {
    required SentryEventLevel level,
    Map<String, String>? tags,
  }) async {
    messages.add(MessageCall(message: message, level: level, tags: tags));
  }

  /// Sets the user context for Sentry events.
  @override
  Future<void> setUser(String? userId) async {
    this.userId = userId;
  }

  /// Clears all recorded calls.
  void reset() {
    breadcrumbs.clear();
    exceptions.clear();
    messages.clear();
    userId = null;
  }
}

/// Represents a call to addBreadcrumb
class BreadcrumbCall extends Equatable {
  /// Breadcrumb message.
  final String message;

  /// Breadcrumb level.
  final SentryEventLevel level;

  /// Optional breadcrumb category.
  final String? category;

  /// Optional breadcrumb metadata.
  final Map<String, dynamic>? data;

  /// Creates a recorded breadcrumb call.
  const BreadcrumbCall({
    required this.message,
    required this.level,
    this.category,
    this.data,
  });

  @override
  /// Values used for equality checks.
  List<Object?> get props => [message, level, category, data];
}

/// Represents a call to captureException
class ExceptionCall extends Equatable {
  /// Captured exception object.
  final Object exception;

  /// Captured stack trace.
  final StackTrace? stackTrace;

  /// Optional tags included with the exception.
  final Map<String, String>? tags;

  /// Optional contexts included with the exception.
  final Map<String, dynamic>? contexts;

  /// Creates a recorded exception call.
  const ExceptionCall({
    required this.exception,
    this.stackTrace,
    this.tags,
    this.contexts,
  });

  @override
  /// Values used for equality checks.
  List<Object?> get props => [exception, stackTrace, tags, contexts];
}

/// Represents a call to captureMessage
class MessageCall extends Equatable {
  /// Captured message text.
  final String message;

  /// Captured message level.
  final SentryEventLevel level;

  /// Optional tags included with the message.
  final Map<String, String>? tags;

  /// Creates a recorded message call.
  const MessageCall({required this.message, required this.level, this.tags});

  @override
  /// Values used for equality checks.
  List<Object?> get props => [message, level, tags];
}

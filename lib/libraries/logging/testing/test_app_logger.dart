import 'package:construculator/libraries/logging/interfaces/logger.dart';
import 'package:construculator/libraries/logging/testing/fake_logger_wrapper.dart';

class TestAppLogger implements Logger {
  String currentTag;
  String currentEmojiPrefix;
  final FakeLoggerWrapper internalLogger;

  final List<dynamic> loggedErrors = [];
  final List<StackTrace?> loggedStackTraces = [];

  TestAppLogger._private(this.currentTag, this.currentEmojiPrefix, this.internalLogger);

  TestAppLogger({required this.internalLogger})
    : currentTag = 'FakeLogger',
      currentEmojiPrefix = '';

  @override
  Logger tag(String newTag) {
    return TestAppLogger._private(newTag, currentEmojiPrefix, internalLogger);
  }

  @override
  Logger emoji(String newEmojiPrefix) {
    return TestAppLogger._private(currentTag, newEmojiPrefix, internalLogger);
  }

  String _formatMessage(String message) {
    String prefix = '';
    if (currentEmojiPrefix.isNotEmpty) {
      prefix += '$currentEmojiPrefix ';
    }
    prefix += '[$currentTag]';
    return '$prefix $message';
  }

  @override
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.i(
      _formatMessage(message),
      error: error,
      stackTrace: stackTrace,
    );
    if (error != null) loggedErrors.add(error);
    if (stackTrace != null) loggedStackTraces.add(stackTrace);
  }

  @override
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.w(
      _formatMessage(message),
      error: error,
      stackTrace: stackTrace,
    );
    if (error != null) loggedErrors.add(error);
    if (stackTrace != null) loggedStackTraces.add(stackTrace);
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.e(
      _formatMessage(message),
      error: error,
      stackTrace: stackTrace,
    );
    if (error != null) loggedErrors.add(error);
    if (stackTrace != null) loggedStackTraces.add(stackTrace);
  }

  @override
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.d(
      _formatMessage(message),
      error: error,
      stackTrace: stackTrace,
    );
    if (error != null) loggedErrors.add(error);
    if (stackTrace != null) loggedStackTraces.add(stackTrace);
  }

  @override
  void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.f(
      _formatMessage(message),
      error: error,
      stackTrace: stackTrace,
    );
    if (error != null) loggedErrors.add(error);
    if (stackTrace != null) loggedStackTraces.add(stackTrace);
  }

  @override
  void omg(String message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.f(
      _formatMessage(message),
      error: error,
      stackTrace: stackTrace,
    );
    if (error != null) loggedErrors.add(error);
    if (stackTrace != null) loggedStackTraces.add(stackTrace);
  }

  void clear() {
    internalLogger.clear();
    loggedErrors.clear();
    loggedStackTraces.clear();
  }

  void reset() {
    clear();
    currentTag = 'FakeLogger';
    currentEmojiPrefix = '';
  }
  
  @override
  Logger fresh() {
    return TestAppLogger._private('FakeLogger', '', internalLogger);
  }
}

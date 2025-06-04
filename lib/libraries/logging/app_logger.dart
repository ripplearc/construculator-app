import 'package:construculator/libraries/logging/interfaces/logger.dart';
import 'package:construculator/libraries/logging/interfaces/logger_wrapper.dart';

// Logger implementation that uses the flutter logger package.
// Currently, it is only used to log messages to the console. 
// This implementation will be extended to support other logging targets in the future.
class AppLoggerImpl implements Logger {
  final String _tag;
  final String _emojiPrefix;
  final LoggerWrapper _internalLogger;

  // Private constructor for internal instantiation by tag() and emoji()
  AppLoggerImpl._private(this._tag, this._emojiPrefix, this._internalLogger);

  AppLoggerImpl({
    required LoggerWrapper internalLogger,
  })  : _tag = 'Construculator',
        _emojiPrefix = '',
        _internalLogger = internalLogger;

  String _formatMessage(String message) {
    String prefix = '';
    if (_emojiPrefix.isNotEmpty) {
      prefix += '$_emojiPrefix ';
    }
    prefix += '[$_tag]';
    return '$prefix $message';
  }

  @override
  Logger fresh() {
    // Return a new instance with the default tag and emoji prefix, 
    // and sharing the same internal logger
    return AppLoggerImpl._private('Construculator', '', _internalLogger);
  }
  @override
  Logger tag(String newTag) {
    // Return a new instance with the new tag, preserving the current emojiPrefix 
    // and sharing the same internal 
    return AppLoggerImpl._private(newTag, _emojiPrefix, _internalLogger);
  }

  @override
  Logger emoji(String newEmojiPrefix) {
    // Return a new instance with the new emojiPrefix, preserving the current tag
    // and sharing the same internal 
    return AppLoggerImpl._private(_tag, newEmojiPrefix, _internalLogger);
  }

  @override
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.i(_formatMessage(message), error: error, stackTrace: stackTrace);
  }

  @override
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.w(_formatMessage(message), error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.e(_formatMessage(message), error: error, stackTrace: stackTrace);
  }

  @override
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.d(_formatMessage(message), error: error, stackTrace: stackTrace);
  }

  @override
  void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.f(_formatMessage(message), error: error, stackTrace: stackTrace);
  }

  @override
  void omg(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.f(_formatMessage(message), error: error, stackTrace: stackTrace);
  }
} 
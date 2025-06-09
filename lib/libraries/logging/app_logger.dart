// coverage:ignore-file
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logger/logger.dart';

/// Global Logger For The App
class AppLogger {
  final String _tag;
  final String _emojiPrefix;
  final Logger _internalLogger;

  /// Private constructor for internal instantiation by tag() and emoji()
  AppLogger._private(this._tag, this._emojiPrefix, this._internalLogger);

  AppLogger()  : _tag = 'Construculator',
        _emojiPrefix = '',
        _internalLogger = Logger(
          filter: _AppLogFilter(),
          printer: PrettyPrinter(
            methodCount: 1,
            errorMethodCount: 5,
            lineLength: 80,
            colors: true,
            printEmojis: true,
          ),
          output: ConsoleOutput(),
        );

  String _formatMessage(String message) {
    String prefix = '';
    if (_emojiPrefix.isNotEmpty) {
      prefix += '$_emojiPrefix ';
    }
    prefix += '[$_tag]';
    return '$prefix $message';
  }

  /// Return a new instance with the default tag and emoji prefix, 
  /// and sharing the same internal logger
  AppLogger fresh() {
    return AppLogger._private('Construculator', '', _internalLogger);
  }

  /// Return a new instance with the new tag, preserving the current emojiPrefix 
  /// and sharing the same internal logger
  AppLogger tag(String newTag) {
    return AppLogger._private(newTag, _emojiPrefix, _internalLogger);
  }

  /// Return a new instance with the new emojiPrefix, preserving the current tag
  /// and sharing the same internal logger
  AppLogger emoji(String newEmojiPrefix) {
    return AppLogger._private(_tag, newEmojiPrefix, _internalLogger);
  }

  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.i(_formatMessage(message), error: error, stackTrace: stackTrace);
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.w(_formatMessage(message), error: error, stackTrace: stackTrace);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.e(_formatMessage(message), error: error, stackTrace: stackTrace);
  }

  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.d(_formatMessage(message), error: error, stackTrace: stackTrace);
  }

  void omg(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.f(_formatMessage(message), error: error, stackTrace: stackTrace);
  }
} 

class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    final env = String.fromEnvironment('APP_ENV',defaultValue: devEnv);
    if (env == prodEnv && !kDebugMode) {
      return event.level.index >= Level.warning.index; // Only log warnings and errors and fatal/omg in production
    }

    if (env == qaEnv && !kDebugMode) {
      return event.level.index >= Level.info.index; // Only log info and above in qa
    }

    return true; // Log all messages in dev
  }
}
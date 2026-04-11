import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/sentry/interfaces/sentry_wrapper.dart';
import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:logger/logger.dart';

/// Global Logger For The App
class AppLogger {
  final String _tag;
  final String _emojiPrefix;
  final Logger _internalLogger;
  final SentryWrapper? _sentryWrapper;
  final Config? _config;

  /// Static default SentryWrapper instance used when none is provided
  static SentryWrapper? _defaultSentryWrapper;

  /// Static default Config instance used when none is provided
  static Config? _defaultConfig;

  /// Set the default SentryWrapper to be used by all AppLogger instances
  /// This should be called once during app initialization
  static void setSentryWrapper(SentryWrapper? wrapper) {
    _defaultSentryWrapper = wrapper;
  }

  /// Set the default Config to be used by all AppLogger instances
  /// This should be called once during app initialization
  static void setConfig(Config? config) {
    _defaultConfig = config;
  }

  /// Private constructor for internal instantiation by tag() and emoji()
  AppLogger._private(
    this._tag,
    this._emojiPrefix,
    this._internalLogger,
    this._sentryWrapper,
    this._config,
  );

  /// Creates an [AppLogger] with optional [sentryWrapper] and [config] overrides.
  /// Falls back to the static defaults set via [setSentryWrapper] and [setConfig].
  AppLogger({SentryWrapper? sentryWrapper, Config? config})
    : _tag = 'Construculator',
      _emojiPrefix = '',
      _sentryWrapper = sentryWrapper ?? _defaultSentryWrapper,
      _config = config ?? _defaultConfig,
      _internalLogger = Logger(
        filter: AppLogFilter(config: config ?? _defaultConfig),
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
    return AppLogger._private(
      'Construculator',
      '',
      _internalLogger,
      _sentryWrapper,
      _config,
    );
  }

  /// Return a new instance with the new tag, preserving the current emojiPrefix
  /// and sharing the same internal logger
  AppLogger tag(String newTag) {
    return AppLogger._private(
      newTag,
      _emojiPrefix,
      _internalLogger,
      _sentryWrapper,
      _config,
    );
  }

  /// Return a new instance with the new emojiPrefix, preserving the current tag
  /// and sharing the same internal logger
  AppLogger emoji(String newEmojiPrefix) {
    return AppLogger._private(
      _tag,
      newEmojiPrefix,
      _internalLogger,
      _sentryWrapper,
      _config,
    );
  }

  /// Logs an informational message.
  /// Writes to console (filtered by environment) and adds a Sentry breadcrumb.
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.i(
      _formatMessage(message),
      error: error,
      stackTrace: stackTrace,
    );

    _sentryWrapper?.addBreadcrumb(
      message: _formatMessage(message),
      level: SentryEventLevel.info,
      category: _tag,
    );
  }

  /// Logs a warning message.
  /// Writes to console and adds a Sentry breadcrumb with optional error data.
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.w(
      _formatMessage(message),
      error: error,
      stackTrace: stackTrace,
    );

    _sentryWrapper?.addBreadcrumb(
      message: _formatMessage(message),
      level: SentryEventLevel.warning,
      category: _tag,
      data: error != null ? {'error': error.toString()} : null,
    );
  }

  /// Logs an error message.
  /// Writes to console and captures either an exception or message to Sentry.
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.e(
      _formatMessage(message),
      error: error,
      stackTrace: stackTrace,
    );

    if (error != null) {
      _sentryWrapper?.captureException(
        error,
        stackTrace: stackTrace,
        tags: {'logger_tag': _tag},
        contexts: {
          'log': {'message': _formatMessage(message)},
        },
      );
    } else {
      _sentryWrapper?.captureMessage(
        _formatMessage(message),
        level: SentryEventLevel.error,
        tags: {'logger_tag': _tag},
      );
    }
  }

  /// Logs a debug message.
  /// Only writes to console (filtered by environment); no Sentry tracking.
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.d(
      _formatMessage(message),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs a fatal error message.
  /// Writes to console and always captures an exception to Sentry with 'fatal' severity.
  void omg(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.f(
      _formatMessage(message),
      error: error,
      stackTrace: stackTrace,
    );

    _sentryWrapper?.captureException(
      error ?? Exception(message),
      stackTrace: stackTrace,
      tags: {'logger_tag': _tag, 'severity': 'fatal'},
      contexts: {
        'log': {'message': _formatMessage(message)},
      },
    );
  }
}

@visibleForTesting
class AppLogFilter extends LogFilter {
  final Config? config;
  final bool isDebugMode;

  AppLogFilter({this.config, bool? debugMode})
    : isDebugMode = debugMode ?? kDebugMode;

  @override
  bool shouldLog(LogEvent event) {
    if (config == null) {
      return true;
    }

    if ((config?.isProd == true) && !isDebugMode) {
      return event.level.index >= Level.warning.index;
    }

    if ((config?.isQa == true) && !isDebugMode) {
      return event.level.index >= Level.info.index;
    }

    return true;
  }
}

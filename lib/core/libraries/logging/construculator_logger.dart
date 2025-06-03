import 'package:construculator/core/libraries/logging/interfaces/logger.dart';
import 'package:logger/logger.dart' as log_package;

// Default implementation for the AppLogger interface.
class ConstruculatorLoggerImpl implements AppLogger {
  final String _tag;
  final log_package.Logger _internalLogger; // The actual logger instance from the logger package

  // Private constructor to be used by the factory and the tag method.
  ConstruculatorLoggerImpl._private(this._tag, this._internalLogger);

  // Public constructor: creates the underlying logger instance.
  // The initial tag can be a default one.
  ConstruculatorLoggerImpl({String initialTag = 'App'}) 
      : _tag = initialTag,
        _internalLogger = log_package.Logger(
          // TODO: Revisit advanced log filtering and output based on Environment 
          // once AppConfig is initialized and Environment is known. 
          // For now, using a simple default configuration.
          filter: log_package.ProductionFilter(), // Default to production filter (logs info and above)
          printer: log_package.PrettyPrinter(
            methodCount: 1,
            errorMethodCount: 5,
            lineLength: 80,
            colors: true,
            printEmojis: true,
          ),
          output: log_package.ConsoleOutput(), // Default to console output
        );

  @override
  AppLogger tag(String newTag) {
    // Return a new instance with the new tag, sharing the same _internalLogger configuration.
    return ConstruculatorLogger._private(newTag, _internalLogger);
  }

  @override
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.i('[$_tag] $message', error: error, stackTrace: stackTrace);
  }

  @override
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.w('[$_tag] $message', error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.e('[$_tag] $message', error: error, stackTrace: stackTrace);
  }

  @override
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _internalLogger.d('[$_tag] $message', error: error, stackTrace: stackTrace);
  }
} 
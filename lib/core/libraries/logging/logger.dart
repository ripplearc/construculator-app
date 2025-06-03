// coverage:ignore-file 
import 'package:construculator/core/libraries/logging/interfaces/ilogger.dart';
import 'package:logger/logger.dart' as log_package;

// TODO: Revisit advanced log filtering and output based on Environment 
// once AppConfig is initialized and Environment is known. Currently uses default setup.

class LoggerImpl implements ILogger {
  final String tag;
  final log_package.Logger _logger;

  // Removed static _instances and factory for now to simplify DI with Modular.
  // If tagged instances are needed widely via a service locator pattern, 
  // the factory can be reintroduced carefully or managed via Modular's factory bindings.

  LoggerImpl(this.tag)
    : _logger = log_package.Logger(
        // Using default filter and console output to avoid AppConfig dependency during construction.
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
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d('[$tag] $message', error: error, stackTrace: stackTrace);
  }

  @override
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('[$tag] $message', error: error, stackTrace: stackTrace);
  }

  @override
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w('[$tag] $message', error: error, stackTrace: stackTrace);
  }

  @override
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);
  }

  // The specific `log` method from the original Logger, if needed, can be added to ILogger interface.
  // For now, sticking to the common debug, info, warning, error.
  /*
  void log(
    log_package.Level level,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _logger.log(level, '[$tag] $message', error: error, stackTrace: stackTrace);
  }
  */
}

// The _AppLogFilter and _getLogOutput are commented out as they depended on AppConfig.instance.
// This functionality needs to be re-introduced in a DI-friendly way.
/*
class _AppLogFilter extends log_package.LogFilter {
  @override
  bool shouldLog(log_package.LogEvent event) {
    // This needs access to the current Environment, 
    // which AppConfig will determine after its own initialization.
    // Placeholder logic:
    // if (currentEnvironment == Environment.prod) { 
    //   return event.level.index >= log_package.Level.warning.index;
    // }
    // return true;
    return true; // Defaulting to log everything for now
  }
}

log_package.LogOutput _getLogOutput() {
  // Also needs Environment info.
  // Placeholder:
  // if (currentEnvironment == Environment.dev) {
  //   return log_package.MultiOutput([log_package.ConsoleOutput()]);
  // }
  return log_package.ConsoleOutput();
}
*/

// coverage:ignore-file 
import 'package:construculator/core/config/app_config.dart';
import 'package:logger/logger.dart' as log_package;

class Logger {
  final String tag;
  final log_package.Logger _logger;
  static final Map<String, Logger> _instances = {};
  factory Logger(String tag) {
    return _instances.putIfAbsent(tag, () => Logger._internal(tag));
  }
  Logger._internal(this.tag)
    : _logger = log_package.Logger(
        filter: _AppLogFilter(),
        printer: log_package.PrettyPrinter(
          methodCount: 1,
          errorMethodCount: 5,
          lineLength: 80,
          colors: true,
          printEmojis: true,
        ),
        output: _getLogOutput(),
      );
  static log_package.LogOutput _getLogOutput() {
    if (AppConfig.instance.isDev) {
      return log_package.MultiOutput([log_package.ConsoleOutput()]);
    }
    return log_package.ConsoleOutput();
  }

  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d('[$tag] $message', error: error, stackTrace: stackTrace);
  }

  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('[$tag] $message', error: error, stackTrace: stackTrace);
  }

  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w('[$tag] $message', error: error, stackTrace: stackTrace);
  }

  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);
  }

  void log(
    log_package.Level level,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _logger.log(level, '[$tag] $message', error: error, stackTrace: stackTrace);
  }
}

class _AppLogFilter extends log_package.LogFilter {
  @override
  bool shouldLog(log_package.LogEvent event) {
    if (AppConfig.instance.isProd) {
      return event.level.index >= log_package.Level.warning.index;
    }

    if (AppConfig.instance.isQa) {
      return event.level.index >= log_package.Level.info.index;
    }

    return true;
  }
}

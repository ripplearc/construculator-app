abstract class ILogger {
  void info(String message, [dynamic error, StackTrace? stackTrace]);
  void warning(String message, [dynamic error, StackTrace? stackTrace]);
  void error(String message, [dynamic error, StackTrace? stackTrace]);
  void debug(String message, [dynamic error, StackTrace? stackTrace]);
  // You can add other methods like verbose, wtf, etc., if needed.
} 
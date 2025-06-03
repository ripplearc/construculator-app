// The AppLogger interface defines the contract for logging operations.
// It supports standard logging levels and allows for tagging to contextualize log messages.
abstract class AppLogger {
  // Returns a new AppLogger instance (or a reconfigured one) that will use the specified tag.
  // This allows for chaining: logger.tag("MyFeature").info("Log message");
  AppLogger tag(String tag);

  void info(String message, [dynamic error, StackTrace? stackTrace]);
  void warning(String message, [dynamic error, StackTrace? stackTrace]);
  void error(String message, [dynamic error, StackTrace? stackTrace]);
  void debug(String message, [dynamic error, StackTrace? stackTrace]);
  // You can add other methods like verbose, wtf, etc., if needed.
} 
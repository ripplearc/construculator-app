// The Logger interface defines the contract for logging operations.
// It supports standard logging levels and allows for tagging and custom emoji/prefix for log messages.
abstract class Logger {
  // Returns a new Logger instance that will use the specified tag.
  Logger tag(String tag);
  
  // Returns a new Logger instance that will use the specified emoji/prefix string.
  Logger emoji(String emoji);

  // Returns a new Logger instance with the default tag and emoji prefix.
  // this is useful for logging messages without having to override tag and emoji prefix.
  Logger fresh();

  void info(String message, [dynamic error, StackTrace? stackTrace]);
  void warning(String message, [dynamic error, StackTrace? stackTrace]);
  void error(String message, [dynamic error, StackTrace? stackTrace]);
  void debug(String message, [dynamic error, StackTrace? stackTrace]);
  void wtf(String message, [dynamic error, StackTrace? stackTrace]);
  void omg(String message, [dynamic error, StackTrace? stackTrace]);
} 
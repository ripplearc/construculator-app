// A wrapper for the flutter logger package to provide a consistent interface that can be faked for testing.
abstract class LoggerWrapper {
  void i(String message, {dynamic error, StackTrace? stackTrace});
  void w(String message, {dynamic error, StackTrace? stackTrace});
  void e(String message, {dynamic error, StackTrace? stackTrace});
  void f(String message, {dynamic error, StackTrace? stackTrace});
  void d(String message, {dynamic error, StackTrace? stackTrace});
}
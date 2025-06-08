import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:stack_trace/stack_trace.dart' as trace;

// Base class for all custom exceptions in this application.
// It implements Dart's built-in `Exception` interface, making all subclasses
// throwable and catchable as standard exceptions.
//
// Why extend `AppException` instead of each custom exception implementing `Exception` directly?
// 1. Shared Properties & Behavior: `AppException` provides common fields like `stackTrace`
//    and the original `exception` (if any was caught and wrapped). It can also offer
//    a default `toString()` implementation or other utility methods, reducing boilerplate
//    in specific exception classes.
// 2. Type Hierarchy for Catching: Allows for `catch (AppException e)` to handle any
//    custom app exception, while still permitting more specific catches like
//    `catch (ServerException e)`. This offers more granular error handling than
//    just `catch (Exception e)` which would include non-app specific exceptions.
// 3. Centralized Logic: Common logic, such as default logging (though specific logging
//    is done in subclasses here), can be centralized in this base class.
// 4. Clarity of Intent: Clearly distinguishes application-defined exceptions from
//    generic Dart or third-party exceptions.
abstract class AppException implements Exception {
  final trace.Trace stackTrace;
  final Exception exception;

  AppException(this.stackTrace, this.exception);

  @override
  String toString() {
    final message = exception.toString();
    final t = stackTrace.toString();
    return 'AppException: $message\nOriginating StackTrace:\n$t';
  }
}
/// Exception thrown when a server error occurs.
class ServerException extends AppException {
  final log = AppLogger();
  ServerException(super.stackTrace,super.exception) {
    log.tag('ServerException').error(toString());
  }
}
/// Exception thrown when a client error occurs.
class ClientException extends AppException {
  final log = AppLogger();
  final String message;
  ClientException(super.stackTrace,super.exception,this.message) {
    log.tag('ClientException').warning(toString());
  }
  @override
  String toString() {
    return message;
  }
}

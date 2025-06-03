import 'package:stack_trace/stack_trace.dart' as trace;
import 'package:construculator/core/logging/logger.dart';

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
  final Exception exception; // The original exception, if this AppException wraps another one.

  AppException(this.stackTrace, this.exception);

  // Provides a default string representation including the original exception message and stack trace.
  @override
  String toString() {
    final message = exception.toString();
    final t = stackTrace.toString();
    return 'AppException: $message\nOriginating StackTrace:\n$t';
  }
}

class ServerException extends AppException {
  ServerException(super.stackTrace,super.exception) {
    final log = Logger('SERVER EXCEPTION');
    log.error(toString());
  }
}
class ClientException extends AppException {
  final String message;
  ClientException(super.stackTrace,super.exception,this.message) {
    final log = Logger('CLIENT EXCEPTION');
    log.warning(toString());
  }
  @override
  String toString() {
    return message;
  }
}

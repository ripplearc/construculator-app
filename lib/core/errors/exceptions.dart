import 'package:stack_trace/stack_trace.dart' as trace;
import 'package:construculator_app_architecture/core/utils/logger.dart';

abstract class AppException implements Exception {
  final trace.Trace stackTrace;
  final Exception exception;

  AppException(this.stackTrace,this.exception);

  @override
  String toString(){
    final message = exception.toString();
    final t = stackTrace.toString();
    return '$message\n\n$t';
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

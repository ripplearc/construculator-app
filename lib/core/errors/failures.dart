abstract class Failure {}

class ServerFailure extends Failure {
  final String message;
  ServerFailure(this.message);
}
class NetworkFailure extends Failure {}
class ValidationFailure extends Failure {
  final String errors;
  ValidationFailure(this.errors);
}
class ClientFailure extends Failure {
  final String message;
  ClientFailure(this.message);
}

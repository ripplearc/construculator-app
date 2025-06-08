import 'package:equatable/equatable.dart';

// Failure represents specific, anticipated error conditions or alternative outcomes of an operation (e.g., a use case or repository method).
// Unlike exceptions (which signify unexpected, disruptive events and are `thrown`),
// `Failure` objects are `returned`, typically as the `Left` side of an `Either<Failure, SuccessType>`.
// This pattern makes error handling explicit and part of the function's contract.
//
// Key Difference between `Failure` (with `Either`) and `AppException`:
//    - `Failure`: Represents *expected/anticipated* alternative outcomes. Handled by checking the
//      result of a function (e.g., `result.isLeft()` or `result.fold(...)`).
//    - `AppException`: Represents *unexpected/exceptional* events that disrupt normal flow.
//      Handled using `try-catch` blocks.

abstract class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => [];
}

/// Failure thrown when a server error occurs.
class ServerFailure extends Failure {
  final String message;
  const ServerFailure(this.message);
}
/// Failure thrown when a network error occurs.
class NetworkFailure extends Failure {}
/// Failure thrown when a validation error occurs.
class ValidationFailure extends Failure {
  final String errors;
  const ValidationFailure(this.errors);
}
/// Failure thrown when a client error occurs.
class ClientFailure extends Failure {
  final String message;
  const ClientFailure(this.message);
}

import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:equatable/equatable.dart';

/// Failure represents specific, anticipated error conditions or alternative outcomes of an operation (e.g., a use case or repository method).
/// Unlike exceptions (which signify unexpected, disruptive events and are `thrown`),
/// `Failure` objects are `returned`, typically as the `Left` side of an `Either<Failure, SuccessType>`.
/// This pattern makes error handling explicit and part of the function's contract.
///
/// Key Difference between `Failure` (with `Either`) and `AppException`:
///    - `Failure`: Represents *expected/anticipated* alternative outcomes. Handled by checking the
///      result of a function (e.g., `result.isLeft()` or `result.fold(...)`).
///    - `AppException`: Represents *unexpected/exceptional* events that disrupt normal flow.
///      Handled using `try-catch` blocks.
abstract class Failure extends Equatable {
  /// Creates a new [Failure]
  const Failure();

  /// The properties of the failure
  @override
  List<Object?> get props => [];
}

/// Failure thrown when a server error occurs.
///
/// Return this failure when a method call throws a [ServerException]
class ServerFailure extends Failure {}

/// Failure thrown when a network error occurs.
///
/// Return this failure if an active network is required but none is available.
class NetworkFailure extends Failure {}

/// Failure thrown when a client error occurs.
///
/// Return this failure if a method call throws a [ClientException]
/// The UI can extract the message from this failure and display it to the user.
class ClientFailure extends Failure {}

/// Failure thrown when a rate limit error occurs.
class RateLimitFailure extends Failure {}

/// Failure thrown when a user is not found.
class UserNotFoundFailure extends Failure {}

/// Failure thrown when an unexpected error occurs.
class UnexpectedFailure extends Failure {}

/// Failure thrown when an authentication error occurs.
class AuthFailure extends Failure {
  /// The type of authentication error that occurred.
  final AuthErrorType errorType;
  const AuthFailure({required this.errorType});
}

/// Failure thrown when an estimation error occurs.
class EstimationFailure extends Failure {
  /// The type of estimation error that occurred.
  final EstimationErrorType errorType;
  const EstimationFailure({required this.errorType});

  @override
  List<Object?> get props => [errorType];
}

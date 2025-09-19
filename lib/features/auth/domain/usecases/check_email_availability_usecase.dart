// coverage:ignore-file
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

/// This is the use case for checking the availability of an email address.
class CheckEmailAvailabilityUseCase {
  final AuthManager authManager;

  CheckEmailAvailabilityUseCase(this.authManager);

  /// Checks the availability of an email address using the auth manager.
  ///
  /// Returns a [Future] that emits an [Either] containing a [Failure] or an [AuthResult<bool>].
  Future<Either<Failure, AuthResult<bool>>> call(String email) async {
    final result = await authManager.isEmailRegistered(email);
    if (!result.isSuccess) {
      final errorType = result.errorType;
      if (errorType == null) {
        return Left(UnexpectedFailure());
      }
      return Left(AuthFailure(errorType: errorType));
    }
    return Right(AuthResult.success(result.data));
  }
}

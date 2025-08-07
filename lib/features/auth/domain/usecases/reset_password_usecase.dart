import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// This is the use case for resetting a user's password.
class ResetPasswordUseCase  {
  final AuthManager authManager;

  ResetPasswordUseCase(this.authManager);

  /// Resets a user's password using the auth manager.
  /// Accepts an email as a parameter.
  /// 
  /// Returns a [Future] that emits an [Either] containing a [Failure] or an [void].
  Future<Either<Failure, void>> call(String email) async {
    final result = await authManager.resetPassword(email);
    if (!result.isSuccess) {
      final errorType = result.errorType;
      if (errorType == null) {
        return Left(UnexpectedFailure());
      }
      return Left(AuthFailure(errorType: errorType));
    }
    return Right(null);
  }
} 
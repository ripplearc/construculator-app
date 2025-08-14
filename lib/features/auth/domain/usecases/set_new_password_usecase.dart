import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// This is the use case for setting a new password.
class SetNewPasswordUseCase {
  final AuthManager authManager;

  SetNewPasswordUseCase(this.authManager);

  /// Sets a new password for the specified email using the auth manager.
  /// Accepts an email and a new password as parameters.
  /// 
  /// Returns a [Future] that emits an [Either] containing a [Failure] or an [void].
  Future<Either<Failure, void>> call(String email,String newPassword) async {
    final result = await authManager.updateUserPassword(newPassword);
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

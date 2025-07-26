import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:dartz/dartz.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// This is the use case for logging in a user.
class LoginUseCase {
  final AuthManager authManager;

  LoginUseCase(this.authManager);

  /// Logs in a user using the auth manager.
  /// Accepts an email and password as parameters.
  /// 
  /// Returns a [Future] that emits an [Either] containing a [Failure] or an [UserCredential].
  Future<Either<Failure, UserCredential>> call(String email, String password) async {
    final result = await authManager.loginWithEmail(email, password);
    if (!result.isSuccess) {
      final errorType = result.errorType;
      if (errorType == null) {
        return Left(UnexpectedFailure());
      }
      return Left(AuthFailure(errorType: errorType));
    }
    final credential = result.data;
    if (credential == null) {
      return Left(UserNotFoundFailure());
    }
    return Right(credential);
  }
}
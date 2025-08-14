// coverage:ignore-file
import 'package:construculator/features/auth/domain/usecases/params/create_account_usecase_params.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// This is the use case for creating a new user account.
class CreateAccountUseCase {
  final AuthManager authManager;

  CreateAccountUseCase(this.authManager);

  /// Creates a new user account using the auth manager.
  /// Accepts a [CreateAccountUseCaseParams] object as a parameter.
  /// 
  /// Returns a [Future] that emits an [Either] containing a [Failure] or an [AuthResult<bool>].
  Future<Either<Failure, void>> call(CreateAccountUseCaseParams params) async {
    // update only the user password
    final updatePasswordResult = await authManager.updateUserPassword(
      params.password,
    );
    if (!updatePasswordResult.isSuccess) {
      if (updatePasswordResult.errorType != AuthErrorType.samePassword) {
        final errorType = updatePasswordResult.errorType;
        if (errorType == null) {
          return Left(UnexpectedFailure());
        }
        return Left(AuthFailure(errorType: errorType));
      }
    }
    final userResult = await authManager.createUserProfile(
      User(
        email: params.email ?? '',
        phone: params.phone,
        countryCode: params.countryCode,
        firstName: params.firstName,
        lastName: params.lastName,
        professionalRole: params.professionalRole,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userStatus: UserProfileStatus.active,
        userPreferences: {},
      ),
    );
    if (!userResult.isSuccess) {
      final errorType = userResult.errorType;
      if (errorType == null) {
        return Left(UnexpectedFailure());
      }
      return Left(AuthFailure(errorType: errorType));
    }
    return Right(null);
  }
}

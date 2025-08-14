import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/auth/data/models/professional_role.dart';
import 'package:construculator/libraries/either/either.dart';

/// This is the use case for getting a list of professional roles.
class GetProfessionalRolesUseCase {
  final AuthManager authManager;

  GetProfessionalRolesUseCase(this.authManager);

  /// Retrieves a list of professional roles using the auth repository.
  /// 
  /// Returns a [Future] that emits an [Either] containing a [Failure] or a list of [ProfessionalRole].
  Future<Either<Failure, List<ProfessionalRole>>> call() async {
    final rolesResult = await authManager.getProfessionalRoles();
    if (!rolesResult.isSuccess) {
      final errorType = rolesResult.errorType;
      if (errorType == null) {
        return Left(UnexpectedFailure());
      }
      return Left(AuthFailure(errorType: errorType));
    }
    final roles = rolesResult.data;
    if (roles == null) {
      return Left(UnexpectedFailure());
    }
    return Right(roles);
  }
} 
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/features/auth/domain/entities/professional_role.dart';
import 'package:construculator/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

/// This is the use case for getting a list of professional roles.
class GetProfessionalRolesUseCase {
  final AuthRepository repository;

  GetProfessionalRolesUseCase(this.repository);

  /// Retrieves a list of professional roles using the auth repository.
  /// 
  /// Returns a [Future] that emits an [Either] containing a [Failure] or a list of [ProfessionalRole].
  Future<Either<Failure, List<ProfessionalRole>>> call() async {
    return await repository.getProfessionalRoles();
  }
} 
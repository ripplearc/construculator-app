import 'package:construculator/libraries/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:construculator/features/auth/domain/entities/professional_role.dart';

/// This is the contract for the authentication repository.
abstract class AuthRepository {
  /// Retrieves a list of professional roles.
  /// 
  /// Returns a [Future] that emits an [Either] containing a [Failure] or a list of [ProfessionalRole].
  Future<Either<Failure, List<ProfessionalRole>>> getProfessionalRoles();
} 
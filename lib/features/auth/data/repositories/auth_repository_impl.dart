import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:dartz/dartz.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:construculator/features/auth/domain/repositories/auth_repository.dart';
import 'package:construculator/features/auth/domain/entities/professional_role.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppLogger logger = AppLogger().tag('AuthRepositoryImpl');
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});
  @override
  Future<Either<Failure, List<ProfessionalRole>>> getProfessionalRoles() async {
    try {
      final roleModels = await remoteDataSource.getProfessionalRoles();
      return Right(roleModels.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      logger.error('ServerException: ${e.toString()}', e);
      return Left(ServerFailure());
    }
  }
}

import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';

class GetProjectUseCase {
  final ProjectRepository _projectRepository;

  GetProjectUseCase(this._projectRepository);

  Future<Either<Failure, Project>> call(String projectId) async {
    try {
      final project = await _projectRepository.getProject(projectId);
      return Right(project);
    } on TimeoutException {
      return Left(NetworkFailure());
    } on SocketException {
      return Left(NetworkFailure());
    } on ServerException {
      return Left(ServerFailure());
    } on NetworkException {
      return Left(NetworkFailure());
    } catch (_) {
      return Left(UnexpectedFailure());
    }
  }
}

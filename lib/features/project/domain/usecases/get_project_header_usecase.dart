// coverage:ignore-file

import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';

/// Use case for retrieving a project by its ID.
///
/// This use case encapsulates the business logic for fetching a project
/// from the repository. It follows the single responsibility principle
/// by focusing solely on the operation of getting a project.
class GetProjectUseCase {
  final ProjectRepository _projectRepository;

  GetProjectUseCase(this._projectRepository);

  /// Retrieves a project by its unique identifier.
  ///
  /// Returns a [Future] that emits an [Either] containing a [Failure] or a [Project] entity.
  Future<Either<Failure, Project>> call(String projectId) async {
    try {
      final project = await _projectRepository.getProject(projectId);
      return Right(project);
    } catch (e) {
      // Handle different types of exceptions and convert to appropriate failures
      return Left(UnexpectedFailure());
    }
  }
}

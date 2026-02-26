import 'dart:async';
import 'dart:io';

import 'package:construculator/features/project/domain/entities/project_header_data.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';

/// Use case for retrieving project header data including project info and user profile.
///
/// This use case encapsulates the business logic for fetching both the project
/// and the current user's profile information needed to render the project header.
/// It follows the single responsibility principle by focusing solely on gathering
/// all data required for the project header UI.
class GetProjectHeaderUseCase {
  final ProjectRepository _projectRepository;
  final AuthRepository _authRepository;

  GetProjectHeaderUseCase(this._projectRepository, this._authRepository);

  /// Retrieves project header data by project ID.
  ///
  /// Fetches both the project information and the current user's profile.
  /// Returns a [Future] that emits an [Either] containing a [Failure] or [ProjectHeaderData].
  Future<Either<Failure, ProjectHeaderData>> call(String projectId) async {
    try {
      final project = await _projectRepository.getProject(projectId);

      final credentials = _authRepository.getCurrentCredentials();
      final userId = credentials?.id;

      final userProfile = userId != null
          ? await _authRepository.getUserProfile(userId)
          : null;

      return Right(
        ProjectHeaderData(project: project, userProfile: userProfile),
      );
    } on TimeoutException {
      return Left(NetworkFailure());
    } on SocketException {
      return Left(NetworkFailure());
    } on ServerException {
      return Left(ServerFailure());
    } on NetworkException {
      return Left(NetworkFailure());
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
}

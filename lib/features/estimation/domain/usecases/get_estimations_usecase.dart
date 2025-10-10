// coverage:ignore-file
import 'dart:async';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Use case for retrieving all cost estimations for a specific project.
class GetEstimationsUseCase {
  final CostEstimationRepository _repository;

  GetEstimationsUseCase(this._repository);

  /// Retrieves all cost estimations for the specified project.
  ///
  /// [projectId] - The unique identifier of the project to get estimations for.
  ///
  /// Returns a [Future] that emits an [Either] containing a [Failure] or a [List<CostEstimate>].
  Future<Either<Failure, List<CostEstimate>>> call(String projectId) async {
    try {
      final estimations = await _repository.getEstimations(projectId);
      return Right(estimations);
    } on ServerException {
      return Left(ServerFailure());
    } on ClientException {
      return Left(ClientFailure());
    } on NetworkException {
      return Left(NetworkFailure());
    } on TimeoutException {
      return Left(NetworkFailure());
    } on TypeError {
      return Left(ClientFailure());
    } catch (e) {
      return Left(UnexpectedFailure());
    }
  }
}

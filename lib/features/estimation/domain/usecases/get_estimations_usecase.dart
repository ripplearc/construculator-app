// coverage:ignore-file
import 'dart:async';
import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

/// Use case for retrieving all cost estimations for a specific project.
/// 
/// This use case encapsulates the business logic for fetching cost estimations
/// from the repository and handles any potential failures that might occur
/// during the data retrieval process.
class GetEstimationsUseCase {
  final CostEstimationRepository _repository;
  static final _logger = AppLogger().tag('GetEstimationsUseCase');

  GetEstimationsUseCase(this._repository);

  /// Retrieves all cost estimations for the specified project.
  /// 
  /// [projectId] - The unique identifier of the project to get estimations for.
  /// 
  /// Returns a [Future] that emits an [Either] containing a [Failure] or a [List<CostEstimate>].
  Future<Either<Failure, List<CostEstimate>>> call(String projectId) async {
    try {
      _logger.debug('Getting cost estimations for project: $projectId');
      final estimations = await _repository.getEstimations(projectId);
      _logger.debug('Successfully retrieved ${estimations.length} cost estimations for project: $projectId');
      return Right(estimations);
    } on ServerException {
      _logger.error('Error getting cost estimations for project $projectId: ServerException');
      return Left(ServerFailure());
    } on ClientException {
      _logger.error('Error getting cost estimations for project $projectId: ClientException');
      return Left(ClientFailure());
    } on NetworkException {
      _logger.error('Error getting cost estimations for project $projectId: NetworkException');
      return Left(NetworkFailure());
    } on TimeoutException {
      _logger.error('Error getting cost estimations for project $projectId: TimeoutException');
      return Left(NetworkFailure());
    } on TypeError {
      _logger.error('Error getting cost estimations for project $projectId: TypeError');
      return Left(ClientFailure());
    } catch (e) {
      _logger.error('Error getting cost estimations for project $projectId: $e');
      return Left(UnexpectedFailure());
    }
  }
}


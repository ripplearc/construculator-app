// coverage:ignore-file

import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
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
    return await _repository.getEstimations(projectId);
  }
}

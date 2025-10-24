// coverage:ignore-file

import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';

/// Use case for creating a new cost estimation.
///
/// This use case encapsulates the business logic for creating cost estimations
/// and handles the setup of default values for new estimations. It ensures
/// that all required fields are properly initialized with appropriate defaults.
class AddCostEstimationUseCase {
  final CostEstimationRepository _repository;
  final Clock _clock;
  static final _logger = AppLogger().tag('AddCostEstimationUseCase');

  AddCostEstimationUseCase(this._repository, this._clock);

  /// Creates a new cost estimation with the specified name.
  ///
  /// [estimationName] - The name for the new cost estimation.
  /// [projectId] - The ID of the project this estimation belongs to.
  /// [creatorUserId] - The ID of the user creating this estimation.
  ///
  /// Returns a [Future] that emits an [Either] containing a [Failure] or the created [CostEstimate].
  Future<Either<Failure, CostEstimate>> call({
    required String estimationName,
    required String projectId,
    required String creatorUserId,
  }) async {
    _logger.debug(
      'Creating cost estimation: $estimationName for project: $projectId',
    );

    final now = _clock.now();

    final defaultMarkupConfiguration = MarkupConfiguration(
      overallType: MarkupType.overall,
      overallValue: const MarkupValue(
        type: MarkupValueType.percentage,
        value: 0.0,
      ),
    );

    final costEstimation = CostEstimate(
      id: '',
      projectId: projectId,
      estimateName: estimationName,
      creatorUserId: creatorUserId,
      markupConfiguration: defaultMarkupConfiguration,
      lockStatus: const LockStatus.unlocked(),
      createdAt: now,
      updatedAt: now,
    );

    final result = await _repository.createEstimation(costEstimation);

    return result.fold(
      (failure) {
        _logger.error('Error creating cost estimation: $failure');
        return Left(failure);
      },
      (createdEstimation) {
        _logger.debug(
          'Successfully created cost estimation: ${createdEstimation.id}',
        );
        return Right(createdEstimation);
      },
    );
  }
}

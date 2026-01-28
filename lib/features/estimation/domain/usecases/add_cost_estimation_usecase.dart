import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';

/// Use case for creating a new cost estimation.
///
/// This use case encapsulates the business logic for creating cost estimations
/// and handles the setup of default values for new estimations. It ensures
/// that all required fields are properly initialized with appropriate defaults.
class AddCostEstimationUseCase {
  final CostEstimationRepository _repository;
  final AuthRepository _authRepository;
  final Clock _clock;
  final AppLogger _logger;

  AddCostEstimationUseCase(
    this._repository,
    this._authRepository,
    this._clock,
    AppLogger appLogger,
  ) : _logger = appLogger.tag('AddCostEstimationUseCase');

  /// Creates a new cost estimation with the specified name.
  ///
  /// [estimationName] - The name for the new cost estimation.
  /// [projectId] - The ID of the project this estimation belongs to.
  ///
  /// Returns a [Future] that emits an [Either] containing a [Failure] or the created [CostEstimate].
  Future<Either<Failure, CostEstimate>> call({
    required String estimationName,
    required String projectId,
  }) async {
    _logger.debug(
      'Creating cost estimation: $estimationName for project: $projectId',
    );

    User? userProfile;
    UserCredential? credentials;
    try {
      credentials = _authRepository.getCurrentCredentials();
      if (credentials == null) {
        _logger.error(
          'Error getting user credentials: User credentials are null',
        );
        return const Left(
          EstimationFailure(errorType: EstimationErrorType.authenticationError),
        );
      }
      userProfile = await _authRepository.getUserProfile(credentials.id);

      if (userProfile == null) {
        _logger.error(
          'User profile not found for credential: ${credentials.id}',
        );
        return const Left(
          EstimationFailure(errorType: EstimationErrorType.authenticationError),
        );
      }
    } catch (e) {
      _logger.error(
        'User profile not found for credential: ${credentials?.id}',
      );
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.authenticationError),
      );
    }

    final creatorUserId = userProfile.id;
    if (creatorUserId == null || creatorUserId.isEmpty) {
      _logger.error('User ID is null or empty');
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.authenticationError),
      );
    }

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

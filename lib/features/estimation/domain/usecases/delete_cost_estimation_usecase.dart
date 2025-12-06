import 'dart:async';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

/// Use case for deleting a cost estimation.
///
/// This use case encapsulates the business logic for deleting cost estimations.
/// It handles error cases and converts exceptions to appropriate failure types.
class DeleteCostEstimationUseCase {
  final CostEstimationRepository _repository;
  static final _logger = AppLogger().tag('DeleteCostEstimationUseCase');

  DeleteCostEstimationUseCase(this._repository);

  /// Deletes a cost estimation by its ID.
  ///
  /// [estimationId] - The ID of the cost estimation to delete.
  ///
  /// Returns a [Future] that emits an [Either] containing a [Failure] or void on success.
  Future<Either<Failure, void>> call({required String estimationId}) async {
    try {
      _logger.debug('Deleting cost estimation: $estimationId');

      await _repository.deleteEstimation(estimationId);

      _logger.debug('Successfully deleted cost estimation: $estimationId');

      return const Right(null);
    } on ServerException {
      _logger.error('Error deleting cost estimation: ServerException');
      return Left(ServerFailure());
    } on ClientException {
      _logger.error('Error deleting cost estimation: ClientException');
      return Left(ClientFailure());
    } on NetworkException {
      _logger.error('Error deleting cost estimation: NetworkException');
      return Left(NetworkFailure());
    } on TimeoutException {
      _logger.error('Error deleting cost estimation: TimeoutException');
      return Left(NetworkFailure());
    } on TypeError {
      _logger.error('Error deleting cost estimation: TypeError');
      return Left(ClientFailure());
    } catch (e) {
      _logger.error('Error deleting cost estimation: $e');
      return Left(UnexpectedFailure());
    }
  }
}

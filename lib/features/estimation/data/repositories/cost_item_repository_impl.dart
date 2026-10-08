import 'dart:async';
import 'dart:io';

import 'package:construculator/features/estimation/data/data_source/interfaces/cost_item_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

class CostItemRepositoryImpl implements CostItemRepository {
  CostItemRepositoryImpl({required this.dataSource});

  final CostItemDataSource dataSource;
  static final _logger = AppLogger().tag('CostItemRepositoryImpl');

  /// The most rows the API returns for one request. A full page may have
  /// dropped rows, so a sum over it could be too small.
  static const _maxRowsPerRequest = 1000;

  @override
  Future<Either<Failure, CostItem>> createCostItem(CostItem item) async {
    try {
      final dto = CostItemDto.fromEntity(item);
      final created = await dataSource.createCostItem(dto);
      return Right(created.toEntity());
    } catch (e) {
      return _handleError(e, 'creating cost item');
    }
  }

  @override
  Future<Either<Failure, double>> getEstimateItemsTotal(
    String estimateId,
  ) async {
    try {
      final totals = await dataSource.fetchItemTotalCostsByEstimateId(
        estimateId,
      );
      if (totals.length >= _maxRowsPerRequest) {
        _logger.error(
          'Cost item totals for $estimateId fill the $_maxRowsPerRequest row limit, so the sum may be too small',
        );
        return const Left(
          EstimationFailure(
            errorType: EstimationErrorType.unexpectedDatabaseError,
          ),
        );
      }
      final cents = totals.fold<int>(0, (sum, t) => sum + (t * 100).round());
      return Right(cents / 100);
    } catch (e) {
      return _handleError(e, 'summing cost items');
    }
  }

  Left<Failure, T> _handleError<T>(Object error, String operation) {
    if (error is TimeoutException) {
      _logger.error(
        'Timeout error $operation: message=${error.message}, duration=${error.duration}',
      );
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.timeoutError),
      );
    } else if (error is SocketException) {
      _logger.warning(
        'Connection error $operation: message=${error.message}',
      );
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.connectionError),
      );
    } else if (error is FormatException) {
      _logger.error(
        'Parsing error $operation: message=${error.message}',
      );
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.parsingError),
      );
    } else if (error is TypeError) {
      _logger.error('Parsing error $operation: ${error.toString()}');
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.parsingError),
      );
    } else {
      _logger.error('Unexpected error $operation: $error');
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.unexpectedError),
      );
    }
  }
}

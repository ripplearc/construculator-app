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

  Left<Failure, CostItem> _handleError(Object error, String operation) {
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

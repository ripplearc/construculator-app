import 'dart:async';
import 'dart:io';

import 'package:construculator/features/estimation/data/data_source/interfaces/cost_item_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/local_cost_item_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

/// Reads and writes cost lines: the server through [dataSource], and this
/// phone's own database through [localDataSource].
class CostItemRepositoryImpl implements CostItemRepository {
  CostItemRepositoryImpl({
    required this.dataSource,
    required this.localDataSource,
  });

  /// The server's cost lines.
  final CostItemDataSource dataSource;

  /// The cost lines saved on this phone.
  final LocalCostItemDataSource localDataSource;
  static final _logger = AppLogger().tag('CostItemRepositoryImpl');

  static const _unexpectedFailure = EstimationFailure(
    errorType: EstimationErrorType.unexpectedError,
  );

  static const _phoneStorageFailure = EstimationFailure(
    errorType: EstimationErrorType.unexpectedDatabaseError,
  );

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
  Future<Either<Failure, CostItem>> addCostItemOnPhone(CostItem item) async {
    if (item.id.isEmpty) return const Left(_unexpectedFailure);
    try {
      await localDataSource.saveCostItemOnPhone(CostItemDto.fromEntity(item));
      return Right(item);
    } catch (_) {
      return const Left(_phoneStorageFailure);
    }
  }

  // TODO: [CA-1290] show the grey Not synced line and the sync summary from this set. https://ripplearc.youtrack.cloud/issue/CA-1290
  @override
  Stream<Either<Failure, Set<String>>> watchNotSyncedCostItemIds(
    String estimateId,
  ) {
    return localDataSource
        .watchCostItemIdsWithPendingUpload(estimateId)
        .transform(
          StreamTransformer<
            Set<String>,
            Either<Failure, Set<String>>
          >.fromHandlers(
            handleData: (notSynced, sink) => sink.add(Right(notSynced)),
            handleError: (error, stack, sink) {
              _logger.error(
                'Failed to watch cost lines not synced',
                error,
                stack,
              );
              sink.add(const Left(_phoneStorageFailure));
            },
          ),
        );
  }

  @override
  Future<Either<Failure, double>> getEstimateItemsTotal(
    String estimateId,
  ) async {
    final Map<String, double> onThisPhone;
    try {
      final lines = await localDataSource.loadCostItemsByEstimateId(estimateId);
      onThisPhone = {for (final line in lines) line.id: line.itemTotalCost};
    } catch (_) {
      return const Left(_phoneStorageFailure);
    }
    try {
      final onServer = await dataSource.fetchItemTotalCostsByEstimateId(
        estimateId,
      );
      if (onServer.length >= _maxRowsPerRequest) {
        return _rowLimitFailure(estimateId);
      }
      return Right(_sumToCent({...onServer, ...onThisPhone}));
    } on TimeoutException catch (e) {
      return _totalFromThisPhone(onThisPhone, e);
    } on SocketException catch (e) {
      return _totalFromThisPhone(onThisPhone, e);
    } catch (e) {
      return _handleError(e, 'summing cost items');
    }
  }

  Either<Failure, double> _totalFromThisPhone(
    Map<String, double> onThisPhone,
    Object reason,
  ) {
    // TODO: [CA-648] read every line from the phone once a sync stream delivers cost_items. https://ripplearc.youtrack.cloud/issue/CA-648
    _logger.warning(
      'Server unreachable ($reason), so the total counts only the '
      '${onThisPhone.length} lines on this phone',
    );
    return Right(_sumToCent(onThisPhone));
  }

  static double _sumToCent(Map<String, double> totalsById) =>
      totalsById.values.fold<int>(0, (sum, t) => sum + (t * 100).round()) / 100;

  @override
  Future<Either<Failure, List<CostItem>>> getCostItemsForEstimate(
    String estimateId,
  ) async {
    try {
      final dtos = await dataSource.fetchCostItemsByEstimateId(
        estimateId: estimateId,
      );
      if (dtos.length >= _maxRowsPerRequest) {
        return _rowLimitFailure(estimateId);
      }
      return Right(dtos.map((dto) => dto.toEntity()).toList());
    } catch (e) {
      return _handleError(e, 'fetching cost items');
    }
  }

  Left<Failure, T> _rowLimitFailure<T>(String estimateId) {
    _logger.error(
      'Cost items for $estimateId fill the $_maxRowsPerRequest row limit, so rows may be missing',
    );
    return const Left(
      EstimationFailure(errorType: EstimationErrorType.unexpectedDatabaseError),
    );
  }

  @override
  Future<Either<Failure, String?>> getEstimateNameKeepingEquipmentRate({
    required String companyId,
    required String itemName,
    required EquipmentPricingMethod pricingMethod,
    required double rateAmount,
  }) async {
    try {
      return Right(
        await dataSource.fetchNewestEstimateNameByEquipmentRate(
          companyId: companyId,
          itemName: itemName,
          pricingMethod: pricingMethod.toJson(),
          rateAmount: rateAmount,
        ),
      );
    } catch (e) {
      return _handleError(e, 'looking up the estimate keeping a rate');
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
      _logger.warning('Connection error $operation: message=${error.message}');
      return const Left(
        EstimationFailure(errorType: EstimationErrorType.connectionError),
      );
    } else if (error is FormatException) {
      _logger.error('Parsing error $operation: message=${error.message}');
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

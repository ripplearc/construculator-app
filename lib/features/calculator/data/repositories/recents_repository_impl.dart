import 'dart:async';

import 'package:construculator/features/calculator/data/data_source/interfaces/local_recents_data_source.dart';
import 'package:construculator/features/calculator/domain/repositories/recents_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

/// [RecentsRepository] over the local store: turns what the data source
/// throws into a [CalculatorFailure] and hands its watches through.
///
/// The watches are the data source's own streams: the source tracks and
/// ends them, so [dispose] delegates to it and only logs a source that
/// fails to close, as the trade stores repository does.
class RecentsRepositoryImpl implements RecentsRepository {
  static final _logger = AppLogger().tag('RecentsRepositoryImpl');

  final LocalRecentsDataSource _dataSource;

  /// Creates a repository over a local data source.
  RecentsRepositoryImpl({required this._dataSource});

  @override
  Stream<List<Quantity>> watchRecents(String drawer) =>
      _dataSource.watchRecents(drawer);

  @override
  Future<Either<Failure, void>> saveRecents(
    String drawer,
    List<Quantity> values,
  ) async {
    try {
      await _dataSource.replaceRecents(drawer, values);
      return const Right(null);
    } catch (error) {
      _logger.error('Error saving the $drawer recents: $error');
      return const Left(
        CalculatorFailure(errorType: CalculatorErrorType.storageError),
      );
    }
  }

  @override
  void dispose() => unawaited(
    _dataSource.dispose().catchError((Object error, StackTrace stackTrace) {
      _logger.warning('Failed to dispose the recents data source: $error');
    }),
  );
}

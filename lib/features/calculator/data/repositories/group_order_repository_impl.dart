import 'dart:async';

import 'package:construculator/features/calculator/data/data_source/interfaces/local_group_order_data_source.dart';
import 'package:construculator/features/calculator/domain/repositories/group_order_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';

/// [GroupOrderRepository] over the local store: lays the stored order over
/// the default, stamps writes from [Clock], and turns what the data source
/// throws into a [CalculatorFailure].
///
/// A stored order is used only when it names exactly this build's groups,
/// each once: an order written by a build with other groups, or a row this
/// build cannot read, falls back to the default so the keyboard always
/// shows every group, and is logged as a warning (it is expected after an
/// update). The watches are the data source's own streams; [dispose]
/// delegates to it, as the recents repository does.
class GroupOrderRepositoryImpl implements GroupOrderRepository {
  static final _logger = AppLogger().tag('GroupOrderRepositoryImpl');

  final LocalGroupOrderDataSource _dataSource;
  final Clock _clock;

  /// The groups in the order the keyboard shows them until the user sets
  /// one (UX Design Doc Appendix B).
  final List<String> defaultOrder;

  /// Creates a repository over a local data source, with the order shown
  /// until the user sets one.
  GroupOrderRepositoryImpl({
    required this._dataSource,
    required this._clock,
    required this.defaultOrder,
  });

  @override
  Stream<List<String>> watchGroupOrder() =>
      Stream<List<String>>.multi((controller) {
        final subscription = _dataSource.watchGroupOrder().listen(
          (stored) => controller.add(_shown(stored)),
          onError: (Object error, StackTrace stackTrace) {
            if (error is FormatException) {
              _logger.warning(
                'The stored group order cannot be read; showing the default: '
                '${error.message}',
              );
              controller.add(defaultOrder);
            } else {
              controller.addError(error, stackTrace);
            }
          },
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      });

  @override
  Future<Either<Failure, void>> saveGroupOrder(List<String> order) async {
    try {
      await _dataSource.replaceGroupOrder(order, _clock.now());
      return const Right(null);
    } catch (error, stackTrace) {
      _logger.error('Error saving the group order', error, stackTrace);
      return const Left(
        CalculatorFailure(errorType: CalculatorErrorType.storageError),
      );
    }
  }

  @override
  void dispose() => unawaited(
    _dataSource.dispose().catchError((Object error, StackTrace stackTrace) {
      _logger.warning(
        'Failed to dispose the group order data source',
        error,
        stackTrace,
      );
    }),
  );

  List<String> _shown(List<String>? stored) {
    if (stored == null) return defaultOrder;
    if (_namesEveryGroupOnce(stored)) return stored;
    _logger.warning(
      'The stored group order $stored does not name this build\'s groups '
      '$defaultOrder; showing the default',
    );
    return defaultOrder;
  }

  bool _namesEveryGroupOnce(List<String> order) =>
      order.length == defaultOrder.length &&
      order.toSet().length == order.length &&
      order.every(defaultOrder.contains);
}

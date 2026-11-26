import 'dart:async';

import 'package:construculator/features/calculator/domain/repositories/group_order_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter/foundation.dart';

/// An in-memory [GroupOrderRepository] for BLoC and widget tests: the order
/// saved, the default until one is, and a watch that emits now and after
/// every change.
class FakeGroupOrderRepository implements GroupOrderRepository {
  /// The order shown until one is saved.
  final List<String> defaultOrder;

  /// The order saved, or `null` until one is.
  List<String>? saved;

  /// The failure every save answers when set.
  Failure? saveFailure;

  /// How many times [saveGroupOrder] was called.
  int saveCallCount = 0;

  final _changes = StreamController<void>.broadcast();

  /// Creates a fake showing [defaultOrder] until an order is saved.
  FakeGroupOrderRepository({required this.defaultOrder});

  @override
  Stream<List<String>> watchGroupOrder() =>
      Stream<List<String>>.multi((controller) {
        var last = _shown();
        controller.add(last);
        final subscription = _changes.stream.listen((_) {
          final next = _shown();
          if (listEquals(next, last)) return;
          last = next;
          controller.add(next);
        }, onDone: controller.close);
        controller.onCancel = subscription.cancel;
      });

  @override
  Future<Either<Failure, void>> saveGroupOrder(List<String> order) async {
    saveCallCount++;
    if (saveFailure case final failure?) return Left(failure);
    saved = List.unmodifiable(order);
    if (!_changes.isClosed) _changes.add(null);
    return const Right(null);
  }

  /// Forgets the saved order and the counter; keeps [saveFailure].
  void reset() {
    saved = null;
    saveCallCount = 0;
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  void dispose() {
    unawaited(_changes.close());
  }

  List<String> _shown() => saved ?? defaultOrder;
}

import 'dart:async';

import 'package:construculator/features/calculator/domain/repositories/recents_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Fake [RecentsRepository] for testing the calculator bloc: holds every
/// drawer in memory and lets a test fail the next save.
class FakeRecentsRepository implements RecentsRepository {
  /// The values of every drawer, newest first, by drawer.
  final Map<String, List<Quantity>> drawers = {};

  /// The failure every save answers with while set.
  Failure? saveFailure;

  final _changes = StreamController<void>.broadcast();

  @override
  Stream<List<Quantity>> watchRecents(String drawer) =>
      Stream<List<Quantity>>.multi((controller) {
        controller.add(_read(drawer));
        final subscription = _changes.stream.listen(
          (_) => controller.add(_read(drawer)),
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      });

  @override
  Future<Either<Failure, void>> saveRecents(
    String drawer,
    List<Quantity> values,
  ) async {
    if (saveFailure case final failure?) return Left(failure);
    drawers[drawer] = List.unmodifiable(values);
    if (!_changes.isClosed) _changes.add(null);
    return const Right(null);
  }

  /// Empties every drawer and clears the failure.
  void reset() {
    drawers.clear();
    saveFailure = null;
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  void dispose() {
    unawaited(_changes.close());
  }

  List<Quantity> _read(String drawer) => drawers[drawer] ?? const [];
}

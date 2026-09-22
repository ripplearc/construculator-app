import 'dart:async';

import 'package:construculator/features/calculator/domain/repositories/calculator_preferences_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Fake [CalculatorPreferencesRepository] for tests outside the calculator
/// feature that only need settings to exist: holds them in memory and lets
/// a test drive them from the other side, as a sync from another device
/// would. Tests inside the feature wire the real repository over the auth
/// fakes instead (test-double rule: fake the boundary, not your own code).
class FakeCalculatorPreferencesRepository
    implements CalculatorPreferencesRepository {
  /// The settings every watcher currently sees.
  CalculatorPreferences current = CalculatorPreferences.defaults;

  /// The failure the next saves answer with, or `null` to succeed.
  Failure? saveFailure;

  /// Every settings object handed to [savePreferences], in order.
  final List<CalculatorPreferences> savedPreferences = [];

  final _changes = StreamController<CalculatorPreferences>.broadcast();

  @override
  Stream<CalculatorPreferences> watchPreferences() =>
      Stream<CalculatorPreferences>.multi((controller) {
        controller.add(current);
        final subscription = _changes.stream.listen(
          controller.add,
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      }).distinct();

  @override
  Future<Either<Failure, CalculatorPreferences>> savePreferences(
    CalculatorPreferences preferences,
  ) async {
    savedPreferences.add(preferences);
    if (saveFailure case final failure?) return Left(failure);
    emit(preferences);
    return Right(preferences);
  }

  /// Makes every watcher see [preferences], as a change synced from another
  /// device would.
  void emit(CalculatorPreferences preferences) {
    current = preferences;
    if (!_changes.isClosed) _changes.add(preferences);
  }

  /// Puts the fake back to a fresh install with nothing saved.
  void reset() {
    current = CalculatorPreferences.defaults;
    saveFailure = null;
    savedPreferences.clear();
  }

  @override
  void dispose() {
    unawaited(_changes.close());
  }
}

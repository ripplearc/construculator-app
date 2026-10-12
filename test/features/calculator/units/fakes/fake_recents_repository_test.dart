import 'package:construculator/features/calculator/testing/fake_recents_repository.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeRecentsRepository repository;

  const eightFeet = Length(8 * Length.ticksPerFoot, unit: Unit.foot);
  const tenFeet = Length(10 * Length.ticksPerFoot, unit: Unit.foot);

  setUp(() => repository = FakeRecentsRepository());
  tearDown(() => repository.dispose());

  group('FakeRecentsRepository', () {
    test('a watch sees the drawer now and after each save', () async {
      final expectation = expectLater(
        repository.watchRecents('Height'),
        emitsInOrder([
          <Quantity>[],
          [eightFeet],
          [tenFeet, eightFeet],
        ]),
      );
      await repository.saveRecents('Height', [eightFeet]);
      await repository.saveRecents('Height', [tenFeet, eightFeet]);
      await expectation;
    });

    test('a set failure is answered without writing', () async {
      repository.saveFailure = const CalculatorFailure(
        errorType: CalculatorErrorType.storageError,
      );
      final result = await repository.saveRecents('Height', [eightFeet]);
      expect(
        result.fold((failure) => failure, (_) => null),
        const CalculatorFailure(errorType: CalculatorErrorType.storageError),
      );
      expect(repository.drawers, isEmpty);
    });

    test('reset empties every drawer and clears the failure', () async {
      await repository.saveRecents('Height', [eightFeet]);
      repository.saveFailure = const CalculatorFailure(
        errorType: CalculatorErrorType.storageError,
      );
      repository.reset();
      expect(repository.drawers, isEmpty);
      expect(repository.saveFailure, isNull);
    });

    test('dispose ends the watches handed out', () async {
      var done = false;
      repository
          .watchRecents('Height')
          .listen((_) {}, onDone: () => done = true);
      await pumpEventQueue();
      repository.dispose();
      await pumpEventQueue();
      expect(done, isTrue);
    });
  });
}

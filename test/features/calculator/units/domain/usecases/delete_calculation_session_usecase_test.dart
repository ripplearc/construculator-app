import 'package:construculator/features/calculator/domain/usecases/delete_calculation_session_usecase.dart';
import 'package:construculator/libraries/calculation/testing/fake_calculation_session_repository.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeCalculationSessionRepository history;
  late DeleteCalculationSessionUseCase useCase;

  Tape typed(String digit) => switch (const Tape().typeDigit(digit)) {
    TapeChanged(:final tape) => tape,
    _ => const Tape(),
  };

  setUp(() {
    // History is the calculation library's, so its fake stands in for it.
    history = FakeCalculationSessionRepository();
    // ignore: no_direct_instantiation
    useCase = DeleteCalculationSessionUseCase(repository: history);
  });

  tearDown(() => history.dispose());

  group('DeleteCalculationSessionUseCase', () {
    test('takes the session and its tape out of history and leaves the '
        'others', () async {
      await history.bankSession(typed('2'));
      await history.bankSession(typed('3'));

      final deleted = await useCase('session-1');

      expect(deleted.isRight(), isTrue);
      expect(
        [for (final session in history.sessions) session.id],
        ['session-2'],
      );
      expect(history.tapes.keys, ['session-2']);
    });

    test('answers notFound for a session that is gone already', () async {
      final deleted = await useCase('session-9');

      expect(
        deleted.getLeftOrNull(),
        const CalculatorFailure(errorType: CalculatorErrorType.notFound),
      );
    });

    test('answers the failure the store refuses with, and the session '
        'stays', () async {
      await history.bankSession(typed('2'));
      history.writeFailure = const CalculatorFailure(
        errorType: CalculatorErrorType.storageError,
      );

      final deleted = await useCase('session-1');

      expect(
        deleted.getLeftOrNull(),
        const CalculatorFailure(errorType: CalculatorErrorType.storageError),
      );
      expect(history.sessions, hasLength(1));
    });
  });
}

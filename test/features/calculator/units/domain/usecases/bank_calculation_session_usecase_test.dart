import 'package:construculator/features/calculator/domain/usecases/bank_calculation_session_usecase.dart';
import 'package:construculator/libraries/calculation/testing/fake_calculation_session_repository.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeCalculationSessionRepository history;
  late BankCalculationSessionUseCase useCase;

  Tape after(Tape tape, TapeOutcome Function(Tape tape) key) =>
      switch (key(tape)) {
        TapeChanged(:final tape) => tape,
        _ => tape,
      };

  /// 2 + 3 = as the engine lands it: 2, +3, Calc 5.
  Tape twoPlusThree() {
    var tape = after(const Tape(), (tape) => tape.typeDigit('2'));
    tape = after(tape, (tape) => tape.pressOperator(Operator.add));
    tape = after(tape, (tape) => tape.typeDigit('3'));
    return after(tape, (tape) => tape.pressEquals());
  }

  setUp(() {
    // History is the calculation library's, so its fake stands in for it.
    history = FakeCalculationSessionRepository();
    // ignore: no_direct_instantiation
    useCase = BankCalculationSessionUseCase(repository: history);
  });

  tearDown(() => history.dispose());

  group('BankCalculationSessionUseCase', () {
    test('banks the whole tape as typed and answers the session with the '
        'result it ended on', () async {
      final tape = twoPlusThree();

      final banked = await useCase(tape);

      final session = banked.getRightOrNull();
      expect(session, isNotNull);
      expect(session!.resultText, '5');
      expect(history.tapes[session.id], tape);
      expect(await history.watchSessions().first, [session]);
    });

    test('a tape with no result is banked too, and names none', () async {
      final tape = after(
        after(const Tape(), (tape) => tape.typeDigit('5')),
        (tape) => tape.pressOperator(Operator.add),
      );

      final banked = await useCase(tape);

      expect(banked.getRightOrNull()!.resultText, isNull);
      expect(history.tapes.values.single, tape);
    });

    test('answers the repository\'s failure with nobody signed in, and '
        'history keeps nothing', () async {
      history.signedIn = false;

      final banked = await useCase(twoPlusThree());

      expect(
        banked.getLeftOrNull(),
        const CalculatorFailure(errorType: CalculatorErrorType.notSignedIn),
      );
      expect(history.sessions, isEmpty);
    });
  });
}

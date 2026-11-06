import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Test module that provides [CalculatorBloc] as a factory (`i.add`) so
/// each test resolves a fresh instance via `Modular.get`. The production
/// [CalculatorModule] does not bind [CalculatorBloc] — the page owns its
/// lifecycle through `BlocProvider` — so this test-only binding keeps the
/// unit tests on dependency injection instead of direct instantiation.
class _CalculatorBlocTestModule extends Module {
  @override
  void binds(Injector i) {
    i.add<CalculatorBloc>(() => CalculatorBloc());
  }
}

void main() {
  late CalculatorBloc bloc;

  setUp(() {
    Modular.init(_CalculatorBlocTestModule());
    bloc = Modular.get<CalculatorBloc>();
  });

  tearDown(() {
    bloc.close();
    Modular.destroy();
  });

  /// The tape after [keys] pressed on the engine directly, the expectation
  /// every bloc test is held to: the bloc adds nothing of its own.
  Tape pressed(String keys, {Tape tape = const Tape()}) {
    var current = tape;
    for (final key in keys.split(' ')) {
      if (key.isEmpty) continue;
      final outcome = switch (key) {
        'ft' => current.pressUnit(Unit.foot),
        'in' => current.pressUnit(Unit.inch),
        'yd' => current.pressUnit(Unit.yard),
        'm' => current.pressUnit(Unit.metre),
        'lbs' => current.pressUnit(Unit.pound),
        '/' => current.typeFraction(),
        '×' => current.pressOperator(Operator.multiply),
        '÷' => current.pressOperator(Operator.divide),
        '+' => current.pressOperator(Operator.add),
        '−' => current.pressOperator(Operator.subtract),
        '=' => current.pressEquals(),
        '⌫' => current.backspace(),
        '(' => current.pressBracket(),
        '[DMS]' => current.pressDmsKey(),
        '✕' => current.clearActive(),
        '[SIN]' => current.pressTrigKey(TrigFunction.sine),
        '[COS]' => current.pressTrigKey(TrigFunction.cosine),
        '[TAN]' => current.pressTrigKey(TrigFunction.tangent),
        '[ASIN]' => current.pressTrigKey(TrigFunction.arcsine),
        '[ACOS]' => current.pressTrigKey(TrigFunction.arccosine),
        '[ATAN]' => current.pressTrigKey(TrigFunction.arctangent),
        _ when key.startsWith('[') => current.pressFunctionKey(
          key.substring(1, key.length - 1),
          keyWantsUnit: !PlainNumberKeys.all.contains(
            key.substring(1, key.length - 1),
          ),
          readsDegrees: key == '[${PlainNumberKeys.pitch}]',
        ),
        _ => current.typeDigit(key),
      };
      if (outcome case TapeChanged(:final tape)) current = tape;
    }
    return current;
  }

  CalculatorState tapeState(Tape tape, {TapeNotice? notice}) =>
      CalculatorState(tape: tape, notice: notice);

  group('CalculatorBloc', () {
    group('walkthrough 11.1: Length 22ft then Width 18ft 8in', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'produces the engine\'s tape step by step, every key a state',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Length'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorUnitSelected(Unit.inch)),
        expect: () => [
          tapeState(pressed('[Length]')),
          tapeState(pressed('[Length] 2')),
          tapeState(pressed('[Length] 2 2')),
          tapeState(pressed('[Length] 2 2 ft')),
          tapeState(pressed('[Length] 2 2 ft [Width]')),
          tapeState(pressed('[Length] 2 2 ft [Width] 1')),
          tapeState(pressed('[Length] 2 2 ft [Width] 1 8')),
          tapeState(pressed('[Length] 2 2 ft [Width] 1 8 ft')),
          tapeState(pressed('[Length] 2 2 ft [Width] 1 8 ft 8')),
          tapeState(pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in')),
        ],
      );

      test('and the state reads the tape back for the display', () {
        final state = tapeState(pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in'));
        expect(state.tape.beingTyped, isNotNull);
        expect(state.labelKeyId, 'Width');
        expect(state.valueText, '18ft 8in');
        expect(
          [for (final chip in state.chipsList) '${chip.label}${chip.value}'],
          ['Length22ft', 'Width18ft 8in'],
        );
        expect(state.chipsList.first.type, CoreCalculatorChipType.editable);
        expect(state.chipsList.last.type, CoreCalculatorChipType.active);
      });
    });

    group('each key reaches its tape method', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'a decimal point, a fraction and an operator',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('.'))
          ..add(const CalculatorDigitPressed('5'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorFractionPressed())
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.inch)),
        skip: 8,
        expect: () => [tapeState(pressed('1 . 5 ft + 1 / 2 in'))],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'equals lands the running total: 2ft × 3 = is Calc 6ft 0in',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorOperatorPressed(Operator.multiply))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorEqualsPressed()),
        skip: 4,
        expect: () => [tapeState(pressed('2 ft × 3 ='))],
        verify: (bloc) {
          expect(bloc.state.labelKeyId, Tape.calcKey);
          expect(bloc.state.valueText, '6ft 0in');
          expect(bloc.state.tape.beingTyped, isNull);
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['2ft', '×3', '6ft 0in'],
          );
          expect(bloc.state.chipsList.last.type, CoreCalculatorChipType.result);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        '⌫ removes the last token and C clears the tape',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorControlActioned(ControlAction.delete))
          ..add(const CalculatorControlActioned(ControlAction.clearAll)),
        skip: 2,
        expect: () => [tapeState(pressed('2 4 ⌫')), CalculatorState.initial()],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the bracket key opens a bracket and closes it, as one chip',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorOperatorPressed(Operator.multiply))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorControlActioned(ControlAction.paren)),
        skip: 6,
        expect: () => [tapeState(pressed('2 + ( 3 × 4 ('))],
        verify: (bloc) {
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['2', '3×4'],
          );
          final bracket = bloc.state.chipsList.last;
          expect(bracket.type, CoreCalculatorChipType.bracketClosed);
          expect(bracket.factor, CoreIcons.addOperator);
          expect(
            [for (final chip in bloc.state.chipsList) chip.inert],
            [false, false],
          );
          expect(bloc.state.labelKeyId, isNull);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'an open bracket reads as one with no closing parenthesis',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3')),
        skip: 1,
        expect: () => [tapeState(pressed('( 3'))],
        verify: (bloc) {
          final bracket = bloc.state.chipsList.single;
          expect(bracket.value, '3');
          expect(bracket.type, CoreCalculatorChipType.bracketOpen);
          expect(bracket.factor, isNull);
          expect(bracket.label, isNull);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'typing inside a bracket reads as typing: the label and the value '
        'row read the chip inside, the tape the whole bracket',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorOperatorPressed(Operator.multiply))
          ..add(const CalculatorDigitPressed('4')),
        skip: 5,
        expect: () => [tapeState(pressed('2 + ( 3 × 4'))],
        verify: (bloc) {
          expect(bloc.state.tape.beingTyped, isNotNull);
          expect(bloc.state.labelKeyId, isNull);
          expect(bloc.state.valueText, '4');
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['2', '3×4'],
          );
          expect(
            [for (final chip in bloc.state.chipsList) chip.type],
            [
              CoreCalculatorChipType.editable,
              CoreCalculatorChipType.bracketOpen,
            ],
          );
          expect(bloc.state.chipsList.last.factor, CoreIcons.addOperator);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the chips before an open bracket are inert until it closes (term '
        '2.22: dimmed and cannot be tapped)',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorControlActioned(ControlAction.paren)),
        skip: 3,
        expect: () => [
          tapeState(pressed('2 + ( 3')),
          tapeState(pressed('2 + ( 3 (')),
        ],
        verify: (bloc) {
          expect(
            [for (final chip in bloc.state.chipsList) chip.inert],
            [false, false],
          );
        },
      );

      test('while a bracket is open every chip before it is inert, and the '
          'bracket itself is not', () {
        final open = tapeState(pressed('2 + ( 3'));
        expect([for (final chip in open.chipsList) chip.inert], [true, false]);
        expect(open.chipsList.last.type, CoreCalculatorChipType.bracketOpen);
      });
    });

    group('what the tape says comes with the state', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'a refused key keeps the tape and carries the refusal; the next '
        'taken key clears it',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorEqualsPressed())
          ..add(const CalculatorDigitPressed('5')),
        expect: () => [
          const CalculatorState(
            refusal: TapeRefused(TapeRefusal.nothingToCompute),
          ),
          tapeState(pressed('5')),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the same refusal twice in a row is one state',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorEqualsPressed())
          ..add(const CalculatorEqualsPressed()),
        expect: () => [
          const CalculatorState(
            refusal: TapeRefused(TapeRefusal.nothingToCompute),
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a refused unit, an unfinished fraction and a zero under the fraction '
        'line each carry their own reason',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorFractionPressed())
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorDigitPressed('0')),
        expect: () => [
          const CalculatorState(
            refusal: TapeRefused(TapeRefusal.typeANumberFirst),
          ),
          tapeState(pressed('1')),
          tapeState(pressed('1 /')),
          tapeState(pressed('1 /')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.finishThisValueFirst),
          ),
          tapeState(pressed('1 /')).copyWith(
            refusal: () => const TapeEntryRefused(EntryRefusal.zeroDenominator),
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a notice rides with the change that caused it and goes with the next',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3')),
        skip: 3,
        expect: () => [
          tapeState(pressed('2 +'), notice: TapeNotice.emptyBracketsRemoved),
          tapeState(pressed('2 + 3')),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'an error chip is read as its error for the label and no value',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('7'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorKeySelected('lbs'))
          ..add(const CalculatorOperatorPressed(Operator.divide))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorEqualsPressed()),
        skip: 7,
        expect: () => [tapeState(pressed('7 8 lbs ÷ 1 2 ft ='))],
        verify: (bloc) {
          expect(bloc.state.labelKeyId, CalculationError.dimensionError.name);
          expect(bloc.state.valueText, '');
          final chip = bloc.state.chipsList.last;
          expect(chip.label, CalculationError.dimensionError.name);
          expect(chip.value, isNull);
          expect(chip.type, CoreCalculatorChipType.error);
        },
      );
    });

    group('S1a 2/2: the keys the bloc tells apart', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'a trig key presses its function, after its number (38 [SIN]) or '
        'before it ([ATAN] 16)',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorKeySelected('SIN'))
          ..add(const CalculatorControlActioned(ControlAction.clearAll))
          ..add(const CalculatorKeySelected('ATAN'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('6')),
        skip: 2,
        expect: () => [
          tapeState(pressed('3 8 [SIN]')),
          CalculatorState.initial(),
          tapeState(pressed('[ATAN]')),
          tapeState(pressed('[ATAN] 1')),
          tapeState(pressed('[ATAN] 1 6')),
        ],
        verify: (bloc) {
          expect(bloc.state.labelKeyId, TrigFunction.arctangent.key);
          expect(bloc.state.valueText, '16');
          expect(bloc.state.tape.beingTyped, isNotNull);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        "the keyboard's SIN id reaches the engine's sine: 38 [SIN] answers "
        'Sine 0.615661 on the tape',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorKeySelected('SIN')),
        skip: 2,
        expect: () => [tapeState(pressed('3 8 [SIN]'))],
        verify: (bloc) {
          expect(bloc.state.labelKeyId, TrigFunction.sine.key);
          expect(bloc.state.valueText, '0.615661');
          expect(bloc.state.tape.beingTyped, isNull);
          expect(bloc.state.chipsList.last.label, TrigFunction.sine.key);
          expect(bloc.state.chipsList.last.value, '0.615661');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        "the keyboard's ATAN id reaches the engine's arctangent: [ATAN] 1 6 "
        'offers Arctangent 86.42°',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('ATAN'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('6')),
        skip: 2,
        expect: () => [tapeState(pressed('[ATAN] 1 6'))],
        verify: (bloc) {
          expect(bloc.state.labelKeyId, TrigFunction.arctangent.key);
          expect(bloc.state.valueText, '16');
          expect(
            bloc.state.tape.trigAnswer,
            isA<Answer>().having(
              (answer) => const QuantityFormatter().format(answer.value),
              'text',
              '86.42°',
            ),
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the D:M:S key types a segment: 38 [DMS] 30 [DMS] 45',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorKeySelected('DMS'))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('0'))
          ..add(const CalculatorKeySelected('DMS'))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorDigitPressed('5')),
        skip: 7,
        expect: () => [tapeState(pressed('3 8 [DMS] 3 0 [DMS] 4 5'))],
        verify: (bloc) => expect(bloc.state.valueText, '38°30\'45"'),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'Pitch, Slope and Sides take a plain number, so an operator leaves '
        'the bare number as complete',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Pitch'))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('0'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorKeySelected('Sides'))
          ..add(const CalculatorDigitPressed('6'))
          ..add(const CalculatorOperatorPressed(Operator.add)),
        skip: 3,
        expect: () => [
          tapeState(pressed('[Pitch] 3 0 +')),
          tapeState(pressed('[Pitch] 3 0 + [Sides]')),
          tapeState(pressed('[Pitch] 3 0 + [Sides] 6')),
          tapeState(pressed('[Pitch] 3 0 + [Sides] 6 +')),
        ],
        verify: (bloc) {
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['30°', '+6', '+'],
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a weight unit under a length-only key and a length unit under '
        'Slope are refused with the tape\'s own reasons',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorDigitPressed('5'))
          ..add(const CalculatorKeySelected('lbs'))
          ..add(const CalculatorControlActioned(ControlAction.clearAll))
          ..add(const CalculatorKeySelected('Slope'))
          ..add(const CalculatorDigitPressed('6'))
          ..add(const CalculatorUnitSelected(Unit.foot)),
        skip: 2,
        expect: () => [
          tapeState(pressed('[Width] 5')).copyWith(
            refusal: () => const TapeEntryRefused(EntryRefusal.needsLength),
          ),
          CalculatorState.initial(),
          tapeState(pressed('[Slope]')),
          tapeState(pressed('[Slope] 6')),
          tapeState(pressed('[Slope] 6')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.slopeTakesAGrade),
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a unit inside a bracket is judged by the chip being typed there, '
        'not by the key the chip before the bracket is named by',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorDigitPressed('5'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorKeySelected('lbs')),
        skip: 6,
        expect: () => [tapeState(pressed('[Width] 5 ft + ( 3 lbs'))],
        verify: (bloc) => expect(bloc.state.valueText, '3lbs'),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        '✕ in a bracket with nothing typed in it yet is refused with its own '
        'reason, and inside it clears the chip being typed there',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorControlActioned(ControlAction.paren))
          ..add(const CalculatorActiveValueCleared())
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorActiveValueCleared()),
        skip: 3,
        expect: () => [
          tapeState(pressed('2 + (')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.nothingTypedInGroup),
          ),
          tapeState(pressed('2 + ( 3')),
          tapeState(pressed('2 + ( 3 ✕')),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        '✕ clears the value being typed and leaves the tape before it; with '
        'nothing typed in the chip it emptied, a second ✕ closes the '
        'calculator',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorActiveValueCleared())
          ..add(const CalculatorEqualsPressed())
          ..add(const CalculatorActiveValueCleared()),
        skip: 5,
        expect: () => [
          tapeState(pressed('2 ft + 1 8 ✕')),
          tapeState(pressed('2 ft + 1 8 ✕')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.operatorNeedsANumber),
          ),
          tapeState(pressed('2 ft + 1 8 ✕')).copyWith(closesCalculator: true),
        ],
      );
    });

    group(
      'T1a (CA-1092): ✕ with no value in progress closes the calculator',
      () {
        blocTest<CalculatorBloc, CalculatorState>(
          'on an empty tape ✕ closes the calculator and the tape stays empty',
          build: () => bloc,
          act: (bloc) => bloc.add(const CalculatorActiveValueCleared()),
          expect: () => [const CalculatorState(closesCalculator: true)],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'after an answer ✕ closes the calculator: a result is not a value in '
          'progress',
          build: () => bloc,
          act: (bloc) => bloc
            ..add(const CalculatorDigitPressed('2'))
            ..add(const CalculatorOperatorPressed(Operator.multiply))
            ..add(const CalculatorDigitPressed('3'))
            ..add(const CalculatorEqualsPressed())
            ..add(const CalculatorActiveValueCleared()),
          skip: 4,
          expect: () => [
            tapeState(pressed('2 × 3 =')).copyWith(closesCalculator: true),
          ],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'inside an open bracket ✕ on the empty chip an operator opened is '
          'refused, not a close: 2 + (3 + ✕ 4) = is 9',
          build: () => bloc,
          act: (bloc) => bloc
            ..add(const CalculatorDigitPressed('2'))
            ..add(const CalculatorOperatorPressed(Operator.add))
            ..add(const CalculatorControlActioned(ControlAction.paren))
            ..add(const CalculatorDigitPressed('3'))
            ..add(const CalculatorOperatorPressed(Operator.add))
            ..add(const CalculatorActiveValueCleared())
            ..add(const CalculatorDigitPressed('4'))
            ..add(const CalculatorControlActioned(ControlAction.paren))
            ..add(const CalculatorEqualsPressed()),
          skip: 5,
          expect: () => [
            tapeState(pressed('2 + ( 3 +')).copyWith(
              refusal: () => const TapeRefused(TapeRefusal.nothingBeingTyped),
            ),
            tapeState(pressed('2 + ( 3 + 4')),
            tapeState(pressed('2 + ( 3 + 4 (')),
            tapeState(pressed('2 + ( 3 + 4 ( =')),
          ],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'after ÷ 0 = the divisor is reopened with nothing typed in it, so ✕ '
          'closes the calculator, as the prototype\'s does after its error',
          build: () => bloc,
          act: (bloc) => bloc
            ..add(const CalculatorDigitPressed('5'))
            ..add(const CalculatorOperatorPressed(Operator.divide))
            ..add(const CalculatorDigitPressed('0'))
            ..add(const CalculatorEqualsPressed())
            ..add(const CalculatorActiveValueCleared()),
          skip: 4,
          expect: () => [
            tapeState(pressed('5 ÷ 0 =')).copyWith(closesCalculator: true),
          ],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'the fraction key with nothing typed is refused with the same word '
          'and closes nothing',
          build: () => bloc,
          act: (bloc) => bloc.add(const CalculatorFractionPressed()),
          expect: () => [
            const CalculatorState(
              refusal: TapeRefused(TapeRefusal.nothingBeingTyped),
            ),
          ],
        );

        blocTest<CalculatorBloc, CalculatorState>(
          'the next key taken or refused clears the close, as it clears a '
          'notice or a refusal',
          build: () => bloc,
          act: (bloc) => bloc
            ..add(const CalculatorActiveValueCleared())
            ..add(const CalculatorDigitPressed('5'))
            ..add(const CalculatorActiveValueCleared())
            ..add(const CalculatorActiveValueCleared())
            ..add(const CalculatorEqualsPressed()),
          expect: () => [
            const CalculatorState(closesCalculator: true),
            tapeState(pressed('5')),
            tapeState(pressed('5 ✕')),
            tapeState(pressed('5 ✕')).copyWith(closesCalculator: true),
            tapeState(pressed('5 ✕')).copyWith(
              refusal: () => const TapeRefused(TapeRefusal.nothingToCompute),
            ),
          ],
        );
      },
    );

    group('the keyboard around the tape', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'selecting a group changes only the group',
        build: () => bloc,
        act: (bloc) => bloc.add(const CalculatorGroupSelected(2)),
        expect: () => [const CalculatorState(currentGroupIndex: 2)],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the System of units toggle sets the tape\'s own preferences, so a '
        'mixed sum follows it',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorUnitSystemChanged(UnitSystem.metric))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorUnitSelected(Unit.metre))
          ..add(const CalculatorOperatorPressed(Operator.add))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorEqualsPressed()),
        skip: 6,
        expect: () => [
          tapeState(
            pressed(
              '1 m + 1 ft =',
              tape: const Tape(
                preferences: CalculatorPreferences(
                  system: MeasurementSystem.metric,
                ),
              ),
            ),
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.currentUnitSystem, UnitSystem.metric);
          expect(bloc.state.valueText, '1.3m');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'C and a reset keep the System of units and the group',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorUnitSystemChanged(UnitSystem.metric))
          ..add(const CalculatorGroupSelected(3))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorControlActioned(ControlAction.clearAll))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorResetRequested()),
        skip: 3,
        expect: () => [
          const CalculatorState(
            tape: Tape(
              preferences: CalculatorPreferences(
                system: MeasurementSystem.metric,
              ),
            ),
            currentGroupIndex: 3,
          ),
          tapeState(
            pressed(
              '4',
              tape: const Tape(
                preferences: CalculatorPreferences(
                  system: MeasurementSystem.metric,
                ),
              ),
            ),
          ).copyWith(currentGroupIndex: 3),
          const CalculatorState(
            tape: Tape(
              preferences: CalculatorPreferences(
                system: MeasurementSystem.metric,
              ),
            ),
            currentGroupIndex: 3,
          ),
        ],
      );
    });

    group('T1b: the order of the function-key groups (Section 1.5)', () {
      const reorderedUnitFirst = [
        CalculatorGroupId.unit,
        CalculatorGroupId.basicGeometry,
        CalculatorGroupId.shapes,
        CalculatorGroupId.materials,
        CalculatorGroupId.trigonometry,
      ];

      blocTest<CalculatorBloc, CalculatorState>(
        'a group dragged to the front in View all leads the order, and the '
        'group on the keyboard follows to its new index',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorGroupSelected(3))
          ..add(const CalculatorGroupsReordered(oldIndex: 3, newIndex: 0)),
        skip: 1,
        expect: () => [
          const CalculatorState(
            currentGroupIndex: 0,
            groupOrder: reorderedUnitFirst,
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a group dragged in front of the one on the keyboard moves that one '
        'back by a place',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const CalculatorGroupsReordered(oldIndex: 4, newIndex: 0)),
        expect: () => [
          const CalculatorState(
            currentGroupIndex: 1,
            groupOrder: [
              CalculatorGroupId.trigonometry,
              CalculatorGroupId.basicGeometry,
              CalculatorGroupId.shapes,
              CalculatorGroupId.materials,
              CalculatorGroupId.unit,
            ],
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a drag that leaves the shown group where it is still changes the '
        'order',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const CalculatorGroupsReordered(oldIndex: 3, newIndex: 4)),
        expect: () => [
          const CalculatorState(
            groupOrder: [
              CalculatorGroupId.basicGeometry,
              CalculatorGroupId.shapes,
              CalculatorGroupId.materials,
              CalculatorGroupId.trigonometry,
              CalculatorGroupId.unit,
            ],
          ),
        ],
      );

      test('two states that differ only in the order of the groups are not '
          'equal, so the keyboard redraws after a drag', () {
        expect(
          const CalculatorState(groupOrder: reorderedUnitFirst),
          isNot(equals(const CalculatorState())),
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'a drag that ends where it started changes nothing',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const CalculatorGroupsReordered(oldIndex: 2, newIndex: 2)),
        expect: () => const <CalculatorState>[],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a drag from or to a place outside the five groups changes nothing',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorGroupsReordered(oldIndex: 0, newIndex: 5))
          ..add(const CalculatorGroupsReordered(oldIndex: 5, newIndex: 0))
          ..add(const CalculatorGroupsReordered(oldIndex: -1, newIndex: 0))
          ..add(const CalculatorGroupsReordered(oldIndex: 0, newIndex: -1)),
        expect: () => const <CalculatorState>[],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'C and a reset keep the order of the groups',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorGroupsReordered(oldIndex: 3, newIndex: 0))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorControlActioned(ControlAction.clearAll))
          ..add(const CalculatorDigitPressed('4'))
          ..add(const CalculatorResetRequested()),
        skip: 2,
        expect: () => [
          const CalculatorState(
            currentGroupIndex: 1,
            groupOrder: reorderedUnitFirst,
          ),
          tapeState(
            pressed('4'),
          ).copyWith(currentGroupIndex: 1, groupOrder: reorderedUnitFirst),
          const CalculatorState(
            currentGroupIndex: 1,
            groupOrder: reorderedUnitFirst,
          ),
        ],
      );
    });

    group('S1b 2/4: the strip and the equals key', () {
      List<String> row1(CalculatorState state) => [
        for (final suggestion in state.suggestions)
          '${suggestion.key}: ${suggestion.text}',
      ];

      List<String> row2(CalculatorState state) => [
        for (final suggestion in state.conversions) suggestion.text,
      ];

      CalculatorSuggestion leadingOf(String keys) =>
          CalculatorState(tape: pressed(keys)).suggestions.first;

      CalculatorSuggestion conversionOf(String keys, {int index = 0}) =>
          CalculatorState(tape: pressed(keys)).conversions[index];

      void type(CalculatorBloc bloc, String keys) {
        for (final key in keys.split(' ')) {
          bloc.add(switch (key) {
            'ft' => const CalculatorUnitSelected(Unit.foot),
            'in' => const CalculatorUnitSelected(Unit.inch),
            'yd' => const CalculatorUnitSelected(Unit.yard),
            'lbs' => const CalculatorKeySelected('lbs'),
            '×' => const CalculatorOperatorPressed(Operator.multiply),
            '÷' => const CalculatorOperatorPressed(Operator.divide),
            '+' => const CalculatorOperatorPressed(Operator.add),
            '=' => const CalculatorEqualsPressed(),
            '(' => const CalculatorControlActioned(ControlAction.paren),
            '/' => const CalculatorFractionPressed(),
            _ when key.startsWith('[') => CalculatorKeySelected(
              key.substring(1, key.length - 1),
            ),
            _ => CalculatorDigitPressed(key),
          });
        }
      }

      blocTest<CalculatorBloc, CalculatorState>(
        'two named sides earn the rectangle answers on row 1, the value on '
        'screen its conversions on row 2, and the equals key reads Area (S01)',
        build: () => bloc,
        act: (bloc) => type(bloc, '[Length] 2 2 ft [Width] 1 8 ft 8 in'),
        skip: 9,
        expect: () => [
          tapeState(pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in')),
        ],
        verify: (bloc) {
          expect(row1(bloc.state), [
            'Area: 410.67ft²',
            'Diagonal: 28.85ft',
            'Perimeter: 81.33ft',
          ]);
          expect(row2(bloc.state), ['224in', '5.69m']);
          expect([
            for (final s in bloc.state.suggestions) s.kind,
          ], everyElement(CalculatorSuggestionKind.answer));
          expect([
            for (final s in bloc.state.conversions) s.kind,
          ], everyElement(CalculatorSuggestionKind.conversion));
          expect(bloc.state.equalsKeyId, DeterministicRules.areaKey);
        },
      );

      test('Rise and Run earn the three pitch spellings first, and a landed '
          'spelling leaves the row (S08)', () {
        final offered = CalculatorState(
          tape: pressed('[Rise] 6 ft [Run] 1 2 ft'),
        );
        expect(row1(offered), [
          'Pitch-rise per 12in run: 6in/12in',
          'Pitch-degrees: 26.57°',
          'Pitch-grade: 50%',
          'Diagonal: 13.42ft',
          'Arc angle: 180°',
          'Arc radius: 6ft',
          'Arc length: 18.85ft',
        ]);
        expect(offered.equalsKeyId, DeterministicRules.pitchRiseKey);
        final landed = CalculatorState(
          tape: pressed('[Rise] 6 ft [Run] 1 2 ft [Pitch]'),
        );
        expect(row1(landed), [
          'Pitch-degrees: 26.57°',
          'Pitch-grade: 50%',
          'Diagonal: 13.42ft',
          'Arc angle: 180°',
          'Arc radius: 6ft',
          'Arc length: 18.85ft',
        ]);
        expect(row2(landed), isEmpty);
      });

      test('row 2 offers no D:M:S under a pitch answer, which is not a pitch '
          'reading, while another angle answer still offers it', () {
        final degrees = CalculatorState(
          tape: pressed('[Rise] 6 ft [Run] 1 2 ft [Pitch] [Pitch]'),
        );
        expect(degrees.valueText, '26.57°');
        expect(row2(degrees), isEmpty);
        expect(row2(CalculatorState(tape: pressed('1 2 ÷ 2 3 [ATAN]'))), [
          '27°33\'10"',
        ]);
      });

      test('a division by zero silences the strip while it is typed, after '
          'the = that lands its error chip, and until the divisor is retyped '
          '(doc line 771)', () {
        const sides = '[Length] 2 2 ft [Width] 1 8 ft 8 in';
        final typed = CalculatorState(tape: pressed('$sides ÷ 0'));
        expect(row1(typed), isEmpty);
        expect(row2(typed), isEmpty);
        expect(typed.equalsKeyId, isNull);
        final landed = CalculatorState(tape: pressed('$sides ÷ 0 ='));
        expect(landed.tape.endsWithError, isFalse);
        expect(row1(landed), isEmpty);
        expect(row2(landed), isEmpty);
        expect(landed.equalsKeyId, isNull);
        final retyped = CalculatorState(tape: pressed('$sides ÷ 0 = 2'));
        expect(row1(retyped), ['Calc: 9ft 4in']);
        expect(retyped.equalsKeyId, Tape.calcKey);
      });

      test('an error chip that ends the chain hides the rule answers the '
          'named values would earn, and a result after it starts a chain '
          'that is offered again', () {
        final error = CalculatorState(
          tape: pressed('[Length] 2 2 ft [Width] 1 8 ft + 7 8 lbs ='),
        );
        expect(error.tape.endsWithError, isTrue);
        expect(row1(error), isEmpty);
        expect(row2(error), isEmpty);
        expect(error.equalsKeyId, isNull);
        expect(row1(CalculatorState(tape: pressed('5 ÷ 0 = 2 = + 1'))), [
          'Calc: 3.5',
        ]);
      });

      test('a trig chip that continues a chain follows Calc, so = lands the '
          'chain; one that stands alone or builds its own ratio leads '
          '(term 2.15, rule 4.6, walkthrough 23.3)', () {
        final product = CalculatorState(tape: pressed('5 × [SIN] 3 0'));
        expect(row1(product), ['Calc: 2.5', 'Sine: 0.5']);
        expect(product.equalsKeyId, Tape.calcKey);
        final sum = CalculatorState(tape: pressed('5 + [SIN] 3 0'));
        expect(row1(sum), ['Calc: 5.5', 'Sine: 0.5']);
        expect(sum.equalsKeyId, Tape.calcKey);
        final reach = CalculatorState(tape: pressed('5 + [ATAN] 1 6 ÷ 1 2'));
        expect(row1(reach), ['Calc: 58.13°', 'Arctangent(16 ÷ 12): 53.13°']);
        expect(reach.equalsKeyId, Tape.calcKey);
        final alone = CalculatorState(tape: pressed('[ATAN] 1 6 ÷ 1 2'));
        expect(row1(alone), ['Arctangent(16 ÷ 12): 53.13°', 'Calc: 1.33']);
        expect(alone.equalsKeyId, 'Arctangent(16 ÷ 12)');
        final typed = CalculatorState(tape: pressed('[SIN] 3 0'));
        expect(row1(typed), ['Sine: 0.5']);
        expect(typed.equalsKeyId, 'Sine');
      });

      test('a bracket that continues a chain from a result offers Calc with '
          'Ans on the equals key (doc line 1011)', () {
        final group = CalculatorState(
          tape: pressed('3 6 ft ÷ 1 2 ft = × ( 4 + 1 ('),
        );
        expect(row1(group), ['Calc: 15']);
        expect(group.equalsKeyId, CalculatorState.ansKey);
        final open = CalculatorState(tape: pressed('3 6 ft ÷ 1 2 ft = × ( 4'));
        expect(row1(open), isEmpty);
        expect(open.equalsKeyId, isNull);
      });

      test('row 2 holds the value on screen in its other units: a typed '
          'length, a result, an angle answer (S03, S16)', () {
        final typed = CalculatorState(tape: pressed('[Length] 2 2 ft'));
        expect(row1(typed), isEmpty);
        expect(typed.equalsKeyId, isNull);
        expect(row2(typed), ['264in', '7.33yd', '6.71m']);
        expect(row2(CalculatorState(tape: pressed('[Length] 2 2 ft in'))), [
          '22ft 0in',
          '6,706mm',
        ]);
        expect(row2(CalculatorState(tape: pressed('1 2 ft × 5 ft ='))), [
          '6.67yd²',
          '8,640in²',
          '5.57m²',
        ]);
        expect(row2(CalculatorState(tape: pressed('1 2 ÷ 2 3 [ATAN]'))), [
          '27°33\'10"',
        ]);
        expect([
          for (final s in typed.conversions) s.kind,
        ], everyElement(CalculatorSuggestionKind.conversion));
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'an operator with values on both sides offers Calc, the equals key '
        'reads Calc, and = lands it (S14)',
        build: () => bloc,
        act: (bloc) => type(bloc, '7 8 × 5 6 ft ='),
        skip: 5,
        expect: () => [
          tapeState(pressed('7 8 × 5 6 ft')),
          tapeState(pressed('7 8 × 5 6 ft =')),
        ],
        verify: (bloc) {
          final before = CalculatorState(tape: pressed('7 8 × 5 6 ft'));
          expect(row1(before), ['Calc: 4368ft 0in']);
          expect(
            before.suggestions.single.kind,
            CalculatorSuggestionKind.runningTotal,
          );
          expect(before.equalsKeyId, Tape.calcKey);
          expect(row2(before), ['672in', '18.67yd', '17.07m']);
          expect(bloc.state.valueText, '4368ft 0in');
          expect(row1(bloc.state), isEmpty);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a chain continuing from a result relabels the equals key Ans while '
        'the strip still says Calc (S22; rule 4.9)',
        build: () => bloc,
        act: (bloc) => type(bloc, '3 6 ft ÷ 1 2 ft = × 4'),
        skip: 9,
        expect: () => [tapeState(pressed('3 6 ft ÷ 1 2 ft = × 4'))],
        verify: (bloc) {
          expect(row1(bloc.state), ['Calc: 12']);
          expect(bloc.state.equalsKeyId, CalculatorState.ansKey);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a chain started afresh after a result reads Calc again, not Ans',
        build: () => bloc,
        act: (bloc) => type(bloc, '3 6 ft ÷ 1 2 ft = [Length] 2 ft × 4'),
        skip: 12,
        expect: () => [
          tapeState(pressed('3 6 ft ÷ 1 2 ft = [Length] 2 ft × 4')),
        ],
        verify: (bloc) {
          expect(row1(bloc.state), ['Calc: 8ft 0in']);
          expect(bloc.state.equalsKeyId, Tape.calcKey);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a pending trig chip leads the row with its answer and the ratio it '
        'builds across ÷ keeps the Calc beside it (S111)',
        build: () => bloc,
        act: (bloc) => type(bloc, '[ATAN] 1 6 ÷ 1 2'),
        skip: 5,
        expect: () => [tapeState(pressed('[ATAN] 1 6 ÷ 1 2'))],
        verify: (bloc) {
          expect(row1(bloc.state), [
            'Arctangent(16 ÷ 12): 53.13°',
            'Calc: 1.33',
          ]);
          expect(bloc.state.equalsKeyId, 'Arctangent(16 ÷ 12)');
          expect(row2(bloc.state), isEmpty);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the strip is empty while a bracket is open and offers the whole '
        'chain\'s Calc once it closes (S128)',
        build: () => bloc,
        act: (bloc) => type(bloc, '2 + ( 3 × 4 ('),
        skip: 5,
        expect: () => [
          tapeState(pressed('2 + ( 3 × 4')),
          tapeState(pressed('2 + ( 3 × 4 (')),
        ],
        verify: (bloc) {
          final open = CalculatorState(tape: pressed('2 + ( 3 × 4'));
          expect(open.suggestions, isEmpty);
          expect(open.conversions, isEmpty);
          expect(open.equalsKeyId, isNull);
          expect(row1(bloc.state), ['Calc: 14']);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'after an error chip both rows stay empty on purpose',
        build: () => bloc,
        act: (bloc) => type(bloc, '7 8 lbs ÷ 1 2 ft ='),
        skip: 7,
        expect: () => [tapeState(pressed('7 8 lbs ÷ 1 2 ft ='))],
        verify: (bloc) {
          expect(bloc.state.suggestions, isEmpty);
          expect(bloc.state.conversions, isEmpty);
          expect(bloc.state.equalsKeyId, isNull);
        },
      );

      test('a typed angle, a bare number and a weight read as the doc says: '
          'no conversions for the first two, weights for the third', () {
        expect(
          row2(CalculatorState(tape: pressed('[Pitch] 8 . 4 5'))),
          isEmpty,
        );
        expect(row2(CalculatorState(tape: pressed('7 8'))), isEmpty);
        expect(row2(CalculatorState(tape: pressed('7 8 lbs'))), [
          '35.38kg',
          '0.04 ton',
        ]);
        expect(
          row2(
            CalculatorState(tape: pressed('[Length] 2 2 ft [Width] 1 8 ft 8')),
          ),
          isEmpty,
          reason: 'an unfinished compound has no value to convert yet',
        );
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting Area lands it as a result chip; the other answers stay on '
        'offer and the result\'s conversions take row 2',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Length'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorKeySelected('Width'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorUnitSelected(Unit.inch))
          ..add(
            CalculatorSuggestionAccepted(
              leadingOf('[Length] 2 2 ft [Width] 1 8 ft 8 in'),
            ),
          ),
        skip: 10,
        expect: () => [
          tapeState(
            pressed('[Length] 2 2 ft [Width] 1 8 ft 8 in').append(
              ResultChip(
                key: DeterministicRules.areaKey,
                value: leadingOf('[Length] 2 2 ft [Width] 1 8 ft 8 in').value,
              ),
            ),
          ),
        ],
        verify: (bloc) {
          expect(
            [
              for (final chip in bloc.state.chipsList)
                '${chip.label}${chip.value}',
            ],
            ['Length22ft', 'Width18ft 8in', 'Area410.67ft²'],
          );
          expect(bloc.state.labelKeyId, DeterministicRules.areaKey);
          expect(bloc.state.valueText, '410.67ft²');
          expect(row1(bloc.state), ['Diagonal: 28.85ft', 'Perimeter: 81.33ft']);
          expect(row2(bloc.state), [
            '45.63yd²',
            '59,136in²',
            '38.15m²',
            '0.0094acre',
          ]);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        '= lands the leading suggestion when the strip has one (Area), as '
        'accepting it would',
        build: () => bloc,
        act: (bloc) => type(bloc, '[Length] 2 0 ft [Width] 1 0 ft ='),
        skip: 8,
        expect: () => [
          tapeState(
            pressed('[Length] 2 0 ft [Width] 1 0 ft').append(
              ResultChip(
                key: DeterministicRules.areaKey,
                value: leadingOf('[Length] 2 0 ft [Width] 1 0 ft').value,
              ),
            ),
          ),
        ],
        verify: (bloc) => expect(bloc.state.valueText, '200ft²'),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'Rise and Run earn the three pitch spellings; the long name keeps the '
        'equals key\'s own id, and the accepted spelling leaves the row (S08)',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Rise] 6 ft [Run] 1 2 ft');
          bloc.add(
            CalculatorSuggestionAccepted(leadingOf('[Rise] 6 ft [Run] 1 2 ft')),
          );
        },
        skip: 6,
        expect: () => [
          tapeState(pressed('[Rise] 6 ft [Run] 1 2 ft')),
          tapeState(
            pressed('[Rise] 6 ft [Run] 1 2 ft').append(
              ResultChip(
                key: DeterministicRules.pitchRiseKey,
                value: leadingOf('[Rise] 6 ft [Run] 1 2 ft').value,
              ),
            ),
          ),
        ],
        verify: (bloc) {
          final before = CalculatorState(
            tape: pressed('[Rise] 6 ft [Run] 1 2 ft'),
          );
          expect(row1(before).take(3), [
            'Pitch-rise per 12in run: 6in/12in',
            'Pitch-degrees: 26.57°',
            'Pitch-grade: 50%',
          ]);
          expect(before.equalsKeyId, DeterministicRules.pitchRiseKey);
          expect(bloc.state.valueText, '6in/12in');
          expect(row1(bloc.state).take(2), [
            'Pitch-degrees: 26.57°',
            'Pitch-grade: 50%',
          ]);
          expect(row2(bloc.state), isEmpty);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting a prefix trig answer lands the tape the postfix order '
        'lands (rule 4.11)',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[SIN] 3 8');
          bloc.add(CalculatorSuggestionAccepted(leadingOf('[SIN] 3 8')));
        },
        skip: 3,
        expect: () => [tapeState(pressed('3 8 [SIN]'))],
        verify: (bloc) {
          expect(row1(CalculatorState(tape: pressed('[SIN] 3 8'))), [
            'Sine: 0.615661',
          ]);
          expect(row1(bloc.state), isEmpty);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a typed length offers its conversions, and accepting one converts '
        'it in place through the unit key (S03, S05)',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 2 2 ft');
          bloc.add(
            CalculatorSuggestionAccepted(conversionOf('[Length] 2 2 ft')),
          );
        },
        skip: 3,
        expect: () => [
          tapeState(pressed('[Length] 2 2 ft')),
          tapeState(pressed('[Length] 2 2 ft in')),
        ],
        verify: (bloc) {
          final typed = CalculatorState(tape: pressed('[Length] 2 2 ft'));
          expect(row1(typed), isEmpty);
          expect(typed.equalsKeyId, isNull);
          expect(row2(typed), ['264in', '7.33yd', '6.71m']);
          expect(bloc.state.valueText, '264in');
          expect(row2(bloc.state), ['22ft 0in', '6,706mm']);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a result offers its conversions and accepting one re-spells the '
        'result in place',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '1 2 ft × 5 ft =');
          bloc.add(
            CalculatorSuggestionAccepted(conversionOf('1 2 ft × 5 ft =')),
          );
        },
        skip: 7,
        expect: () => [tapeState(pressed('1 2 ft × 5 ft = yd'))],
        verify: (bloc) {
          expect(row2(CalculatorState(tape: pressed('1 2 ft × 5 ft ='))), [
            '6.67yd²',
            '8,640in²',
            '5.57m²',
          ]);
          expect(bloc.state.valueText, '6.67yd²');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'an angle answer offers its other spelling, and accepting it respells '
        'the answer as the D:M:S key does',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '1 2 ÷ 2 3 [ATAN]');
          bloc.add(
            CalculatorSuggestionAccepted(conversionOf('1 2 ÷ 2 3 [ATAN]')),
          );
        },
        skip: 6,
        expect: () => [tapeState(pressed('1 2 ÷ 2 3 [ATAN] [DMS]'))],
        verify: (bloc) {
          expect(row2(CalculatorState(tape: pressed('1 2 ÷ 2 3 [ATAN]'))), [
            '27°33\'10"',
          ]);
          expect(bloc.state.valueText, '27°33\'10"');
          expect(row2(bloc.state), ['27.55°']);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting an answer drops the empty chip a key had opened',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 2 0 ft [Width] 1 0 ft [Height]');
          bloc.add(
            CalculatorSuggestionAccepted(
              leadingOf('[Length] 2 0 ft [Width] 1 0 ft [Height]'),
            ),
          );
        },
        skip: 9,
        expect: () => [
          tapeState(
            pressed('[Length] 2 0 ft [Width] 1 0 ft').append(
              ResultChip(
                key: DeterministicRules.areaKey,
                value: leadingOf('[Length] 2 0 ft [Width] 1 0 ft').value,
              ),
            ),
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting an answer while a value is unfinished is refused the way '
        '= is, and the tape keeps the dangling number',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 2 0 ft [Width] 1 0 ft [Height] 8');
          bloc.add(
            CalculatorSuggestionAccepted(
              leadingOf('[Length] 2 0 ft [Width] 1 0 ft [Height] 8'),
            ),
          );
        },
        skip: 10,
        expect: () => [
          tapeState(
            pressed('[Length] 2 0 ft [Width] 1 0 ft [Height] 8'),
          ).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.finishThisValueFirst),
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting an answer over a dangling fraction is refused with the '
        'fraction\'s own reason, as = refuses it',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 2 0 ft [Width] 1 0 ft [Height] 7 / 1 6');
          bloc.add(
            CalculatorSuggestionAccepted(
              leadingOf('[Length] 2 0 ft [Width] 1 0 ft [Height] 7 / 1 6'),
            ),
          );
        },
        skip: 13,
        expect: () => [
          tapeState(
            pressed('[Length] 2 0 ft [Width] 1 0 ft [Height] 7 / 1 6'),
          ).copyWith(
            refusal: () =>
                const TapeEntryRefused(EntryRefusal.fractionNeedsUnit),
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a chip the strip no longer offers, tapped again before the strip '
        'redrew, changes nothing',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 2 2 ft [Width] 1 8 ft 8 in');
          final area = leadingOf('[Length] 2 2 ft [Width] 1 8 ft 8 in');
          bloc
            ..add(CalculatorSuggestionAccepted(area))
            ..add(CalculatorSuggestionAccepted(area));
        },
        skip: 11,
        expect: () => <CalculatorState>[],
        verify: (bloc) => expect(
          [for (final chip in bloc.state.chipsList) chip.label],
          ['Length', 'Width', DeterministicRules.areaKey],
        ),
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a conversion of a bare number and an answer with no key, which the '
        'strip never offers, change nothing',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('5'))
          ..add(
            const CalculatorSuggestionAccepted(
              CalculatorSuggestion(
                key: null,
                value: Scalar(5),
                kind: CalculatorSuggestionKind.conversion,
                text: '5',
              ),
            ),
          )
          ..add(
            const CalculatorSuggestionAccepted(
              CalculatorSuggestion(
                key: null,
                value: Scalar(5),
                kind: CalculatorSuggestionKind.answer,
                text: '5',
              ),
            ),
          ),
        skip: 1,
        expect: () => <CalculatorState>[],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'with named values and an operator pending, the strip shows the '
        'running total in place of the rule answers, and = lands it (2.15; '
        'walkthrough 12.3)',
        build: () => bloc,
        act: (bloc) => type(bloc, '[Rise] 6 ft [Run] 1 2 ft × 2 ='),
        skip: 8,
        expect: () => [
          tapeState(pressed('[Rise] 6 ft [Run] 1 2 ft × 2')),
          tapeState(pressed('[Rise] 6 ft [Run] 1 2 ft × 2 =')),
        ],
        verify: (bloc) {
          final pending = CalculatorState(
            tape: pressed('[Rise] 6 ft [Run] 1 2 ft × 2'),
          );
          expect(row1(pending), ['Calc: 24ft 0in']);
          expect(pending.equalsKeyId, Tape.calcKey);
          expect(bloc.state.valueText, '24ft 0in');
          expect(bloc.state.labelKeyId, Tape.calcKey);
        },
      );
    });

    group('S1b 3/6: what = lands and what an accepted chip lands', () {
      CalculatorState stateOf(String keys) =>
          CalculatorState(tape: pressed(keys));

      void type(CalculatorBloc bloc, String keys) {
        for (final key in keys.split(' ')) {
          bloc.add(switch (key) {
            'ft' => const CalculatorUnitSelected(Unit.foot),
            'in' => const CalculatorUnitSelected(Unit.inch),
            'yd' => const CalculatorUnitSelected(Unit.yard),
            'm' => const CalculatorKeySelected('m'),
            '×' => const CalculatorOperatorPressed(Operator.multiply),
            '÷' => const CalculatorOperatorPressed(Operator.divide),
            '+' => const CalculatorOperatorPressed(Operator.add),
            '=' => const CalculatorEqualsPressed(),
            _ when key.startsWith('[') => CalculatorKeySelected(
              key.substring(1, key.length - 1),
            ),
            _ => CalculatorDigitPressed(key),
          });
        }
      }

      for (final (keys, calc) in const [
        ('5 + [SIN] 3 0 =', '5.5'),
        ('2 × [COS] 6 0 =', '1'),
        ('5 + [ATAN] 1 6 ÷ 1 2 =', '58.13°'),
      ]) {
        blocTest<CalculatorBloc, CalculatorState>(
          '= lands the chain a trig chip continues, not the trig answer: '
          '$keys is Calc $calc (term 2.15, rule 4.6)',
          build: () => bloc,
          act: (bloc) => type(bloc, keys),
          skip: keys.split(' ').length - 1,
          expect: () => [tapeState(pressed(keys))],
          verify: (bloc) {
            expect(bloc.state.labelKeyId, Tape.calcKey);
            expect(bloc.state.valueText, calc);
          },
        );
      }

      for (final operator in const ['+', '×']) {
        blocTest<CalculatorBloc, CalculatorState>(
          '= after a trailing $operator is refused and keeps the operator, '
          'in place of landing the leading suggestion over it (rule 4.12)',
          build: () => bloc,
          act: (bloc) =>
              type(bloc, '[Length] 2 0 ft [Width] 1 0 ft $operator ='),
          skip: 9,
          expect: () => [
            tapeState(
              pressed('[Length] 2 0 ft [Width] 1 0 ft $operator'),
            ).copyWith(
              refusal: () =>
                  const TapeRefused(TapeRefusal.operatorNeedsANumber),
            ),
          ],
          verify: (bloc) {
            expect(bloc.state.tape.endsWithOperator, isTrue);
            expect(
              bloc.state.suggestions.first.key,
              DeterministicRules.areaKey,
            );
            expect(
              [for (final chip in bloc.state.chipsList) chip.value],
              ['20ft', '10ft', operator],
            );
          },
        );
      }

      Tape landedOn(Tape tape, int offer) {
        final answer = CalculatorState(tape: tape).suggestions[offer];
        return switch (tape.landAnswer(answer.key!, answer.value)) {
          TapeChanged(:final tape) => tape,
          final other => throw StateError('$other'),
        };
      }

      blocTest<CalculatorBloc, CalculatorState>(
        'the first = lands Area; a second and a third = are refused as the '
        'result already shown, while a tapped chip still lands its answer',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '[Length] 2 0 ft [Width] 1 0 ft = = =');
          bloc.add(
            CalculatorSuggestionAccepted(
              CalculatorState(
                tape: landedOn(pressed('[Length] 2 0 ft [Width] 1 0 ft'), 0),
              ).suggestions.first,
            ),
          );
        },
        skip: 8,
        expect: () {
          final area = landedOn(pressed('[Length] 2 0 ft [Width] 1 0 ft'), 0);
          return [
            tapeState(area),
            tapeState(area).copyWith(
              refusal: () => const TapeRefused(TapeRefusal.resultAlreadyShown),
            ),
            tapeState(landedOn(area, 0)),
          ];
        },
        verify: (bloc) {
          expect(
            [for (final chip in bloc.state.chipsList) chip.label],
            ['Length', 'Width', 'Area', 'Diagonal'],
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'accepting the acre chip converts the area result in place '
        '(walkthrough 14.5), and the other conversions stay on offer',
        build: () => bloc,
        act: (bloc) {
          type(bloc, '2 0 0 ft × 8 0 ft =');
          bloc.add(
            CalculatorSuggestionAccepted(
              stateOf('2 0 0 ft × 8 0 ft =').conversions.last,
            ),
          );
        },
        skip: 9,
        expect: () => [
          isA<CalculatorState>()
              .having((s) => s.valueText, 'valueText', '0.3673acre')
              .having((s) => s.labelKeyId, 'labelKeyId', Tape.calcKey)
              .having((s) => s.refusal, 'refusal', isNull),
        ],
        verify: (bloc) {
          expect(
            [for (final s in bloc.state.conversions) s.text],
            ['16,000ft²', '1,777.78yd²', '2,304,000in²', '1,486.45m²'],
          );
        },
      );

      for (final (keys, chip) in const [
        ('2 yd', '6ft 0in'),
        ('2 6 4 in', '22ft 0in'),
        ('1 2 ft × 5 ft =', '6.67yd²'),
      ]) {
        blocTest<CalculatorBloc, CalculatorState>(
          'accepting the conversion chip "$chip" lands the text the chip '
          'shows: $keys (Section 1.2, walkthrough 14.2)',
          build: () => bloc,
          act: (bloc) {
            type(bloc, keys);
            bloc.add(
              CalculatorSuggestionAccepted(stateOf(keys).conversions.first),
            );
          },
          skip: keys.split(' ').length,
          expect: () => [
            isA<CalculatorState>()
                .having((s) => s.valueText, 'valueText', chip)
                .having((s) => s.refusal, 'refusal', isNull),
          ],
        );
      }
    });

    group('S1b 4/6: the label and the value', () {
      CalculatorState stateOf(String keys) =>
          CalculatorState(tape: pressed(keys));

      test(
        'the label names the key, the operator of a chip with no key, or '
        'a bare value, with the reading of a bare number (S134, S42, S95)',
        () {
          expect(stateOf('').displayLabel, isNull);
          expect(
            stateOf('1 2 ft').displayLabel,
            const CalculatorDisplayLabel(),
          );
          expect(
            stateOf('1 2').displayLabel,
            const CalculatorDisplayLabel(isTyping: true),
          );
          expect(
            stateOf('[Length] 2 2').displayLabel,
            const CalculatorDisplayLabel(keyId: 'Length', isTyping: true),
          );
          expect(
            stateOf('[Length] 2 2 ft').displayLabel,
            const CalculatorDisplayLabel(keyId: 'Length'),
          );
          expect(
            stateOf('5').displayLabel,
            const CalculatorDisplayLabel(isTyping: true),
          );
          expect(
            stateOf('2 + 1 2').displayLabel,
            const CalculatorDisplayLabel(operator: Operator.add),
          );
          expect(
            stateOf('2 × [Width] 1 8').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Width',
              operator: Operator.multiply,
              isTyping: true,
            ),
          );
          expect(
            stateOf('2 × [Pitch] 3 0 .').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Pitch',
              operator: Operator.multiply,
              reading: NumberReading.degrees,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[Slope] 7').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Slope',
              reading: NumberReading.grade,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[Pitch] 8 in').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Pitch',
              reading: NumberReading.risePerFoot,
            ),
          );
          expect(
            stateOf('[Pitch] 3 0').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Pitch',
              reading: NumberReading.degrees,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[Pitch] 6 / 1 2').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Pitch',
              reading: NumberReading.risePerFoot,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[SIN]').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Sine',
              reading: NumberReading.degrees,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[ACOS] 0 . 5').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Arccosine',
              reading: NumberReading.ratio,
              isTyping: true,
            ),
          );
          expect(
            stateOf('3 8 [DMS] 3 0').displayLabel,
            const CalculatorDisplayLabel(
              reading: NumberReading.degreesMinutesSeconds,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[Pitch] 3 8 [DMS] 3 0').displayLabel,
            const CalculatorDisplayLabel(
              keyId: 'Pitch',
              reading: NumberReading.degreesMinutesSeconds,
              isTyping: true,
            ),
          );
          expect(
            stateOf('[Width]').displayLabel,
            const CalculatorDisplayLabel(keyId: 'Width', isTyping: true),
          );
          expect(
            stateOf('2 ft × 3 =').displayLabel,
            const CalculatorDisplayLabel(keyId: Tape.calcKey),
          );
          expect(
            stateOf('7 8 lbs ÷ 1 2 ft =').displayLabel,
            CalculatorDisplayLabel(keyId: CalculationError.dimensionError.name),
          );
        },
      );

      test('a bracket\'s factor is the icon of the operator that leads it, '
          'and none when the bracket starts the chain', () {
        expect(
          stateOf('2 + ( 3 (').chipsList.last.factor,
          CoreIcons.addOperator,
        );
        expect(
          stateOf('2 − ( 3 (').chipsList.last.factor,
          CoreIcons.subtractOperator,
        );
        expect(
          stateOf('2 × ( 3 (').chipsList.last.factor,
          CoreIcons.multiplyOperator,
        );
        expect(stateOf('2 ÷ ( 3 (').chipsList.last.factor, CoreIcons.divide);
        expect(stateOf('( 3 (').chipsList.last.factor, isNull);
        expect(stateOf('2 + 3').chipsList.last.factor, isNull);
      });

      test('a closed bracket is named by its operator and its inside, and '
          'the value row shows what it is worth (Section 7)', () {
        final closed = stateOf('2 + ( 3 × 4 (');
        expect(
          closed.displayLabel,
          const CalculatorDisplayLabel(
            operator: Operator.add,
            bracketExpression: '3×4',
          ),
        );
        expect(closed.valueText, '12');
        expect([for (final chip in closed.chipsList) chip.value], ['2', '3×4']);

        final first = stateOf('( 3 × 4 (');
        expect(
          first.displayLabel,
          const CalculatorDisplayLabel(bracketExpression: '3×4'),
        );
        expect(first.valueText, '12');

        final open = stateOf('2 + ( 3 × 4');
        expect(
          open.displayLabel,
          const CalculatorDisplayLabel(operator: Operator.multiply),
        );
        expect(open.valueText, '4');

        final empty = stateOf('2 + (');
        expect(empty.displayLabel, isNull);
        expect(empty.valueText, '');
        expect(
          stateOf('2 + ( 3 ×').displayLabel,
          const CalculatorDisplayLabel(
            operator: Operator.multiply,
            isTyping: true,
          ),
        );
        expect([for (final chip in empty.chipsList) chip.value], ['2', '']);
        expect(empty.chipsList.last.type, CoreCalculatorChipType.bracketOpen);
        expect(empty.chipsList.last.factor, CoreIcons.addOperator);
      });

      test('the value row and the tape write a bare number\'s reading after '
          'it: degrees, a grade, a rise per 12in; a point still open, a '
          'D:M:S spelling and a ratio are left as typed', () {
        expect(stateOf('[Pitch] 3 0').valueText, '30°');
        expect(stateOf('[Pitch] 8 .').valueText, '8.');
        expect(stateOf('[Pitch] 8 . 4 5').valueText, '8.45°');
        expect(stateOf('[Pitch] 8 in').valueText, '8in/12in');
        expect(stateOf('[Pitch] 6 / 1 2').valueText, '6/12');
        expect(
          [
            for (final chip in stateOf('[Pitch] 6 / 1 2 +').chipsList)
              chip.value,
          ],
          ['6in/12in', '+'],
        );
        expect(stateOf('[Pitch] 1 / 4 in').valueText, '1/4in/12in');
        expect(
          [
            for (final chip in stateOf('[Pitch] 1 / 4 in +').chipsList)
              chip.value,
          ],
          ['1/4in/12in', '+'],
        );
        expect(stateOf('[Slope] 7').valueText, '7%');
        expect(stateOf('[SIN] 3 8 . 3 0').valueText, '38.30°');
        expect(stateOf('[ACOS] 0 . 5').valueText, '0.5');
        expect(stateOf('3 8 [DMS] 3 0').valueText, '38°30\'00"');
        expect(stateOf('[Width] 1 8 ft 8').valueText, '18ft 8');
        expect(stateOf('[Pitch]').valueText, '');
        expect(
          [for (final chip in stateOf('[Pitch] 8 in').chipsList) chip.value],
          ['8in/12in'],
        );
        expect(
          [
            for (final chip in stateOf('3 8 [SIN]').chipsList)
              '${chip.label}${chip.value}',
          ],
          ['Sine38°', 'Sine0.615661'],
        );
      });
    });

    group('S1b 5/6: the pills', () {
      CalculatorState stateOf(String keys) =>
          CalculatorState(tape: pressed(keys));

      test('the Read-as pill offers the other reading of the number on the '
          'display, as a sentence from its reading to the next (S86, S92, '
          'S115, S116)', () {
        CalculatorReadAsPill pillOf(String keys) =>
            stateOf(keys).dependentKeys.single as CalculatorReadAsPill;

        expect(pillOf('[Pitch] 8 . 4 5').sourceText, '8.45°');
        expect(pillOf('[Pitch] 8 . 4 5').targetText, '8.45in/12in');
        expect(pillOf('[Pitch] 8 . 4 5').rebuildsAnAnswer, isFalse);
        expect(pillOf('[Pitch] 8 in').sourceText, '8in/12in');
        expect(pillOf('[Pitch] 8 in').targetText, '8°');
        expect(pillOf('[Pitch] 8 .').sourceText, '8.');
        expect(pillOf('[Pitch] 8 .').targetText, '8°00\'00"');
        expect(pillOf('[Slope] 0 . 6 5').sourceText, '0.65%');
        expect(pillOf('[Slope] 0 . 6 5').targetText, '65%');
        expect(pillOf('[SIN] 3 8 . 3 0').sourceText, '38.30°');
        expect(pillOf('[SIN] 3 8 . 3 0').targetText, '38°30\'00"');
        expect(pillOf('3 8 . 3 0 [SIN]').sourceText, '38.30°');
        expect(pillOf('3 8 . 3 0 [SIN]').rebuildsAnAnswer, isTrue);
        expect(stateOf('[Pitch] 1 0 0').dependentKeys, isEmpty);
        expect(
          stateOf('[Rise] 6 ft [Run] 1 2 ft [Pitch]').dependentKeys,
          isEmpty,
          reason: 'a pitch answer carries no pill (Section 8)',
        );
        expect(stateOf('[Slope] 2 . 5').dependentKeys, isEmpty);
        expect(stateOf('[Length] 2 2 ft').dependentKeys, isEmpty);
        expect(stateOf('[ACOS] 0 . 5').dependentKeys, isEmpty);
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'taking the Read-as pill re-reads the number from its digits, and a '
        'trig answer after it is rebuilt (S91)',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('8'))
          ..add(const CalculatorDigitPressed('.'))
          ..add(const CalculatorDigitPressed('3'))
          ..add(const CalculatorDigitPressed('0'))
          ..add(const CalculatorKeySelected('SIN'))
          ..add(const CalculatorReadAsAccepted()),
        skip: 6,
        expect: () => [
          tapeState(switch (pressed('3 8 . 3 0 [SIN]').reInput()) {
            TapeChanged(:final tape) => tape,
            final other => throw StateError('$other'),
          }),
        ],
        verify: (bloc) {
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['38°30\'00"', '0.622515'],
          );
          expect(
            (bloc.state.dependentKeys.single as CalculatorReadAsPill)
                .targetText,
            '38.30°',
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the Read-as pill tapped with nothing to re-read is refused',
        build: () => bloc,
        act: (bloc) => bloc.add(const CalculatorReadAsAccepted()),
        expect: () => [
          const CalculatorState(
            refusal: TapeRefused(TapeRefusal.nothingToReInput),
          ),
        ],
      );
    });

    group('S1b 6/6: the strip notes', () {
      CalculatorState stateOf(String keys) =>
          CalculatorState(tape: pressed(keys));

      test('a pitch of 90° or more, a flat pitch with a Rise alone, and a '
          'slope of 0% say why the strip is empty, and keep saying it under '
          'a second value (S89); a flat pitch with a Run answers Rise 0ft', () {
        expect(
          stateOf('[Pitch] 8 9 9').stripNote,
          const CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: true),
        );
        expect(stateOf('[Pitch] 8 9 9').suggestions, isEmpty);
        expect(
          stateOf('[Pitch] 9 0').stripNote,
          const CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: true),
        );
        expect(stateOf('[Pitch] 0').stripNote, isNull);
        expect(
          [for (final s in stateOf('[Pitch] 0').suggestions) s.key],
          [
            DeterministicRules.pitchDegreesKey,
            DeterministicRules.pitchRiseKey,
            DeterministicRules.pitchGradeKey,
          ],
        );
        expect(stateOf('[Pitch] 0 [Run] 1 0 ft').stripNote, isNull);
        expect(
          [
            for (final s in stateOf('[Pitch] 0 [Run] 1 0 ft').suggestions)
              '${s.key}: ${s.text}',
          ],
          ['Rise: 0ft', 'Diagonal: 10ft'],
        );
        expect(
          stateOf('[Pitch] 0 [Rise] 1 0 ft').stripNote,
          const CalculatorFlatPitchHasNoRunNote(),
        );
        expect(stateOf('[Pitch] 0 [Rise] 1 0 ft').suggestions, isEmpty);
        expect(stateOf('[Pitch] 0 [Rise] 1 0 ft').conversions, isEmpty);
        expect(
          stateOf('[Pitch] 9 5 [Diag] 2 2 ft').stripNote,
          const CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: true),
        );
        expect(stateOf('[Pitch] 9 5 [Diag] 2 2 ft').suggestions, isEmpty);
        expect(
          stateOf('[Slope] 0').stripNote,
          const CalculatorSlopeOutOfRangeNote(),
        );
        expect(stateOf('[Pitch] 0 in').stripNote, isNull);
        expect(
          stateOf('[Pitch] 9 5 [Run] 1 0 ft').conversions,
          isEmpty,
          reason: 'a note takes the place of both rows (Section 1.8)',
        );
        expect(stateOf('[Slope] 0 [Run] 1 0 ft').conversions, isEmpty);
        expect(stateOf('[Pitch] 9 5 [Diag] 2 2 ft').conversions, isEmpty);
        expect(stateOf('[Pitch] 8 in').stripNote, isNull);
        expect(stateOf('[Pitch] 8 9').stripNote, isNull);
        expect(stateOf('[Slope] 7').stripNote, isNull);
        expect(stateOf('').stripNote, isNull);
      });

      test('a prefix trig chip its function cannot answer says so while the '
          'operand stays (Section 5.4)', () {
        expect(
          stateOf('[ACOS] 4 5').stripNote,
          const CalculatorTrigCannotAnswerNote(TrigFunction.arccosine),
        );
        expect(
          stateOf('[TAN] 9 0').stripNote,
          const CalculatorTrigCannotAnswerNote(TrigFunction.tangent),
        );
        expect(stateOf('[ACOS] 0 . 5').stripNote, isNull);
        expect(stateOf('[ACOS] 4 5').suggestions, isEmpty);
      });

      blocTest<CalculatorBloc, CalculatorState>(
        'the D:M:S key on a pitch answer changes nothing and the note says '
        'so until the next key, which brings the other spellings back',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const CalculatorKeySelected('Rise'))
          ..add(const CalculatorDigitPressed('6'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorKeySelected('Run'))
          ..add(const CalculatorDigitPressed('1'))
          ..add(const CalculatorDigitPressed('2'))
          ..add(const CalculatorUnitSelected(Unit.foot))
          ..add(const CalculatorKeySelected('Pitch'))
          ..add(const CalculatorKeySelected('DMS'))
          ..add(const CalculatorKeySelected('Pitch')),
        skip: 8,
        expect: () => [
          tapeState(pressed('[Rise] 6 ft [Run] 1 2 ft [Pitch]')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.pitchHasNoDms),
          ),
          tapeState(pressed('[Rise] 6 ft [Run] 1 2 ft [Pitch] [Pitch]')),
        ],
        verify: (bloc) {
          final refused = tapeState(pressed('[Rise] 6 ft [Run] 1 2 ft [Pitch]'))
              .copyWith(
                refusal: () => const TapeRefused(TapeRefusal.pitchHasNoDms),
              );
          expect(refused.stripNote, const CalculatorPitchHasNoDmsNote());
          expect(refused.suggestions, isEmpty);
          expect(bloc.state.stripNote, isNull);
          expect(bloc.state.suggestions, isNotEmpty);
        },
      );

      test('a note never shows after an error chip or inside a bracket, and '
          'a warning outranks a key that changed nothing', () {
        expect(
          CalculatorState(
            tape: pressed('7 8 lbs ÷ 1 2 ft ='),
            refusal: const TapeRefused(TapeRefusal.pitchHasNoDms),
          ).stripNote,
          isNull,
        );
        expect(
          CalculatorState(
            tape: pressed('[Pitch] 9 5'),
            refusal: const TapeRefused(TapeRefusal.pitchHasNoDms),
          ).stripNote,
          const CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: true),
        );
        expect(stateOf('2 + ( 3').stripNote, isNull);
      });
    });

    test(
      'the initial state is an empty imperial tape with the first group',
      () {
        final state = CalculatorState.initial();
        expect(state.tape, const Tape());
        expect(state.currentGroupIndex, 0);
        expect(state.groupOrder, CalculatorGroupId.defaultOrder);
        expect(state.currentUnitSystem, UnitSystem.imperial);
        expect(state.tape.beingTyped, isNull);
        expect(state.labelKeyId, isNull);
        expect(state.valueText, '');
        expect(state.chipsList, isEmpty);
        expect(state.notice, isNull);
        expect(state.refusal, isNull);
      },
    );
  });
}

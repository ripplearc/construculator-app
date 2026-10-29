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
        expect(state.isTyping, isTrue);
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
          expect(bloc.state.isTyping, isFalse);
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
            ['2', '+(3×4)'],
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
          expect(bloc.state.chipsList.single.value, '(3');
          expect(bloc.state.chipsList.single.label, isNull);
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
          expect(bloc.state.isTyping, isTrue);
          expect(bloc.state.labelKeyId, isNull);
          expect(bloc.state.valueText, '×4');
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['2', '+(3×4'],
          );
        },
      );
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
          expect(bloc.state.isTyping, isTrue);
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
          expect(bloc.state.isTyping, isFalse);
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
            ['30', '+6', '+'],
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
        'nothing being typed it is refused',
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
            refusal: () => const TapeRefused(TapeRefusal.nothingToCompute),
          ),
          tapeState(pressed('2 ft + 1 8 ✕')).copyWith(
            refusal: () => const TapeRefused(TapeRefusal.nothingBeingTyped),
          ),
        ],
      );
    });

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

    group('S1b 2/4: the strip and the equals key', () {
      List<String> row1(CalculatorState state) => [
        for (final suggestion in state.suggestions)
          '${suggestion.key}: ${suggestion.text}',
      ];

      List<String> row2(CalculatorState state) => [
        for (final suggestion in state.conversions) suggestion.text,
      ];

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
        expect(row1(offered).take(3), [
          'Pitch-rise per 12in run: 6in/12in',
          'Pitch-degrees: 26.57°',
          'Pitch-grade: 50%',
        ]);
        expect(offered.equalsKeyId, DeterministicRules.pitchRiseKey);
        final landed = CalculatorState(
          tape: pressed('[Rise] 6 ft [Run] 1 2 ft [Pitch]'),
        );
        expect(row1(landed).take(2), [
          'Pitch-degrees: 26.57°',
          'Pitch-grade: 50%',
        ]);
        expect(row2(landed), isEmpty);
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

    test(
      'the initial state is an empty imperial tape with the first group',
      () {
        final state = CalculatorState.initial();
        expect(state.tape, const Tape());
        expect(state.currentGroupIndex, 0);
        expect(state.currentUnitSystem, UnitSystem.imperial);
        expect(state.isTyping, isFalse);
        expect(state.labelKeyId, isNull);
        expect(state.valueText, '');
        expect(state.chipsList, isEmpty);
        expect(state.notice, isNull);
        expect(state.refusal, isNull);
      },
    );
  });
}

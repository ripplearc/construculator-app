import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/calculator/calculator_module.dart';
import 'package:construculator/features/calculator/data/models/calculator_preferences_dto.dart';
import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../utils/calculator_test_harness.dart';

void main() {
  late CalculatorTestHarness harness;
  late CalculatorBloc bloc;

  // The real chain from the module: the bloc over the settings repository
  // over the auth fakes, with the harness's fakes in place of the
  // bootstrap's so a test can sign a profile in and announce changes.
  setUp(() {
    harness = CalculatorTestHarness();
    Modular.init(CalculatorModule(FakeAppBootstrapFactory.create()));
    Modular.replaceInstance<AuthNotifier>(harness.authNotifier);
    Modular.replaceInstance<AuthManager>(harness.authManager);
    bloc = Modular.get<CalculatorBloc>();
  });

  tearDown(() async {
    await bloc.close();
    Modular.destroy();
    harness.dispose();
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
        'm' => current.pressUnit(Unit.metre),
        'lbs' => current.pressUnit(Unit.pound),
        'ton' => current.pressUnit(Unit.ton),
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
        build: () {
          harness.signIn(harness.userWith({}));
          return bloc;
        },
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
        build: () {
          harness.signIn(harness.userWith({}));
          return bloc;
        },
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

    group('W1 1/4: the settings arrive and the pill saves', () {
      const longTon = CalculatorPreferences(
        tonDefinition: TonDefinition.longTon,
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the settings that arrive re-render every result on the tape and '
        'never what was typed (rule 4.14): 44,550lbs as a ton reads 22.28 '
        'under the short ton and 19.89 under the long ton',
        build: () {
          harness.signIn(harness.userWith({}));
          return bloc;
        },
        act: (bloc) async {
          for (final digit in '44550'.split('')) {
            bloc.add(CalculatorDigitPressed(digit));
          }
          bloc
            ..add(const CalculatorKeySelected('lbs'))
            ..add(const CalculatorOperatorPressed(Operator.multiply))
            ..add(const CalculatorDigitPressed('1'))
            ..add(const CalculatorEqualsPressed())
            ..add(const CalculatorKeySelected('ton'));
          await bloc.stream.firstWhere((s) => s.valueText == '22.28 ton');
          harness.announce(
            harness.userWith({
              'calculator': {'pounds_per_ton': 2240},
            }),
          );
          await bloc.stream.firstWhere((s) => s.valueText == '19.89 ton');
        },
        skip: 10,
        expect: () => [
          tapeState(
            pressed('4 4 5 5 0 lbs × 1 = ton').withPreferences(longTon),
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.tape.preferences, longTon);
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['44550lbs', '×1', '19.89 ton'],
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the System of units pill re-renders at once and saves the choice '
        'to the profile, with no toast (walkthrough 22.1)',
        build: () {
          harness.signIn(harness.userWith({}));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CalculatorUnitSystemChanged(UnitSystem.metric));
          await bloc.stream.firstWhere(
            (s) => s.currentUnitSystem == UnitSystem.metric,
          );
          await pumpEventQueue();
        },
        expect: () => [
          const CalculatorState(
            tape: Tape(
              preferences: CalculatorPreferences(
                system: MeasurementSystem.metric,
              ),
            ),
          ),
        ],
        verify: (bloc) async {
          expect(bloc.state.settingSaveFailure, isNull);
          await harness.repository.watchPreferences().firstWhere(
            (preferences) => preferences.system == MeasurementSystem.metric,
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the pill\'s tap switches to the other system each time, and the '
        'echo of each save is consumed rather than applied',
        build: () {
          harness.signIn(harness.userWith({}));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CalculatorUnitSystemToggled());
          await bloc.stream.firstWhere(
            (s) => s.currentUnitSystem == UnitSystem.metric,
          );
          bloc.add(const CalculatorUnitSystemToggled());
          await bloc.stream.firstWhere(
            (s) => s.currentUnitSystem == UnitSystem.imperial,
          );
          await pumpEventQueue();
        },
        expect: () => [
          const CalculatorState(
            tape: Tape(
              preferences: CalculatorPreferences(
                system: MeasurementSystem.metric,
              ),
            ),
          ),
          const CalculatorState(),
        ],
        verify: (bloc) async {
          await harness.repository.watchPreferences().firstWhere(
            (preferences) => preferences.system == MeasurementSystem.imperial,
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a save with no profile signed in keeps the choice on screen and '
        'says why it was not saved',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const CalculatorUnitSystemChanged(UnitSystem.metric));
          await bloc.stream.firstWhere((s) => s.settingSaveFailure != null);
        },
        expect: () => [
          const CalculatorState(
            tape: Tape(
              preferences: CalculatorPreferences(
                system: MeasurementSystem.metric,
              ),
            ),
          ),
          isA<CalculatorState>()
              .having(
                (s) => s.tape.preferences.system,
                'system',
                MeasurementSystem.metric,
              )
              .having(
                (s) => s.settingSaveFailure,
                'settingSaveFailure',
                isA<UserNotFoundFailure>(),
              ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'two taps before either is handled switch the system twice, not to '
        'the same system',
        build: () {
          harness.signIn(harness.userWith({}));
          return bloc;
        },
        act: (bloc) async {
          bloc
            ..add(const CalculatorUnitSystemToggled())
            ..add(const CalculatorUnitSystemToggled());
          await bloc.stream.firstWhere(
            (s) => s.currentUnitSystem == UnitSystem.imperial,
          );
          await pumpEventQueue();
        },
        expect: () => [
          const CalculatorState(
            tape: Tape(
              preferences: CalculatorPreferences(
                system: MeasurementSystem.metric,
              ),
            ),
          ),
          const CalculatorState(),
        ],
      );

      late Completer<void> saveGate;

      blocTest<CalculatorBloc, CalculatorState>(
        'the echo of a save that lands after a newer choice was made does '
        'not take that choice back',
        build: () {
          harness.signIn(harness.userWith({}));
          saveGate = Completer<void>();
          harness.authRepository.updateUserProfileGate = saveGate;
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CalculatorUnitSystemToggled());
          await bloc.stream.firstWhere(
            (s) => s.currentUnitSystem == UnitSystem.metric,
          );
          bloc.add(const CalculatorUnitSystemToggled());
          await bloc.stream.firstWhere(
            (s) => s.currentUnitSystem == UnitSystem.imperial,
          );
          saveGate.complete();
          await pumpEventQueue();
        },
        expect: () => [
          const CalculatorState(
            tape: Tape(
              preferences: CalculatorPreferences(
                system: MeasurementSystem.metric,
              ),
            ),
          ),
          const CalculatorState(),
        ],
        verify: (bloc) {
          expect(
            harness.authRepository.updateProfileCalls.map(
              (user) =>
                  user.userPreferences[CalculatorPreferencesDto
                      .preferencesKey][CalculatorPreferencesDto.systemKey],
            ),
            ['metric', 'imperial'],
          );
        },
      );

      test('the System of units pill shows only while the tape is empty', () {
        expect(CalculatorState.initial().showsUnitsPill, isTrue);
        expect(tapeState(pressed('5')).showsUnitsPill, isFalse);
        expect(tapeState(pressed('(')).showsUnitsPill, isFalse);
        expect(tapeState(pressed('[Width]')).showsUnitsPill, isFalse);
      });
    });

    group('W1 2/4: the setting sheets', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'a setting sheet opens on request, closes without a change, and '
        'Update re-renders the results, saves and signals the toast '
        '(walkthrough 22.2)',
        build: () {
          harness.signIn(harness.userWith({}));
          return bloc;
        },
        act: (bloc) async {
          bloc
            ..add(const CalculatorDigitPressed('1'))
            ..add(const CalculatorDigitPressed('0'))
            ..add(const CalculatorUnitSelected(Unit.inch))
            ..add(const CalculatorOperatorPressed(Operator.divide))
            ..add(const CalculatorDigitPressed('3'))
            ..add(const CalculatorEqualsPressed())
            ..add(
              const CalculatorSettingSheetOpened(
                CalculatorSetting.fractionResolution,
              ),
            )
            ..add(const CalculatorSettingSheetClosed())
            ..add(
              const CalculatorSettingSheetOpened(
                CalculatorSetting.fractionResolution,
              ),
            )
            ..add(
              const CalculatorSettingUpdated(
                CalculatorSetting.fractionResolution,
                'half',
              ),
            );
          await bloc.stream.firstWhere(
            (s) => s.settingSaved == CalculatorSetting.fractionResolution,
          );
        },
        skip: 5,
        expect: () => [
          tapeState(pressed('1 0 in ÷ 3 =')),
          tapeState(pressed('1 0 in ÷ 3 =')).copyWith(
            openSettingSheet: () => CalculatorSetting.fractionResolution,
          ),
          tapeState(pressed('1 0 in ÷ 3 =')),
          tapeState(pressed('1 0 in ÷ 3 =')).copyWith(
            openSettingSheet: () => CalculatorSetting.fractionResolution,
          ),
          tapeState(
            pressed('1 0 in ÷ 3 =').withPreferences(
              const CalculatorPreferences(
                fractionResolution: FractionResolution.half,
              ),
            ),
          ),
          tapeState(
            pressed('1 0 in ÷ 3 =').withPreferences(
              const CalculatorPreferences(
                fractionResolution: FractionResolution.half,
              ),
            ),
          ).copyWith(settingSaved: () => CalculatorSetting.fractionResolution),
        ],
        verify: (bloc) {
          expect(tapeState(pressed('1 0 in ÷ 3 =')).valueText, '0ft 3-5/16in');
          expect(bloc.state.valueText, '0ft 3-1/2in');
          expect(
            [for (final chip in bloc.state.chipsList) chip.value],
            ['10in', '÷3', '0ft 3-1/2in'],
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the ton, metre and density sheets each apply their option, and the '
        'next key clears the toast signal',
        build: () {
          harness.signIn(harness.userWith({}));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(
            const CalculatorSettingUpdated(
              CalculatorSetting.tonDefinition,
              'longTon',
            ),
          );
          await bloc.stream.firstWhere((s) => s.settingSaved != null);
          bloc.add(
            const CalculatorSettingUpdated(
              CalculatorSetting.metreDisplay,
              'threeDecimals',
            ),
          );
          await bloc.stream.firstWhere((s) => s.settingSaved != null);
          bloc.add(
            const CalculatorSettingUpdated(
              CalculatorSetting.densityUnit,
              'kilogramsPerCubicMetre',
            ),
          );
          await bloc.stream.firstWhere((s) => s.settingSaved != null);
          bloc.add(const CalculatorDigitPressed('5'));
        },
        skip: 6,
        expect: () => [
          tapeState(
            pressed(
              '5',
              tape: const Tape(
                preferences: CalculatorPreferences(
                  tonDefinition: TonDefinition.longTon,
                  metreDisplay: MetreDisplay.threeDecimals,
                  densityUnit: DensityUnit.kilogramsPerCubicMetre,
                ),
              ),
            ),
          ),
        ],
        verify: (bloc) async {
          expect(bloc.state.settingSaved, isNull);
          await harness.repository.watchPreferences().firstWhere(
            (preferences) =>
                preferences ==
                const CalculatorPreferences(
                  tonDefinition: TonDefinition.longTon,
                  metreDisplay: MetreDisplay.threeDecimals,
                  densityUnit: DensityUnit.kilogramsPerCubicMetre,
                ),
          );
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'an Update with no profile signed in keeps the choice on screen, says '
        'why it was not saved and raises no toast',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(
            const CalculatorSettingUpdated(
              CalculatorSetting.tonDefinition,
              'longTon',
            ),
          );
          await bloc.stream.firstWhere((s) => s.settingSaveFailure != null);
        },
        expect: () => [
          const CalculatorState(
            tape: Tape(
              preferences: CalculatorPreferences(
                tonDefinition: TonDefinition.longTon,
              ),
            ),
          ),
          isA<CalculatorState>()
              .having(
                (s) => s.tape.preferences.tonDefinition,
                'tonDefinition',
                TonDefinition.longTon,
              )
              .having(
                (s) => s.settingSaveFailure,
                'settingSaveFailure',
                isA<UserNotFoundFailure>(),
              )
              .having((s) => s.settingSaved, 'settingSaved', isNull),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'a save equal to what last arrived expects no echo, so a later '
        'change from another device to that same value is applied',
        build: () {
          harness.signIn(harness.userWith({}));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(
            const CalculatorSettingUpdated(
              CalculatorSetting.tonDefinition,
              'shortTon',
            ),
          );
          await bloc.stream.firstWhere((s) => s.settingSaved != null);
          harness.announce(
            harness.userWith({
              'calculator': {'pounds_per_ton': 2240},
            }),
          );
          await bloc.stream.firstWhere(
            (s) => s.tape.preferences.tonDefinition == TonDefinition.longTon,
          );
          harness.announce(
            harness.userWith({
              'calculator': {'pounds_per_ton': 2000},
            }),
          );
          await bloc.stream.firstWhere(
            (s) => s.tape.preferences.tonDefinition == TonDefinition.shortTon,
          );
        },
        skip: 1,
        // Settings arriving are not a key, so the toast signal of the save
        // stays until the next key.
        expect: () => [
          const CalculatorState(
            tape: Tape(
              preferences: CalculatorPreferences(
                tonDefinition: TonDefinition.longTon,
              ),
            ),
            settingSaved: CalculatorSetting.tonDefinition,
          ),
          const CalculatorState(settingSaved: CalculatorSetting.tonDefinition),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'the pill\'s tap switches to the other system, and the sheet\'s '
        'close after Update keeps the toast signal',
        build: () {
          harness.signIn(harness.userWith({}));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const CalculatorUnitSystemToggled());
          await bloc.stream.firstWhere(
            (s) => s.currentUnitSystem == UnitSystem.metric,
          );
          bloc.add(const CalculatorUnitSystemToggled());
          await bloc.stream.firstWhere(
            (s) => s.currentUnitSystem == UnitSystem.imperial,
          );
          bloc.add(
            const CalculatorSettingUpdated(
              CalculatorSetting.metreDisplay,
              'oneDecimal',
            ),
          );
          await bloc.stream.firstWhere((s) => s.settingSaved != null);
          bloc.add(const CalculatorSettingSheetClosed());
          await pumpEventQueue();
        },
        verify: (bloc) {
          expect(bloc.state.currentUnitSystem, UnitSystem.imperial);
          expect(bloc.state.settingSaved, CalculatorSetting.metreDisplay);
          expect(
            bloc.state.tape.preferences.metreDisplay,
            MetreDisplay.oneDecimal,
          );
        },
      );

      test('a sheet names its options by the setting\'s values and applies '
          'one by its id', () {
        expect(CalculatorSetting.fractionResolution.optionIds, [
          'half',
          'quarter',
          'eighth',
          'sixteenth',
          'thirtySecond',
          'sixtyFourth',
        ]);
        expect(CalculatorSetting.tonDefinition.optionIds, [
          'shortTon',
          'longTon',
        ]);
        expect(CalculatorSetting.metreDisplay.optionIds, [
          'oneDecimal',
          'twoDecimals',
          'threeDecimals',
        ]);
        expect(CalculatorSetting.densityUnit.optionIds, [
          'poundsPerCubicYard',
          'poundsPerCubicFoot',
          'tonsPerCubicYard',
          'kilogramsPerCubicMetre',
        ]);
        for (final setting in CalculatorSetting.values) {
          expect(
            setting.optionIds,
            contains(setting.selectedOptionId(CalculatorPreferences.defaults)),
          );
          for (final id in setting.optionIds) {
            expect(
              setting.selectedOptionId(
                setting.applied(CalculatorPreferences.defaults, id),
              ),
              id,
            );
          }
        }
        expect(
          () => CalculatorSetting.tonDefinition.applied(
            CalculatorPreferences.defaults,
            'stone',
          ),
          throwsArgumentError,
        );
      });
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

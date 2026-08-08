import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late CalculatorBloc bloc;

  setUp(() {
    bloc = CalculatorBloc();
  });

  tearDown(() {
    bloc.close();
  });

  group('CalculatorBloc', () {
    group('CalculatorDigitPressed', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'appends digit to currentInputValue when isTyping',
        build: () => bloc,
        seed: () => const CalculatorState(isTyping: true),
        act: (bloc) {
          bloc.add(const CalculatorDigitPressed('1'));
          bloc.add(const CalculatorDigitPressed('2'));
        },
        expect: () => [
          const CalculatorState(
            isTyping: true,
            currentInputValue: '1',
            currentNumericValue: '1',
          ),
          const CalculatorState(
            isTyping: true,
            currentInputValue: '12',
            currentNumericValue: '12',
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'does nothing when not isTyping',
        build: () => bloc,
        act: (bloc) => bloc.add(const CalculatorDigitPressed('5')),
        expect: () => [],
      );
    });

    group('CalculatorKeySelected', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'finalizes prior input as a chip and sets new active label',
        build: () => bloc,
        seed: () => const CalculatorState(
          isTyping: true,
          activeInputLabel: 'Rise',
          currentInputValue: '6',
          currentNumericValue: '6',
        ),
        act: (bloc) => bloc.add(const CalculatorKeySelected('Run')),
        verify: (bloc) {
          expect(bloc.state.activeInputLabel, 'Run');
          expect(bloc.state.isTyping, isTrue);
          expect(bloc.state.currentInputValue, '');
          expect(bloc.state.completedChips.length, 1);
          expect(bloc.state.completedChips[0].label, 'Rise');
          expect(bloc.state.completedChips[0].value, '6');
          expect(bloc.state.completedChips[0].type, CoreCalculatorChipType.editable);
          expect(bloc.state.finalizedValues, {'Rise': 6.0});
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'does not compute pitch when Run is zero',
        build: () => bloc,
        seed: () => const CalculatorState(
          isTyping: true,
          activeInputLabel: 'Run',
          currentInputValue: '0',
          currentNumericValue: '0',
          finalizedValues: {'Rise': 6.0},
        ),
        act: (bloc) => bloc.add(const CalculatorOperatorPressed('=')),
        verify: (bloc) {
          expect(bloc.state.resultLabel, isNull);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'auto-computes pitch when both Rise and Run are finalized via =',
        build: () => bloc,
        seed: () => CalculatorState(
          isTyping: true,
          activeInputLabel: 'Run',
          currentInputValue: '12',
          currentNumericValue: '12',
          completedChips: [
            CoreCalculatorChip(
              label: 'Rise',
              value: '6',
              type: CoreCalculatorChipType.editable,
            ),
          ],
          finalizedValues: const {'Rise': 6.0},
        ),
        act: (bloc) => bloc.add(const CalculatorOperatorPressed('=')),
        verify: (bloc) {
          expect(bloc.state.resultLabel, 'Pitch');
          expect(bloc.state.resultValue, '0.5');
          expect(bloc.state.resultChip, isNotNull);
          expect(bloc.state.finalizedValues['Run'], 12.0);
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'does nothing for a non-= operator',
        build: () => bloc,
        seed: () => const CalculatorState(
          isTyping: true,
          activeInputLabel: 'Run',
          currentInputValue: '12',
          currentNumericValue: '12',
        ),
        act: (bloc) => bloc.add(const CalculatorOperatorPressed('+')),
        expect: () => [],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'activates the pressed key without finalizing anything on the very first key press',
        build: () => bloc,
        act: (bloc) => bloc.add(const CalculatorKeySelected('Width')),
        expect: () => [
          const CalculatorState(
            activeInputLabel: 'Width',
            isTyping: true,
          ),
        ],
        verify: (bloc) {
          expect(bloc.state.completedChips, isEmpty);
          expect(bloc.state.finalizedValues, isEmpty);
        },
      );
    });

    group('CalculatorKeySelected — Fence', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'finalizes an in-progress Length entry before computing fence posts',
        build: () => bloc,
        seed: () => const CalculatorState(
          isTyping: true,
          activeInputLabel: 'Length',
          currentInputValue: '24',
          currentNumericValue: '24',
        ),
        act: (bloc) => bloc.add(const CalculatorKeySelected('Fence')),
        verify: (bloc) {
          expect(bloc.state.finalizedValues['Length'], 24.0);
          expect(bloc.state.resultLabel, 'postsResult');
          expect(bloc.state.resultValue, '5');
          expect(bloc.state.dependentKeyLabel, 'oc');
          expect(bloc.state.dependentKeyValue, '6ft');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'computes fence posts when Length is already finalized',
        build: () => bloc,
        seed: () => const CalculatorState(
          finalizedValues: {'Length': 24.0},
        ),
        act: (bloc) => bloc.add(const CalculatorKeySelected('Fence')),
        verify: (bloc) {
          expect(bloc.state.resultLabel, 'Posts');
          expect(bloc.state.resultValue, '5');
          expect(bloc.state.dependentKeyLabel, 'oc');
          expect(bloc.state.dependentKeyValue, '6ft');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'rounds up to the next whole post on a non-exact O.C. multiple',
        build: () => bloc,
        seed: () => const CalculatorState(finalizedValues: {'Length': 25.0}),
        act: (bloc) => bloc.add(const CalculatorKeySelected('Fence')),
        verify: (bloc) {
          expect(bloc.state.resultLabel, 'Posts');
          expect(bloc.state.resultValue, '6');
        },
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'does nothing when Length is not finalized',
        build: () => bloc,
        act: (bloc) => bloc.add(const CalculatorKeySelected('Fence')),
        verify: (bloc) {
          expect(bloc.state.resultLabel, isNull);
        },
      );
    });

    group('CalculatorControlActioned', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'delete removes last character from currentInputValue',
        build: () => bloc,
        seed: () => const CalculatorState(
          isTyping: true,
          currentInputValue: '123',
          currentNumericValue: '123',
        ),
        act: (bloc) => bloc.add(
          const CalculatorControlActioned(ControlAction.delete),
        ),
        expect: () => [
          const CalculatorState(
            isTyping: true,
            currentInputValue: '12',
            currentNumericValue: '12',
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'delete does nothing when currentInputValue is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const CalculatorControlActioned(ControlAction.delete),
        ),
        expect: () => [],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'clearAll resets to CalculatorState.initial()',
        build: () => bloc,
        seed: () => CalculatorState(
          isTyping: true,
          activeInputLabel: 'Rise',
          currentInputValue: '99',
          currentNumericValue: '99',
          completedChips: [
            CoreCalculatorChip(
              label: 'Width',
              value: '10',
              type: CoreCalculatorChipType.editable,
            ),
          ],
          finalizedValues: const {'Width': 10.0},
        ),
        act: (bloc) => bloc.add(
          const CalculatorControlActioned(ControlAction.clearAll),
        ),
        expect: () => [CalculatorState.initial()],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'moreOptions does nothing',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const CalculatorControlActioned(ControlAction.moreOptions),
        ),
        expect: () => [],
      );
    });

    group('CalculatorUnitSystemChanged', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'updates currentUnitSystem to metric',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const CalculatorUnitSystemChanged(UnitSystem.metric),
        ),
        expect: () => [
          const CalculatorState(currentUnitSystem: UnitSystem.metric),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'updates currentUnitSystem back to imperial',
        build: () => bloc,
        seed: () => const CalculatorState(currentUnitSystem: UnitSystem.metric),
        act: (bloc) => bloc.add(
          const CalculatorUnitSystemChanged(UnitSystem.imperial),
        ),
        expect: () => [
          const CalculatorState(currentUnitSystem: UnitSystem.imperial),
        ],
      );
    });

    group('CalculatorGroupSelected', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'updates currentGroupIndex',
        build: () => bloc,
        act: (bloc) => bloc.add(const CalculatorGroupSelected(2)),
        expect: () => [const CalculatorState(currentGroupIndex: 2)],
      );
    });

    group('CalculatorResetRequested', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'resets all state to initial',
        build: () => bloc,
        seed: () => CalculatorState(
          isTyping: true,
          activeInputLabel: 'Height',
          currentInputValue: '42',
          currentGroupIndex: 1,
          currentUnitSystem: UnitSystem.metric,
          completedChips: [
            CoreCalculatorChip(
              label: 'Width',
              value: '5',
              type: CoreCalculatorChipType.editable,
            ),
          ],
          finalizedValues: const {'Width': 5.0},
        ),
        act: (bloc) => bloc.add(const CalculatorResetRequested()),
        expect: () => [CalculatorState.initial()],
      );
    });

    group('CalculatorUnitSelected', () {
      blocTest<CalculatorBloc, CalculatorState>(
        'appends unit abbreviation to currentInputValue when isTyping',
        build: () => bloc,
        seed: () => const CalculatorState(
          isTyping: true,
          currentInputValue: '10',
        ),
        act: (bloc) => bloc.add(const CalculatorUnitSelected('ft')),
        expect: () => [
          const CalculatorState(
            isTyping: true,
            currentInputValue: '10 ft',
          ),
        ],
      );

      blocTest<CalculatorBloc, CalculatorState>(
        'normalises "feet" to "ft"',
        build: () => bloc,
        seed: () => const CalculatorState(isTyping: true),
        act: (bloc) => bloc.add(const CalculatorUnitSelected('feet')),
        expect: () => [
          const CalculatorState(
            isTyping: true,
            currentInputValue: 'ft',
          ),
        ],
      );
    });

    group('CalculatorState.chipsList', () {
      test('is empty in initial state', () {
        expect(CalculatorState.initial().chipsList, isEmpty);
      });

      test('contains active chip while typing with a label', () {
        const state = CalculatorState(
          isTyping: true,
          activeInputLabel: 'Rise',
          currentInputValue: '6',
        );
        expect(state.chipsList.length, 1);
        expect(state.chipsList.single.label, 'Rise');
        expect(state.chipsList.single.value, '6');
        expect(state.chipsList.single.type, CoreCalculatorChipType.active);
      });

      test('omits active chip when not typing', () {
        const state = CalculatorState(isTyping: false, activeInputLabel: 'Rise');
        expect(state.chipsList, isEmpty);
      });

      test('appends result chip after completed chips', () {
        final resultChip = CoreCalculatorChip(
          label: 'Pitch',
          value: '0.5',
          type: CoreCalculatorChipType.disabled,
        );
        final completedChip = CoreCalculatorChip(
          label: 'Rise',
          value: '6',
          type: CoreCalculatorChipType.editable,
        );
        final state = CalculatorState(
          completedChips: [completedChip],
          resultChip: resultChip,
        );
        expect(state.chipsList.length, 2);
        expect(state.chipsList.first, completedChip);
        expect(state.chipsList.last, resultChip);
      });
    });

    group('functionGroups', () {
      test('has three groups', () {
        expect(CalculatorBloc.functionGroups.length, 3);
      });

      test('first group is basicGeometry with 8 keys', () {
        expect(CalculatorBloc.functionGroups[0].name, 'basicGeometry');
        expect(CalculatorBloc.functionGroups[0].keys.length, 8);
      });

      test('second group is materials with 5 keys', () {
        expect(CalculatorBloc.functionGroups[1].name, 'materials');
        expect(CalculatorBloc.functionGroups[1].keys.length, 5);
      });

      test('third group is trigonometry with 3 keys', () {
        expect(CalculatorBloc.functionGroups[2].name, 'trigonometry');
        expect(CalculatorBloc.functionGroups[2].keys.length, 3);
      });
    });
  });
}

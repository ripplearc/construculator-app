import 'dart:io';

import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../scripts/golden/replay.dart';
import '../../../../scripts/golden/scenario.dart';
import '../../../../scripts/golden/snapshot.dart';

/// Drives [CalculatorBloc] with the prototype's keys and reads its state back
/// as a [Snapshot].
///
/// The bloc does not consume the engine yet (that is G3's work), so most
/// scenarios fail at their first checkpoint — which is what this driver is
/// for today: the readable diff of what the app shows against what the
/// prototype showed, and the N/134 the CI job reports. Keys the bloc has no
/// event for (accepting a strip chip, tapping a tape chip, the sheet) are
/// refused, and the runner reports the scenario as unsupported from there.
class BlocScenarioDriver implements ScenarioDriver {
  CalculatorBloc _bloc = CalculatorBloc();

  /// The bloc under test, for the test to close.
  CalculatorBloc get bloc => _bloc;

  @override
  Future<void> reset() async {
    await _bloc.close();
    _bloc = CalculatorBloc();
  }

  @override
  Future<bool> perform(ScenarioStep step) async {
    if (step is! KeyStep) return false;
    final event = _eventFor(step.key);
    if (event == null) return false;
    _bloc.add(event);
    await pumpEventQueue();
    return true;
  }

  @override
  Snapshot snapshot() {
    final state = _bloc.state;
    final label = state.activeInputLabel;
    var value = state.currentInputValue;
    if (state.resultValue case final result?) value = result;
    return Snapshot(
      label: label == null ? '' : '$label…',
      value: value,
      tape: [for (final chip in state.chipsList) '${chip.label}${chip.value}'],
      tapeKinds: [
        for (final chip in state.chipsList)
          chip.type == CoreCalculatorChipType.disabled ? 't-result' : 't-input',
      ],
      depKey: state.dependentKeyLabel == null
          ? null
          : '${state.dependentKeyLabel}: ${state.dependentKeyValue}',
      unitToggleLabel: state.currentUnitSystem == UnitSystem.metric
          ? 'Metric'
          : 'Imperial',
      system: state.currentUnitSystem == UnitSystem.metric
          ? 'metric'
          : 'imperial',
    );
  }

  static const _operators = {
    'op:×': '×',
    'op:÷': '÷',
    'op:+': '+',
    'op:−': '−',
  };

  CalculatorEvent? _eventFor(String key) {
    if (key.startsWith('d:')) return CalculatorDigitPressed(key.substring(2));
    if (key.startsWith('unit:')) {
      return CalculatorUnitSelected(key.substring(5));
    }
    if (key.startsWith('fk:')) return CalculatorKeySelected(key.substring(3));
    if (key.startsWith('mfk:')) return CalculatorKeySelected(key.substring(4));
    final operator = _operators[key];
    if (operator != null) return CalculatorOperatorPressed(operator);
    return switch (key) {
      'equals' => const CalculatorOperatorPressed('='),
      'backspace' => const CalculatorControlActioned(ControlAction.delete),
      'clear' => const CalculatorControlActioned(ControlAction.clearAll),
      _ => null,
    };
  }
}

void main() {
  late BlocScenarioDriver driver;
  late List<Scenario> scenarios;

  setUpAll(() {
    scenarios = loadScenarios(File('test/golden/scenarios.json'));
  });

  setUp(() {
    driver = BlocScenarioDriver();
  });

  tearDown(() async {
    await driver.bloc.close();
  });

  group('Golden replay against CalculatorBloc', () {
    test(
      'replays every scenario and prints the score for the CI job',
      () async {
        final results = <ScenarioResult>[];
        for (final scenario in scenarios) {
          results.add(await runScenario(scenario, driver));
        }
        final report = ReplayReport(results);
        print(report);
        expect(report.total, 134);
        expect(
          report.scoreLine,
          startsWith(
            '${ReplayReport.scorePrefix} ${report.passed}/134 scenarios pass',
          ),
        );
      },
    );

    test(
      'S01 against the stub engine produces a readable failure diff',
      () async {
        final s01 = scenarios.firstWhere((s) => s.id == 'S01');
        final result = await runScenario(s01, driver);
        expect(result.passed, isFalse);
        final diff = ReplayReport.describeFailure(result).join('\n');
        expect(
          diff,
          contains(
            'S01 Area happy path — FAILED at step 11 "top chip Area: 410.67ft²"',
          ),
        );
        expect(diff, contains("expected: strip[0] == 'Area: 410.67ft²'"));
        expect(diff, contains('actual:   '));
        expect(diff, contains('tape=[Length22 ft, Width18 ft8 in]'));
        expect(diff, contains("source:   r=>r.strip[0]==='Area: 410.67ft²'"));
      },
    );

    test('the driver refuses steps the bloc has no event for', () async {
      expect(await driver.perform(const AcceptStep('Area')), isFalse);
      expect(await driver.perform(const KeyStep('view-all')), isFalse);
      expect(await driver.perform(const KeyStep('clear-input')), isFalse);
    });

    test('the driver reads the bloc state back as a snapshot', () async {
      for (final key in const [
        'fk:Length',
        'd:2',
        'd:2',
        'unit:ft',
        'fk:Width',
        'd:8',
        'op:×',
        'equals',
        'backspace',
        'clear',
      ]) {
        expect(await driver.perform(KeyStep(key)), isTrue, reason: key);
      }
      final empty = driver.snapshot();
      expect(empty.tape, isEmpty);
      expect(empty.label, '');
      await driver.perform(const KeyStep('fk:Rise'));
      await driver.perform(const KeyStep('d:6'));
      await driver.perform(const KeyStep('fk:Run'));
      await driver.perform(const KeyStep('d:1'));
      await driver.perform(const KeyStep('d:2'));
      await driver.perform(const KeyStep('equals'));
      final pitch = driver.snapshot();
      expect(pitch.tape, ['Rise6', 'Run12', 'Pitch0.5']);
      expect(pitch.tapeKinds, ['t-input', 't-input', 't-result']);
      expect(pitch.value, '0.5');
      await driver.perform(const KeyStep('fk:Length'));
      await driver.perform(const KeyStep('d:6'));
      await driver.perform(const KeyStep('fk:Fence'));
      final fence = driver.snapshot();
      expect(fence.depKey, 'oc: 6ft');
      expect(fence.system, 'imperial');
      expect(fence.unitToggleLabel, 'Imperial');
      await driver.reset();
      expect(driver.snapshot().tape, isEmpty);
    });
  });
}

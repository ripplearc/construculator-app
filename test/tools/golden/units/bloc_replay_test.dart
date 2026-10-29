import 'dart:io';

import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/formatters/calculator_label_formatter.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../scripts/golden/intended.dart';
import '../../../../scripts/golden/replay.dart';
import '../../../../scripts/golden/scenario.dart';
import '../../../../scripts/golden/snapshot.dart';

/// Drives [CalculatorBloc] with the prototype's keys and reads its state back
/// as a [Snapshot], in the words the page would show in English.
///
/// The bloc maps what the engine answers today (S1b); the ladder's rungs,
/// the sheets and the tape's own taps are still to come, so a scenario
/// that needs them fails at that checkpoint — which is what this driver is
/// for: the readable diff of what the app shows against what the prototype
/// showed, and the score the CI job reports. A strip chip is accepted by the
/// prefix of its text, as the prototype's `{accept}` step names it; steps
/// the bloc has no event for (tapping a tape chip, the sheet) are refused,
/// and the runner reports the scenario as unsupported from there.
class BlocScenarioDriver implements ScenarioDriver {
  CalculatorBloc _bloc = CalculatorBloc();

  static final CalculatorLabelFormatter _labels = CalculatorLabelFormatter(
    AppLocalizationsEn(),
  );

  /// The bloc under test, for the test to close.
  CalculatorBloc get bloc => _bloc;

  @override
  Future<void> reset() async {
    await _bloc.close();
    _bloc = CalculatorBloc();
  }

  @override
  Future<bool> perform(ScenarioStep step) async {
    final event = switch (step) {
      KeyStep(:final key) => _eventFor(key),
      AcceptStep(:final prefix) => _acceptEventFor(prefix),
      _ => null,
    };
    if (event == null) return false;
    _bloc.add(event);
    await pumpEventQueue();
    return true;
  }

  /// The chip whose text starts with [prefix], row 1 first then row 2, as
  /// the prototype's `accept` step finds it.
  CalculatorEvent? _acceptEventFor(String prefix) {
    final state = _bloc.state;
    for (final suggestion in state.suggestions) {
      if (_rowOneText(suggestion).startsWith(prefix)) {
        return CalculatorSuggestionAccepted(suggestion);
      }
    }
    for (final suggestion in state.conversions) {
      if (suggestion.text.startsWith(prefix)) {
        return CalculatorSuggestionAccepted(suggestion);
      }
    }
    return null;
  }

  static String _rowOneText(CalculatorSuggestion suggestion) =>
      '${_labels.suggestionLabel(suggestion)}: ${suggestion.text}';

  @override
  Snapshot snapshot() {
    final state = _bloc.state;
    final label = state.displayLabel;
    return Snapshot(
      label: label.isEmpty
          ? ''
          : '${_labels.labelText(label)}${label.isTyping ? '…' : ''}',
      value: state.valueText,
      tape: [
        for (final chip in state.chipsList) '${chip.label ?? ''}${chip.value}',
      ],
      tapeKinds: [
        for (final chip in state.chipsList)
          switch (chip.type) {
            CoreCalculatorChipType.active => 't-active',
            CoreCalculatorChipType.result => 't-result',
            CoreCalculatorChipType.error => 't-error',
            _ => 't-input',
          },
      ],
      strip: [
        for (final suggestion in state.suggestions) _rowOneText(suggestion),
      ],
      strip2: state.conversions.isEmpty
          ? null
          : [for (final suggestion in state.conversions) suggestion.text],
      equalsLabel: switch (_labels.equalsLabel(state.equalsKeyId)) {
        CalculatorLabelFormatter.equalsSign => '',
        final label => label,
      },
      bracketOpen: state.tape.openBracket != null,
      unitToggleLabel: state.currentUnitSystem == UnitSystem.metric
          ? 'Metric'
          : 'Imperial',
      system: state.currentUnitSystem == UnitSystem.metric
          ? 'metric'
          : 'imperial',
    );
  }

  static const _operators = {
    'op:×': Operator.multiply,
    'op:÷': Operator.divide,
    'op:+': Operator.add,
    'op:−': Operator.subtract,
  };

  /// The unit column's keys by the suffix the scenarios name them with;
  /// the Unit group's keys (bf, lbs, kg, ton, mton) are function keys.
  static const _units = {
    'yd': Unit.yard,
    'ft': Unit.foot,
    'in': Unit.inch,
    'm': Unit.metre,
    'cm': Unit.centimetre,
    'mm': Unit.millimetre,
  };

  CalculatorEvent? _eventFor(String key) {
    if (key.startsWith('d:')) return CalculatorDigitPressed(key.substring(2));
    if (key.startsWith('unit:')) {
      final unit = _units[key.substring(5)];
      return unit == null ? null : CalculatorUnitSelected(unit);
    }
    if (key.startsWith('fk:')) return CalculatorKeySelected(key.substring(3));
    if (key.startsWith('mfk:')) return CalculatorKeySelected(key.substring(4));
    final operator = _operators[key];
    if (operator != null) return CalculatorOperatorPressed(operator);
    return switch (key) {
      'equals' => const CalculatorEqualsPressed(),
      'frac' => const CalculatorFractionPressed(),
      'paren' => const CalculatorControlActioned(ControlAction.paren),
      'backspace' => const CalculatorControlActioned(ControlAction.delete),
      'clear' => const CalculatorControlActioned(ControlAction.clearAll),
      'clear-input' => const CalculatorActiveValueCleared(),
      _ => null,
    };
  }
}

void main() {
  late BlocScenarioDriver driver;
  late List<Scenario> scenarios;
  late ScenarioSource source;
  late IntendedDifferences intended;

  setUpAll(() {
    scenarios = loadScenarios(File('test/golden/scenarios.json'));
    source = loadScenarioSource(File('test/golden/scenarios.json'));
    intended = loadIntendedDifferences(
      File('test/golden/intended_differences.json'),
    );
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
          results.add(await runScenario(scenario, driver, intended: intended));
        }
        final report = ReplayReport(results, source: source);
        print(report);
        expect(report.total, scenarios.length);
        expect(
          report.scoreLine,
          startsWith(
            '${ReplayReport.scorePrefix} ${report.passed}/${scenarios.length} '
            'scenarios pass',
          ),
        );
        expect(
          report.sourceLine,
          'Golden replay source: construculator-prototype.html @ '
          '${source.commit}',
        );
      },
    );

    test('every listed difference names a scenario and a checkpoint that '
        'exist, and a checkpoint entry carries a Dart answer the runner '
        'can evaluate', () {
      for (final entry in intended.entries) {
        final scenario = scenarios.firstWhere(
          (s) => s.id == entry.scenario,
          orElse: () => fail('${entry.scenario} is not in scenarios.json'),
        );
        if (entry.checkpoint case final description?) {
          expect(
            scenario.steps.whereType<CheckpointStep>().map(
              (c) => c.description,
            ),
            contains(description),
            reason: '${entry.scenario} has no checkpoint "$description"',
          );
          if (entry.dart case final dart?) {
            expect(
              dart.isPorted,
              isTrue,
              reason:
                  '${entry.scenario} "$description" has an unported '
                  'Dart answer',
            );
          } else {
            fail('${entry.scenario} "$description" has no Dart answer');
          }
        } else {
          expect(entry.dart, isNull);
        }
        expect(entry.reason, isNotEmpty);
      }
    });

    test('a scenario listed whole is reported as differing on purpose, not '
        'replayed', () async {
      final s04 = scenarios.firstWhere((s) => s.id == 'S04');
      final result = await runScenario(s04, driver, intended: intended);
      expect(result.differsOnPurpose, isTrue);
      expect(result.passed, isFalse);
      expect(result.checkpoints, isEmpty);
      expect(
        ReplayReport.describeFailure(result).first,
        'S04 Toggle Path B (pref-gated) — DIFFERS ON PURPOSE',
      );
    });

    test('S01 passes the engine\'s checkpoints, accepts Area from the strip, '
        'and fails at the first trade rung with a readable diff', () async {
      final s01 = scenarios.firstWhere((s) => s.id == 'S01');
      final result = await runScenario(s01, driver);
      expect(result.passed, isFalse);
      final diff = ReplayReport.describeFailure(result).join('\n');
      expect(
        diff,
        contains(
          'S01 Area happy path — FAILED at step 16 '
          '"material suggestion follows"',
        ),
      );
      expect(diff, contains("expected: strip[0] startsWith 'Drywall:'"));
      expect(diff, contains('actual:   '));
      expect(diff, contains('tape=[Length22ft, Width18ft 8in, Area410.67ft²]'));
      expect(diff, contains('strip=[Diagonal: 28.85ft, Perimeter: 81.33ft]'));
      expect(diff, contains("source:   r=>r.strip[0].startsWith('Drywall:')"));
    });

    test('the driver refuses steps the bloc has no event for, and an accept '
        'that names no chip on the strip', () async {
      expect(await driver.perform(const AcceptStep('Area')), isFalse);
      expect(await driver.perform(const KeyStep('view-all')), isFalse);
      expect(await driver.perform(const KeyStep('toggle-system')), isFalse);
      expect(await driver.perform(const TapChipStep('Length')), isFalse);
    });

    test('the driver accepts a strip chip by the prefix of its text, row 1 '
        'first, then a conversion by its value', () async {
      for (final key in const [
        'fk:Length',
        'd:2',
        'd:2',
        'unit:ft',
        'fk:Width',
        'd:1',
        'd:8',
        'unit:ft',
        'd:8',
        'unit:in',
      ]) {
        await driver.perform(KeyStep(key));
      }
      final offered = driver.snapshot();
      expect(offered.strip, [
        'Area: 410.67ft²',
        'Diagonal: 28.85ft',
        'Perimeter: 81.33ft',
      ]);
      expect(offered.strip2, ['224in', '5.69m']);
      expect(offered.equalsLabel, 'Area');

      expect(await driver.perform(const AcceptStep('Area')), isTrue);
      expect(driver.snapshot().tape.last, 'Area410.67ft²');

      expect(await driver.perform(const AcceptStep('45.63yd²')), isTrue);
      expect(driver.snapshot().tape.last, 'Area45.63yd²');
      expect(driver.snapshot().strip2, isNot(contains('45.63yd²')));
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
      for (final key in const ['fk:Rise', 'd:6', 'unit:ft', 'fk:Run', 'd:1']) {
        await driver.perform(KeyStep(key));
      }
      final typing = driver.snapshot();
      expect(typing.tape, ['Rise6ft', 'Run1']);
      expect(typing.tapeKinds, ['t-input', 't-active']);
      expect(typing.label, 'Run…');
      expect(typing.value, '1');
      for (final key in const ['d:2', 'unit:ft', 'op:×', 'd:2', 'equals']) {
        await driver.perform(KeyStep(key));
      }
      final chained = driver.snapshot();
      expect(chained.tape, ['Rise6ft', 'Run12ft', '×2', 'Calc24ft 0in']);
      expect(chained.tapeKinds, ['t-input', 't-input', 't-input', 't-result']);
      expect(chained.label, 'Calc');
      expect(chained.value, '24ft 0in');
      expect(chained.strip2, ['288in', '7.32m']);
      expect(chained.equalsLabel, '');
      await driver.perform(const KeyStep('paren'));
      expect(driver.snapshot().tape.last, '(');
      expect(driver.snapshot().bracketOpen, isTrue);
      expect(driver.snapshot().strip, isEmpty);
      expect(driver.snapshot().unitToggleLabel, 'Imperial');
    });

    test('the driver reads the label with its reading and a closed bracket '
        'by its inside', () async {
      for (final key in const ['fk:Pitch', 'd:8', 'd:.', 'd:4', 'd:5']) {
        await driver.perform(KeyStep(key));
      }
      final pitch = driver.snapshot();
      expect(pitch.label, 'Pitch · degrees…');
      expect(pitch.value, '8.45°');

      await driver.perform(const KeyStep('clear'));
      for (final key in const [
        'd:2',
        'op:+',
        'paren',
        'd:3',
        'op:×',
        'd:4',
        'paren',
      ]) {
        await driver.perform(KeyStep(key));
      }
      final bracket = driver.snapshot();
      expect(bracket.label, 'Addition · (3×4)');
      expect(bracket.value, '12');
    });
  });
}

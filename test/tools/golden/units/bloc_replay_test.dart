import 'dart:io';

import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/formatters/calculator_label_formatter.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:construculator/libraries/calculation/testing/fake_calculation_session_repository.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../scripts/golden/intended.dart';
import '../../../../scripts/golden/replay.dart';
import '../../../../scripts/golden/scenario.dart';
import '../../../../scripts/golden/snapshot.dart';
import '../../../features/calculator/helpers/calculator_bloc_factory.dart';

/// Drives [CalculatorBloc] with the prototype's keys and reads its state back
/// as a [Snapshot], in the words the page would show in English.
///
/// The bloc maps what the engine answers today (S1b) and the sheet counts
/// the store answers for an area (S2a), over a fake store seeded with
/// Appendix B's sizes; the ladder's other rungs, the sheets and the tape's
/// own taps are still to come, so a scenario that needs them fails at that
/// checkpoint — which is what this driver is for: the readable diff of
/// what the app shows against what the prototype showed, and the score the
/// CI job reports. A finished tape is banked to a fake history (U1), whose
/// session count the snapshot reads, and the "Saved to history" card is
/// read as the prototype's action toast, its Undo and View tapped by their
/// selectors. A strip chip is accepted by the prefix of its text, as
/// the prototype's `{accept}` step names it, and a tape chip is tapped by
/// the prefix of its text (S1c). The prototype's steps that only switch on
/// its own preferences or open its "View all" sheet change nothing here and
/// are performed as no-ops; its tap on the "Materials keys ready" hint, a
/// device the design does not have, selects the Materials group as the
/// "View all" sheet would; steps the bloc has no event for (the sheets,
/// history) are refused, and the runner reports the scenario as
/// unsupported from there.
class BlocScenarioDriver implements ScenarioDriver {
  FakeCalculationSessionRepository _history =
      FakeCalculationSessionRepository();
  late CalculatorBloc _bloc = calculatorBlocForTests(history: _history);

  static final CalculatorLabelFormatter _labels = CalculatorLabelFormatter(
    AppLocalizationsEn(),
  );

  /// The bloc under test, for the test to close.
  CalculatorBloc get bloc => _bloc;

  /// Closes the bloc, then the history it banked to on the way out.
  Future<void> dispose() async {
    await _bloc.close();
    _history.dispose();
  }

  @override
  Future<void> reset() async {
    await dispose();
    _history = FakeCalculationSessionRepository();
    _bloc = calculatorBlocForTests(history: _history);
  }

  // The prototype's preference for editing in place, which the design
  // has as its only way (rule 4.8), so switching it on changes nothing.
  static const String _editInPlacePreference = "editStyle='recompute'";

  // The prototype's "View all" key: the sheet is the page's, not the
  // bloc's, and the group a scenario then clicks is selected by its id.
  static const String _viewAllKey = 'view-all';

  // The prototype's hint under the strip that switches to the Materials
  // group (its risk audit #5); here the group is selected as from "View all".
  static const String _materialsHintKey = 'matswitch';

  @override
  Future<bool> perform(ScenarioStep step) async {
    if (step case JsStep(
      :final source,
    ) when source.contains(_editInPlacePreference)) {
      return true;
    }
    if (step case KeyStep(key: _viewAllKey)) return true;
    final event = switch (step) {
      KeyStep(key: _materialsHintKey) => CalculatorGroupSelected(
        _bloc.state.groupOrder.indexOf(CalculatorGroupId.materials),
      ),
      KeyStep(:final key) => _eventFor(key),
      AcceptStep(:final prefix) => _acceptEventFor(prefix),
      TapChipStep(:final prefix) => _tapEventFor(prefix),
      ClickStep(:final selector) => _clickEventFor(selector),
      _ => null,
    };
    if (event == null) return false;
    _bloc.add(event);
    await pumpEventQueue();
    return true;
  }

  // The tape chip whose text starts with [prefix], as the prototype's
  // `tapChip` step finds it: "Length", "18ft", "+(3×4)".
  CalculatorEvent? _tapEventFor(String prefix) {
    for (final (index, text) in snapshot().tape.indexed) {
      if (text.startsWith(prefix)) return CalculatorChipTapped(index);
    }
    return null;
  }

  // The group a `[data-selgroup="…"]` click selects in the "View all"
  // sheet, by its place in the order the bloc holds.
  CalculatorEvent? _clickEventFor(String selector) {
    if (selector == _undoSelector) return const CalculatorUndoPressed();
    if (selector == _viewSelector) return const CalculatorHistoryViewPressed();
    final match = _groupSelector.firstMatch(selector);
    final groupId = switch (match?.group(1)) {
      'basic' => CalculatorGroupId.basicGeometry,
      'shapes' => CalculatorGroupId.shapes,
      'materials' => CalculatorGroupId.materials,
      'unit' => CalculatorGroupId.unit,
      'trig' => CalculatorGroupId.trigonometry,
      _ => null,
    };
    if (groupId == null) return null;
    return CalculatorGroupSelected(_bloc.state.groupOrder.indexOf(groupId));
  }

  static final RegExp _groupSelector = RegExp(r'\[data-selgroup="(\w+)"\]');

  // The buttons of the prototype's action toast, which the design draws as
  // the "Saved to history" card (Section 1.7).
  static const String _undoSelector = '#act-toast .at-undo';
  static const String _viewSelector = '#act-toast .at-view';

  // The chip whose text starts with [prefix], row 1 first then row 2, as
  // the prototype's `accept` step finds it.
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
      '${_labels.suggestionLabel(suggestion)}: '
      '${_labels.suggestionText(suggestion)}';

  // A tape chip as the prototype's DOM reads it: its key, then its text.
  // An error chip is its title alone ("Dimension Error", S18 and S71).
  static String _chipText(CoreCalculatorChip chip, TapeChip tapeChip) =>
      switch (tapeChip) {
        ErrorChip(:final error) => _labels.displayLabel(error.name),
        _ =>
          '${chip.label ?? ''}'
              '${_bracketTextAsThePrototypeSpellsIt(chip, tapeChip)}',
      };

  static String _bracketTextAsThePrototypeSpellsIt(
    CoreCalculatorChip chip,
    TapeChip tapeChip,
  ) => switch (tapeChip) {
    // the chip draws its parentheses and its operator is the factor icon
    BracketChip(:final operator, :final isOpen) =>
      '${operator?.symbol ?? ''}(${chip.value}${isOpen ? '' : ')'}',
    // a count says what it counts, as the page writes it: 12.83 Sheets
    _ => '${_labels.localizeChips([chip]).single.value}',
  };

  // A pill as the prototype's DOM reads it: an offer is a sentence, a
  // toggle its label, a colon and its value.
  static String _pillText(CalculatorDependentKey key) {
    final pill = _labels.dependentKey(key, onPressed: () {});
    return switch (pill.kind) {
      CoreDependentKeyKind.offer => '${pill.label} ${pill.value}',
      CoreDependentKeyKind.editable ||
      CoreDependentKeyKind.toggle => '${pill.label}: ${pill.value}',
    };
  }

  @override
  Snapshot snapshot() {
    final state = _bloc.state;
    final label = state.displayLabel;
    return Snapshot(
      label: switch (label) {
        final label? =>
          '${_labels.labelText(label)}${label.isTyping ? '…' : ''}',
        null => '',
      },
      value: _labels.valueText(state),
      toast: switch (state.toast) {
        CalculatorEditingGroupToast() ||
        CalculatorSavedToHistoryToast() ||
        null => null,
        final toast => _labels.toastBody(toast),
      },
      actionToast: switch (state.toast) {
        final CalculatorEditingGroupToast toast => _labels.toastBody(toast),
        final CalculatorSavedToHistoryToast toast => [
          _labels.toastBody(toast),
          ?_labels.toastHighlight(toast),
        ].join(' · '),
        _ => null,
      },
      historyCount: _history.sessions.length,
      ladder: [
        for (final step in state.ladderTrace)
          '${step.rung.name}: ${step.applies ? 'yes' : 'no'}',
      ].join(', '),
      hint: switch (state.stripNote) {
        final note? => _labels.noteText(note),
        null =>
          state.suggestions.isEmpty && state.conversions.isEmpty
              ? _labels.l10n.calculatorStripPlaceholder
              : null,
      },
      depKey: state.dependentKeys.isEmpty
          ? null
          : [for (final key in state.dependentKeys) _pillText(key)].join(' | '),
      // The prototype writes the ellipsis on a chip with nothing typed in it
      // yet ("Width…", "+…"); a chip with digits reads as its text, typed
      // ("9", S62) or reopened in place (S65: "Width18ft 8in 78").
      tape: [
        for (final (index, chip) in state.chipsList.indexed)
          '${_chipText(chip, state.tape.chips[index])}'
              '${_hasNothingTyped(state.tape.chips[index]) ? '…' : ''}',
      ],
      tapeBracket: [
        for (final chip in state.tape.chips)
          chip is BracketChip && !chip.isOpen,
      ],
      tapeBracketOpen: [
        for (final chip in state.tape.chips) chip is BracketChip && chip.isOpen,
      ],
      tapeFrozen: [for (final chip in state.chipsList) chip.inert],
      tapeKinds: [
        for (final chip in state.chipsList)
          switch (chip.type) {
            CoreCalculatorChipType.active => 't-active',
            CoreCalculatorChipType.result ||
            CoreCalculatorChipType.dashed => 't-result',
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
          ? _labels.l10n.calculatorUnitSystemMetric
          : _labels.l10n.calculatorUnitSystemImperial,
      system: state.currentUnitSystem == UnitSystem.metric
          ? 'metric'
          : 'imperial',
      functionGroup: _labels.groupLabel(
        state.groupOrder[state.currentGroupIndex],
      ),
    );
  }

  static bool _hasNothingTyped(TapeChip chip) => switch (chip) {
    ValueChip(isActive: true, entry: EntryBuffer(isEmpty: true)) => true,
    _ => false,
  };

  static const _operators = {
    'op:×': Operator.multiply,
    'op:÷': Operator.divide,
    'op:+': Operator.add,
    'op:−': Operator.subtract,
  };

  // The Unit group's function keys, which a scenario names as `unit:lbs`
  // though the prototype presses them in the "View all" sheet.
  static const _unitGroupKeys = {'bf', 'lbs', 'kg', 'ton', 'mton'};

  // The unit column's keys by the suffix the scenarios name them with;
  // the Unit group's keys (bf, lbs, kg, ton, mton) are function keys.
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
      final id = key.substring(5);
      if (_unitGroupKeys.contains(id)) return CalculatorKeySelected(id);
      final unit = _units[id];
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
    await driver.dispose();
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

    test(
      'S01 passes the engine\'s checkpoints, accepts Area and the first '
      'sheet count from the strip, and differs from the prototype at the '
      'Sheet size pill by the stored size alone, with a readable diff',
      () async {
        final s01 = scenarios.firstWhere((s) => s.id == 'S01');
        final result = await runScenario(s01, driver);
        expect(result.passed, isFalse);
        final diff = ReplayReport.describeFailure(result).join('\n');
        expect(
          diff,
          contains(
            'S01 Area happy path — FAILED at step 19 '
            '"dependent key shows the sheet size"',
          ),
        );
        expect(
          diff,
          contains("expected: depKey == 'Sheet size: 47.24in x 94.49in'"),
        );
        expect(diff, contains('actual:   '));
        expect(
          diff,
          contains(
            'tape=[Length22ft, Width18ft 8in, Area410.67ft², '
            'Number of sheets12.83 Sheets]',
          ),
        );
        expect(
          diff,
          contains(
            'strip=[Drywall: 11.41 sheets (48in x 108in), '
            'Drywall: 10.27 sheets (48in x 120in)]',
          ),
        );
        expect(diff, contains("depKey='Sheet size: 48in x 96in'"));
        expect(
          diff,
          contains("source:   r=>r.depKey==='Sheet size: 47.24in x 94.49in'"),
        );
        expect(
          diff,
          contains('ladder=[error: no, tradeFollowOn: yes]'),
          reason: 'the diff says which rung chose the strip (G1, CA-1072)',
        );
      },
    );

    test('the driver reads the "Saved to history" card as the action toast, '
        'counts the sessions in history, and taps Undo and View by the '
        'prototype\'s selectors (S62)', () async {
      for (final key in const [
        'd:1',
        'd:2',
        'unit:ft',
        'op:×',
        'd:5',
        'unit:ft',
        'equals',
        'd:9',
      ]) {
        await driver.perform(KeyStep(key));
      }
      final banked = driver.snapshot();
      expect(banked.tape, ['9']);
      expect(banked.actionToast, 'Saved to history · Calc 60ft²');
      expect(banked.toast, isNull);
      expect(banked.historyCount, 1);

      expect(
        await driver.perform(const ClickStep('#act-toast .at-undo')),
        isTrue,
      );
      final undone = driver.snapshot();
      expect(undone.tape, ['12ft', '×5ft', 'Calc60ft²']);
      expect(undone.actionToast, isNull);
      expect(undone.historyCount, 0);

      await driver.perform(const KeyStep('op:×'));
      final carried = driver.snapshot();
      expect(carried.tape, ['Calc60ft²', '×…']);
      expect(
        carried.actionToast,
        'Saved to history · Calc 60ft² carried forward',
      );
      expect(
        await driver.perform(const ClickStep('#act-toast .at-view')),
        isTrue,
      );
      expect(driver.snapshot().actionToast, isNull);
      expect(driver.snapshot().historyCount, 1);
      expect(driver.bloc.state.historyStage, DisplayAreaStage.fullScreen);
    });

    test('an error chip reads as its title alone, and a key after it starts a '
        'clean tape with the error tape in history (S18, S71)', () async {
      for (final key in const [
        'd:7',
        'd:8',
        'unit:lbs',
        'op:÷',
        'd:1',
        'd:2',
        'unit:ft',
        'equals',
      ]) {
        await driver.perform(KeyStep(key));
      }
      expect(driver.snapshot().tape, ['78lbs', '÷12ft', 'Dimension Error']);
      expect(driver.snapshot().tapeKinds.last, 't-error');

      await driver.perform(const KeyStep('fk:Length'));
      final fresh = driver.snapshot();
      expect(fresh.tape, ['Length…']);
      expect(fresh.actionToast, 'Saved to history');
      expect(fresh.historyCount, 1);
    });

    test('a reset starts the next scenario on an empty history', () async {
      for (final key in const ['d:2', 'op:+', 'd:3', 'equals', 'd:9']) {
        await driver.perform(KeyStep(key));
      }
      expect(driver.snapshot().historyCount, 1);

      await driver.reset();

      expect(driver.snapshot().historyCount, 0);
      expect(driver.snapshot().tape, isEmpty);
    });

    test('the driver refuses steps the bloc has no event for, an accept '
        'that names no chip on the strip and a tap that names no chip on '
        'the tape', () async {
      expect(await driver.perform(const AcceptStep('Area')), isFalse);
      expect(await driver.perform(const KeyStep('toggle-system')), isFalse);
      expect(await driver.perform(const TapChipStep('Length')), isFalse);
      expect(await driver.perform(const ClickStep('#set-update')), isFalse);
      expect(
        await driver.perform(const JsStep('()=>{ state.histStage = 2; }')),
        isFalse,
      );
    });

    test('the prototype\'s edit-in-place preference and its View all key '
        'change nothing and are performed as no-ops', () async {
      expect(
        await driver.perform(
          const JsStep(
            "()=>{ state.prefs.editStyle='recompute'; persist('proto_prefs_v1', state.prefs); render(); }",
          ),
        ),
        isTrue,
      );
      expect(await driver.perform(const KeyStep('view-all')), isTrue);
      expect(driver.snapshot().tape, isEmpty);
    });

    test('a group clicked in View all is selected by its id, and a Unit '
        'group key named unit:lbs presses that function key', () async {
      expect(
        await driver.perform(const ClickStep('[data-selgroup="unit"]')),
        isTrue,
      );
      expect(driver.bloc.state.currentGroupIndex, 3);

      await driver.perform(const KeyStep('d:5'));
      expect(await driver.perform(const KeyStep('unit:lbs')), isTrue);
      expect(driver.snapshot().tape, ['5lbs']);
    });

    test('a guard the tape raises on an edit reads as the toast, in the words '
        'of Section 5, and goes with the next key', () async {
      for (final key in const ['fk:Length', 'd:1', 'd:8']) {
        await driver.perform(KeyStep(key));
      }
      await driver.perform(const KeyStep('fk:Width'));
      expect(driver.snapshot().toast, contains("18 isn't complete"));

      await driver.perform(const KeyStep('unit:ft'));
      expect(driver.snapshot().toast, isNull);
    });

    test(
      'a closed bracket tapped by its text reopens with the "Editing this '
      'group" message read as the action toast, the other chips waiting and '
      'the answer reading a dash; the message stops after three (S126, S130)',
      () async {
        for (final key in const [
          'd:2',
          'op:+',
          'paren',
          'd:3',
          'op:×',
          'd:4',
          'paren',
          'op:×',
          'd:5',
          'equals',
        ]) {
          await driver.perform(KeyStep(key));
        }
        expect(driver.snapshot().tape, ['2', '+(3×4)', '×5', 'Calc70']);

        for (var reopened = 1; reopened <= 4; reopened++) {
          expect(await driver.perform(const TapChipStep('+(3×4')), isTrue);
          final open = driver.snapshot();
          expect(open.tape, ['2', '+(3×4', '×5', 'Calc—'], reason: '$reopened');
          expect(open.tapeFrozen, [true, false, true, true]);
          expect(open.toast, isNull);
          expect(
            open.actionToast,
            reopened <= 3 ? contains('Editing this group') : isNull,
            reason: 'reopening $reopened',
          );
          await driver.perform(const KeyStep('paren'));
        }
        expect(driver.snapshot().tape, ['2', '+(3×4)', '×5', 'Calc70']);
      },
    );

    test('a tape chip is tapped by the prefix of its text: the chip reopens, '
        'the results after it read as results while dashed, and a second '
        'tap seals it (S66)', () async {
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
      await driver.perform(const AcceptStep('Area'));

      expect(await driver.perform(const TapChipStep('Width')), isTrue);
      final open = driver.snapshot();
      expect(open.tape, ['Length22ft', 'Width18ft 8in', 'Area410.67ft²']);
      expect(open.tapeKinds, ['t-input', 't-active', 't-result']);
      expect(
        driver.bloc.state.chipsList.last.type,
        CoreCalculatorChipType.dashed,
      );

      expect(await driver.perform(const TapChipStep('Width')), isTrue);
      expect(driver.snapshot().tapeKinds, ['t-input', 't-input', 't-result']);
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

    test('the driver reads the ladder\'s trace into the snapshot: silent '
        'after an error, the rules for two named sides, nothing on an '
        'empty tape', () async {
      expect(
        driver.snapshot().ladder,
        'error: no, tradeFollowOn: no, rules: no',
      );

      for (final key in const [
        'fk:Length',
        'd:2',
        'unit:ft',
        'fk:Width',
        'd:3',
        'unit:ft',
      ]) {
        await driver.perform(KeyStep(key));
      }
      expect(
        driver.snapshot().ladder,
        'error: no, tradeFollowOn: no, rules: yes',
      );

      await driver.perform(const KeyStep('clear'));
      for (final key in const ['d:5', 'op:÷', 'd:0', 'equals']) {
        await driver.perform(KeyStep(key));
      }
      expect(driver.snapshot().ladder, 'error: yes');
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
      expect(typing.depKey, isNull);
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

    test('the driver reads the label with its reading, the pills as the '
        'prototype spells them, and a closed bracket by its inside', () async {
      for (final key in const ['fk:Pitch', 'd:8', 'd:.', 'd:4', 'd:5']) {
        await driver.perform(KeyStep(key));
      }
      final pitch = driver.snapshot();
      expect(pitch.label, 'Pitch · degrees…');
      expect(pitch.value, '8.45°');
      expect(pitch.depKey, 'Input 8.45° as 8.45in/12in');

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
      expect(bracket.tapeBracket, [false, true]);
      expect(bracket.tapeBracketOpen, [false, false]);
      expect(bracket.hint, isNull);
    });

    test('the driver reads the strip note as the hint, the placeholder when '
        'nothing applies, and the typing ellipsis on an active chip', () async {
      expect(
        driver.snapshot().hint,
        BlocScenarioDriver._labels.l10n.calculatorStripPlaceholder,
      );
      for (final key in const ['fk:Pitch', 'd:8', 'd:9', 'd:9']) {
        await driver.perform(KeyStep(key));
      }
      final out = driver.snapshot();
      expect(out.strip, isEmpty);
      expect(
        out.hint,
        BlocScenarioDriver._labels.noteText(
          const CalculatorPitchOutOfRangeNote(isAtLeastARightAngle: true),
        ),
      );

      await driver.perform(const KeyStep('clear'));
      for (final key in const ['d:2', 'op:+', 'paren', 'd:3']) {
        await driver.perform(KeyStep(key));
      }
      final open = driver.snapshot();
      expect(open.tape, ['2', '+(3']);
      expect(open.tapeFrozen, [true, false]);
      expect(open.tapeBracketOpen, [false, true]);

      await driver.perform(const KeyStep('clear'));
      await driver.perform(const KeyStep('fk:Width'));
      expect(driver.snapshot().tape, ['Width…']);
    });
  });
}

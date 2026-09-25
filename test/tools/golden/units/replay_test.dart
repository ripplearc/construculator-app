import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/golden/check.dart';
import '../../../../scripts/golden/replay.dart';
import '../../../../scripts/golden/scenario.dart';
import '../../../../scripts/golden/snapshot.dart';

/// A driver whose screen is whatever the test scripts: each key press moves
/// to the next snapshot in the list, and keys not in [supported] are refused.
class _ScriptedDriver implements ScenarioDriver {
  /// The snapshots shown after the first, second, … key press.
  final List<Snapshot> screens;

  /// The keys the driver can press.
  static const supported = {'d:1', 'd:2', 'fk:Length'};

  /// Every key pressed, in order, across resets.
  final List<String> pressed = [];

  /// How many times the driver was reset.
  int resets = 0;

  var _index = -1;

  _ScriptedDriver(this.screens);

  @override
  Future<void> reset() async {
    resets += 1;
    _index = -1;
  }

  @override
  Future<bool> perform(ScenarioStep step) async {
    if (step is! KeyStep || !supported.contains(step.key)) return false;
    pressed.add(step.key);
    _index += 1;
    return true;
  }

  @override
  Snapshot snapshot() => _index < 0 ? const Snapshot() : screens[_index];
}

void main() {
  const value1 = CheckpointStep(
    'value 1',
    Check(CheckKind.value, text: '1'),
    source: "r=>r.value==='1'",
  );
  const value12 = CheckpointStep(
    'value 12',
    Check(CheckKind.value, text: '12'),
    source: "r=>r.value==='12'",
  );
  const dom = CheckpointStep(
    'dom',
    Check(CheckKind.js, source: '()=>document'),
    source: '()=>document',
  );
  const one = Snapshot(value: '1', tape: ['1']);
  const twelve = Snapshot(value: '12', tape: ['12']);

  Scenario scenario(List<ScenarioStep> steps, {String id = 'S01'}) =>
      Scenario(id: id, category: 'test', name: 'a scenario', steps: steps);

  group('runScenario', () {
    test(
      'resets, performs each step and passes when every checkpoint holds',
      () async {
        final driver = _ScriptedDriver(const [one, twelve]);
        final result = await runScenario(
          scenario(const [KeyStep('d:1'), value1, KeyStep('d:2'), value12]),
          driver,
        );
        expect(driver.resets, 1);
        expect(driver.pressed, ['d:1', 'd:2']);
        expect(result.passed, isTrue);
        expect(result.checkpoints.map((c) => c.outcome), [
          CheckpointOutcome.passed,
          CheckpointOutcome.passed,
        ]);
        expect(result.checkpoints.first.snapshot, one);
        expect(result.firstFailure, isNull);
      },
    );

    test('stops at the first failure and keeps the snapshot it saw', () async {
      final driver = _ScriptedDriver(const [twelve, twelve]);
      final result = await runScenario(
        scenario(const [KeyStep('d:1'), value1, KeyStep('d:2'), value12]),
        driver,
      );
      expect(result.passed, isFalse);
      expect(driver.pressed, ['d:1']);
      expect(result.firstFailure!.stepIndex, 1);
      expect(result.firstFailure!.snapshot, twelve);
      expect(result.checkpoints.last.outcome, CheckpointOutcome.notReached);
    });

    test(
      'an unsupported step ends the scenario with the checkpoints after it not reached',
      () async {
        final driver = _ScriptedDriver(const [one]);
        final result = await runScenario(
          scenario(const [KeyStep('d:1'), value1, AcceptStep('Area'), value12]),
          driver,
        );
        expect(result.passed, isFalse);
        expect(result.unsupportedStepIndex, 2);
        expect(result.checkpoints.map((c) => c.outcome), [
          CheckpointOutcome.passed,
          CheckpointOutcome.notReached,
        ]);
        expect(result.firstFailure, isNull);
      },
    );

    test(
      'an unported checkpoint is skipped, counted, and does not fail the scenario',
      () async {
        final driver = _ScriptedDriver(const [one]);
        final result = await runScenario(
          scenario(const [KeyStep('d:1'), dom, value1]),
          driver,
        );
        expect(result.passed, isTrue);
        expect(result.unported, 1);
        expect(result.checkpoints.first.outcome, CheckpointOutcome.unported);
      },
    );

    test('passes the base history count through to the checks', () async {
      const saved = CheckpointStep(
        'saved',
        Check(CheckKind.historyCountAfterSaves, number: 1),
        source: 'r=>r.histCount===histAfterSaves(1)',
      );
      final driver = _ScriptedDriver(const [Snapshot(historyCount: 4)]);
      final result = await runScenario(
        scenario(const [KeyStep('d:1'), saved]),
        driver,
        baseHistory: 3,
      );
      expect(result.passed, isTrue);
    });
  });

  group('ReplayReport', () {
    test('scores the scenarios and describes each failure readably', () async {
      final passing = await runScenario(
        scenario(const [KeyStep('d:1'), value1]),
        _ScriptedDriver(const [one]),
      );
      final failing = await runScenario(
        scenario(const [KeyStep('d:1'), value12], id: 'S02'),
        _ScriptedDriver(const [one]),
      );
      final unsupported = await runScenario(
        scenario(const [AcceptStep('Area'), value1, dom], id: 'S03'),
        _ScriptedDriver(const [one]),
      );
      final report = ReplayReport([passing, failing, unsupported]);
      expect(report.passed, 1);
      expect(report.total, 3);
      expect(
        report.scoreLine,
        'Golden replay: 1/3 scenarios pass (1 failed a checkpoint, 1 hit an unsupported step, 0 checkpoints unported)',
      );
      final text = report.toString();
      expect(text, startsWith(ReplayReport.scorePrefix));
      expect(text, contains('S02 a scenario — FAILED at step 2 "value 12"'));
      expect(text, contains("expected: value == '12'"));
      expect(text, contains("actual:   label='' value='1' tape=[1] strip=[]"));
      expect(text, contains("source:   r=>r.value==='12'"));
      expect(
        text,
        contains('S03 a scenario — UNSUPPORTED step 1: AcceptStep(Area)'),
      );
      expect(text, isNot(contains('S01')));
    });

    test('describes a passed scenario as passed', () async {
      final passing = await runScenario(
        scenario(const [KeyStep('d:1'), value1]),
        _ScriptedDriver(const [one]),
      );
      expect(ReplayReport.describeFailure(passing), [
        'S01 a scenario — passed',
      ]);
    });
  });

  group('describeCheck', () {
    test('spells every kind in the words of the snapshot', () {
      final described = [
        for (final kind in CheckKind.values)
          describeCheck(
            Check(
              kind,
              index: 0,
              text: 'x',
              otherText: 'y',
              list: const ['a'],
              number: 2,
              flag: true,
              separator: ' ',
              checks: const [
                Check(CheckKind.value, text: 'v'),
                Check(CheckKind.label, text: 'l'),
              ],
              inner: const Check(CheckKind.value, text: 'v'),
              source: 'src',
            ),
          ),
      ];
      expect(described, hasLength(CheckKind.values.length));
      expect(described.toSet(), hasLength(CheckKind.values.length));
      expect(
        describeCheck(
          const Check(CheckKind.stripAt, index: 0, text: 'Area: 1'),
        ),
        "strip[0] == 'Area: 1'",
      );
      expect(
        describeCheck(
          const Check(
            CheckKind.all,
            checks: [
              Check(CheckKind.value, text: 'a'),
              Check(CheckKind.toastShown, flag: false),
            ],
          ),
        ),
        "(value == 'a' && toast shown == false)",
      );
      expect(describeCheck(const Check(CheckKind.not)), '!()');
      expect(describeCheck(const Check(CheckKind.js, source: 'js')), 'js: js');
    });
  });

  test('describeSnapshot names the surfaces a failure is about', () {
    expect(
      describeSnapshot(
        const Snapshot(
          label: 'L',
          value: 'V',
          depKey: 'D',
          toast: 'T',
          equalsLabel: 'Area',
          bracketOpen: true,
        ),
      ),
      "label='L' value='V' tape=[] strip=[] strip2=null depKey='D' toast='T' equalsLabel='Area' bracketOpen=true",
    );
    expect(
      describeSnapshot(const Snapshot()),
      contains('depKey=null toast=null'),
    );
  });
}

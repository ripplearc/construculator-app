import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/golden/check.dart';
import '../../../../scripts/golden/intended.dart';
import '../../../../scripts/golden/replay.dart';
import '../../../../scripts/golden/scenario.dart';
import '../../../../scripts/golden/snapshot.dart';

class _ScriptedDriver implements ScenarioDriver {
  final List<Snapshot> screens;

  static const supported = {'d:1', 'd:2', 'fk:Length'};

  final List<String> pressed = [];

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
  const seven = Snapshot(value: '7', tape: ['7']);

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
        expect(result.unchecked, isFalse);
        expect(result.unported, 1);
        expect(result.checkpoints.first.outcome, CheckpointOutcome.unported);
      },
    );

    test('a scenario whose checkpoints are all unported is unchecked, not '
        'passed', () async {
      final driver = _ScriptedDriver(const [one]);
      final result = await runScenario(
        scenario(const [KeyStep('d:1'), dom]),
        driver,
      );
      expect(result.passed, isFalse);
      expect(result.unchecked, isTrue);
      expect(result.firstFailure, isNull);
      expect(result.unsupportedStepIndex, isNull);
      final report = ReplayReport([result]);
      expect(report.passed, 0);
      expect(report.unchecked, 1);
      expect(
        report.scoreLine,
        contains('1 checked nothing, 1 checkpoint unported'),
      );
      expect(
        report.toString(),
        contains(
          'S01 a scenario — UNCHECKED: 1 checkpoint unported, none evaluated',
        ),
      );
    });

    test(
      'unported checkpoints are counted from the file, reached or not',
      () async {
        final driver = _ScriptedDriver(const [twelve]);
        final result = await runScenario(
          scenario(const [KeyStep('d:1'), value1, dom, KeyStep('d:2'), dom]),
          driver,
        );
        expect(result.passed, isFalse);
        expect(result.checkpoints.map((c) => c.outcome), [
          CheckpointOutcome.failed,
          CheckpointOutcome.notReached,
          CheckpointOutcome.notReached,
        ]);
        expect(result.unported, 2);
        expect(
          ReplayReport([result]).scoreLine,
          contains('2 checkpoints unported'),
        );
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
        'Golden replay: 1/3 scenarios pass (1 failed a checkpoint, 1 hit an unsupported step, 0 checked nothing, 1 checkpoint unported, 0 differ on purpose, 0 checkpoints differ on purpose)',
      );
      final text = report.toString();
      expect(text, startsWith(ReplayReport.scorePrefix));
      expect(text, isNot(contains('Golden replay source:')));
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

    test('names the prototype file and commit under the score', () {
      const source = ScenarioSource(file: 'proto.html', commit: 'abc123');
      final report = ReplayReport(const [], source: source);
      expect(report.sourceLine, 'Golden replay source: proto.html @ abc123');
      expect(report.toString().split('\n')[1], report.sourceLine);
      expect(
        ReplayReport(
          const [],
          source: const ScenarioSource(file: 'p.html'),
        ).sourceLine,
        'Golden replay source: p.html @ an unknown commit',
      );
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

  group('intended differences', () {
    const listed = IntendedDifference(
      scenario: 'S01',
      checkpoint: 'value 1',
      reason: 'the design says 12 here',
      dart: Check(CheckKind.value, text: '12'),
    );
    const whole = IntendedDifference(
      scenario: 'S04',
      reason: 'a prototype-only preference',
    );
    const intended = IntendedDifferences([listed, whole]);

    test('a listed checkpoint that fails while the Dart answer holds is '
        'intended and does not stop the replay', () async {
      final driver = _ScriptedDriver(const [twelve, twelve]);
      final result = await runScenario(
        scenario(const [KeyStep('d:1'), value1, KeyStep('d:2'), value12]),
        driver,
        intended: intended,
      );
      expect(driver.pressed, ['d:1', 'd:2']);
      expect(result.passed, isTrue);
      expect(result.checkpoints.map((c) => c.outcome), [
        CheckpointOutcome.intended,
        CheckpointOutcome.passed,
      ]);
      expect(result.intendedCheckpoints.single.difference, listed);
      expect(result.firstFailure, isNull);
      final report = ReplayReport([result]);
      expect(report.passed, 1);
      expect(report.intendedCheckpoints, 1);
      expect(report.scoreLine, contains('1 checkpoint differs on purpose'));
      expect(
        report.toString(),
        contains(
          'S01 a scenario — DIFFERS ON PURPOSE at step 2 "value 1"\n'
          '  reason:   the design says 12 here',
        ),
      );
    });

    test('a listed checkpoint whose Dart answer does not hold either is a '
        'failure that stops the replay', () async {
      final driver = _ScriptedDriver(const [seven, twelve]);
      final result = await runScenario(
        scenario(const [KeyStep('d:1'), value1, KeyStep('d:2'), value12]),
        driver,
        intended: intended,
      );
      expect(driver.pressed, ['d:1']);
      expect(result.passed, isFalse);
      expect(result.checkpoints.map((c) => c.outcome), [
        CheckpointOutcome.failed,
        CheckpointOutcome.notReached,
      ]);
      expect(result.firstFailure!.snapshot, seven);
      expect(result.intendedCheckpoints, isEmpty);
    });

    test('a listed checkpoint whose prototype check is unported is judged '
        'by the Dart answer alone', () async {
      const listedDom = IntendedDifference(
        scenario: 'S01',
        checkpoint: 'dom',
        reason: 'the design has no dashes',
        dart: Check(CheckKind.value, text: '1'),
      );
      const list = IntendedDifferences([listedDom]);
      final holds = await runScenario(
        scenario(const [KeyStep('d:1'), dom]),
        _ScriptedDriver(const [one]),
        intended: list,
      );
      expect(holds.passed, isTrue);
      expect(holds.checkpoints.single.outcome, CheckpointOutcome.intended);
      expect(holds.unported, 1);
      final fails = await runScenario(
        scenario(const [KeyStep('d:1'), dom]),
        _ScriptedDriver(const [twelve]),
        intended: list,
      );
      expect(fails.passed, isFalse);
      expect(fails.checkpoints.single.outcome, CheckpointOutcome.failed);
    });

    test(
      'a listed checkpoint that holds is stale, and the report says so',
      () async {
        final driver = _ScriptedDriver(const [one, twelve]);
        final result = await runScenario(
          scenario(const [KeyStep('d:1'), value1, KeyStep('d:2'), value12]),
          driver,
          intended: intended,
        );
        expect(result.passed, isTrue);
        expect(result.checkpoints.first.outcome, CheckpointOutcome.stale);
        expect(result.staleCheckpoints.single.difference, listed);
        final report = ReplayReport([result]);
        expect(report.stale.single.$2.checkpoint.description, 'value 1');
        expect(
          report.toString().split('\n')[1],
          '${ReplayReport.stalePrefix} S01 "value 1" holds; '
          'remove it from the list',
        );
      },
    );

    test(
      'a scenario listed whole is not replayed and differs on purpose',
      () async {
        final driver = _ScriptedDriver(const [one]);
        final result = await runScenario(
          scenario(const [KeyStep('d:1'), value1], id: 'S04'),
          driver,
          intended: intended,
        );
        expect(driver.resets, 0);
        expect(driver.pressed, isEmpty);
        expect(result.differsOnPurpose, isTrue);
        expect(result.passed, isFalse);
        expect(result.checkpoints, isEmpty);
        final report = ReplayReport([result]);
        expect(report.differing, 1);
        expect(report.passed, 0);
        expect(report.scoreLine, contains('1 differ on purpose'));
        expect(ReplayReport.describeFailure(result), [
          'S04 a scenario — DIFFERS ON PURPOSE',
          '  reason:   a prototype-only preference',
        ]);
      },
    );

    test('an unlisted scenario replays as before', () async {
      final driver = _ScriptedDriver(const [one, twelve]);
      final result = await runScenario(
        scenario(const [KeyStep('d:1'), value1], id: 'S02'),
        driver,
        intended: intended,
      );
      expect(result.passed, isTrue);
      expect(result.checkpoints.single.outcome, CheckpointOutcome.passed);
    });

    test('fromJson reads an entry, and the lookups find it', () {
      final entry = IntendedDifference.fromJson(const {
        'scenario': 'S87',
        'checkpoint': 'a length into [Slope] is refused',
        'reason': 'the function key comes first',
        'dart': {'kind': 'toastIncludes', 'text': '[Pitch] 7 [Inch]'},
      });
      expect(entry.wholeScenario, isFalse);
      expect(
        entry.dart,
        const Check(CheckKind.toastIncludes, text: '[Pitch] 7 [Inch]'),
      );
      expect(
        IntendedDifference.fromJson(const {
          'scenario': 'S04',
          'reason': 'a prototype-only preference',
        }).dart,
        isNull,
      );
      final list = IntendedDifferences([entry, whole]);
      expect(
        list.forCheckpoint('S87', 'a length into [Slope] is refused'),
        entry,
      );
      expect(list.forCheckpoint('S87', 'another check'), isNull);
      expect(list.forScenario('S87'), isNull);
      expect(list.forScenario('S04'), whole);
      expect(IntendedDifferences.none.forScenario('S04'), isNull);
    });

    test('a checkpoint entry without its Dart answer is refused', () {
      expect(
        () => IntendedDifference.fromJson(const {
          'scenario': 'S87',
          'checkpoint': 'a length into [Slope] is refused',
          'reason': 'the function key comes first',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('needs the decided Dart answer'),
          ),
        ),
      );
    });
  });
}

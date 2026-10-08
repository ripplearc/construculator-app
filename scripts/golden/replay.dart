import 'package:equatable/equatable.dart';

import 'check.dart';
import 'intended.dart';
import 'scenario.dart';
import 'snapshot.dart';

/// What the runner drives: something that takes the prototype's steps and
/// can be asked what the screen shows. The bloc driver in the tests is one;
/// a scripted driver is another.
abstract class ScenarioDriver {
  /// Puts the calculator back to an empty tape, as `REPLAY.reset` does.
  Future<void> reset();

  /// Performs a step; `false` when the driver has no way to perform it, so
  /// the runner can report the scenario as unsupported from that step on
  /// rather than checking a screen the step never reached.
  Future<bool> perform(ScenarioStep step);

  /// What the screen shows now.
  Snapshot snapshot();
}

/// How one checkpoint fared.
enum CheckpointOutcome {
  /// The check held.
  passed,

  /// The check did not hold; the result carries the snapshot it saw.
  failed,

  /// The check is a closure the export could not classify; it was not run.
  unported,

  /// A step before it could not be performed, so it was not reached.
  notReached,

  /// The check did not hold, and `intended_differences.json` says the Dart
  /// answer differs here on purpose; the result carries the reason.
  intended,

  /// The check held although it is listed as an intended difference: the
  /// list is stale and the entry should go.
  stale,
}

/// One checkpoint's result within a scenario.
class CheckpointResult extends Equatable {
  /// The step's index in the scenario, zero-based.
  final int stepIndex;

  /// The checkpoint.
  final CheckpointStep checkpoint;

  /// How it fared.
  final CheckpointOutcome outcome;

  /// The snapshot the check was evaluated against, when it was.
  final Snapshot? snapshot;

  /// The listed difference, for an [CheckpointOutcome.intended] or
  /// [CheckpointOutcome.stale] outcome.
  final IntendedDifference? difference;

  const CheckpointResult({
    required this.stepIndex,
    required this.checkpoint,
    required this.outcome,
    this.snapshot,
    this.difference,
  });

  @override
  List<Object?> get props => [
    stepIndex,
    checkpoint,
    outcome,
    snapshot,
    difference,
  ];
}

/// One scenario's result.
class ScenarioResult extends Equatable {
  /// The scenario.
  final Scenario scenario;

  /// Every checkpoint, in order.
  final List<CheckpointResult> checkpoints;

  /// The index of the first step the driver could not perform, or `null`.
  final int? unsupportedStepIndex;

  /// The listed difference when the whole scenario differs on purpose; it
  /// was then not replayed at all.
  final IntendedDifference? difference;

  const ScenarioResult({
    required this.scenario,
    required this.checkpoints,
    this.unsupportedStepIndex,
    this.difference,
  });

  /// The scenario passes when every step was performed and no evaluated
  /// checkpoint failed. Unported checkpoints do not fail it — they are
  /// reported, since a pass that skipped them is a smaller claim. Neither
  /// do intended differences: those are the decided answers.
  bool get passed =>
      difference == null &&
      unsupportedStepIndex == null &&
      checkpoints.every((c) => c.outcome != CheckpointOutcome.failed);

  /// Whether the whole scenario is a listed difference.
  bool get differsOnPurpose => difference != null;

  /// The checkpoints that differ on purpose.
  List<CheckpointResult> get intendedCheckpoints => [
    for (final c in checkpoints)
      if (c.outcome == CheckpointOutcome.intended) c,
  ];

  /// The listed checkpoints that held anyway.
  List<CheckpointResult> get staleCheckpoints => [
    for (final c in checkpoints)
      if (c.outcome == CheckpointOutcome.stale) c,
  ];

  /// The first failed checkpoint, or `null`.
  CheckpointResult? get firstFailure {
    for (final result in checkpoints) {
      if (result.outcome == CheckpointOutcome.failed) return result;
    }
    return null;
  }

  /// How many checkpoints were unported.
  int get unported =>
      checkpoints.where((c) => c.outcome == CheckpointOutcome.unported).length;

  @override
  List<Object?> get props => [
    scenario,
    checkpoints,
    unsupportedStepIndex,
    difference,
  ];
}

/// Replays one scenario: performs each step, evaluates each checkpoint
/// against the driver's snapshot, and stops at the first failure or at the
/// first step the driver cannot perform — everything after either is a
/// screen the prototype never showed.
///
/// A checkpoint listed in [intended] does not stop the replay when it fails:
/// the Dart answer is the decided one, and the result says why. A scenario
/// listed whole is not replayed.
Future<ScenarioResult> runScenario(
  Scenario scenario,
  ScenarioDriver driver, {
  int baseHistory = 0,
  IntendedDifferences intended = IntendedDifferences.none,
}) async {
  final whole = intended.forScenario(scenario.id);
  if (whole != null) {
    return ScenarioResult(
      scenario: scenario,
      checkpoints: const [],
      difference: whole,
    );
  }
  await driver.reset();
  final results = <CheckpointResult>[];
  int? unsupported;
  var stopped = false;
  for (final (index, step) in scenario.steps.indexed) {
    if (step is! CheckpointStep) {
      if (stopped) continue;
      if (!await driver.perform(step)) {
        unsupported = index;
        stopped = true;
      }
      continue;
    }
    if (stopped) {
      results.add(
        CheckpointResult(
          stepIndex: index,
          checkpoint: step,
          outcome: CheckpointOutcome.notReached,
        ),
      );
      continue;
    }
    if (!step.check.isPorted) {
      results.add(
        CheckpointResult(
          stepIndex: index,
          checkpoint: step,
          outcome: CheckpointOutcome.unported,
        ),
      );
      continue;
    }
    final snapshot = driver.snapshot();
    final passed = step.check.holds(snapshot, baseHistory: baseHistory);
    final listed = intended.forCheckpoint(scenario.id, step.description);
    final outcome = switch ((passed, listed)) {
      (true, null) => CheckpointOutcome.passed,
      (false, null) => CheckpointOutcome.failed,
      (true, _) => CheckpointOutcome.stale,
      (false, _) => CheckpointOutcome.intended,
    };
    results.add(
      CheckpointResult(
        stepIndex: index,
        checkpoint: step,
        outcome: outcome,
        snapshot: snapshot,
        difference: listed,
      ),
    );
    if (outcome == CheckpointOutcome.failed) stopped = true;
  }
  return ScenarioResult(
    scenario: scenario,
    checkpoints: results,
    unsupportedStepIndex: unsupported,
  );
}

/// The results of a whole replay, with the one-line score the CI job reads
/// and a readable diff for every scenario that did not pass.
class ReplayReport {
  /// The prefix of the score line, which `scripts/ci/run_golden_replay.sh`
  /// looks for.
  static const String scorePrefix = 'Golden replay:';

  /// Every scenario's result, in the file's order.
  final List<ScenarioResult> results;

  const ReplayReport(this.results);

  /// How many scenarios passed.
  int get passed => results.where((r) => r.passed).length;

  /// How many scenarios there are.
  int get total => results.length;

  /// How many scenarios differ on purpose, as whole scenarios.
  int get differing => results.where((r) => r.differsOnPurpose).length;

  /// How many checkpoints differ on purpose.
  int get intendedCheckpoints =>
      results.fold(0, (sum, r) => sum + r.intendedCheckpoints.length);

  /// The listed checkpoints that held: entries the list no longer needs.
  List<(ScenarioResult, CheckpointResult)> get stale => [
    for (final r in results)
      for (final c in r.staleCheckpoints) (r, c),
  ];

  /// The score line: "Golden replay: 12/134 scenarios pass (…)". The gate
  /// in `run_golden_replay.sh` passes when pass + differ on purpose = total.
  String get scoreLine {
    final failed = results.where((r) => r.firstFailure != null).length;
    final unsupported = results
        .where((r) => r.unsupportedStepIndex != null)
        .length;
    final unported = results.fold(0, (sum, r) => sum + r.unported);
    return '$scorePrefix $passed/$total scenarios pass '
        '($failed failed a checkpoint, $unsupported hit an unsupported step, '
        '$unported checkpoints unported, $differing differ on purpose, '
        '$intendedCheckpoints checkpoints differ on purpose)';
  }

  /// The prefix of the line that names a stale list entry, which the CI
  /// script also looks for.
  static const String stalePrefix = 'Golden replay: stale intended difference:';

  /// The score line, one line per stale list entry, then a diff for each
  /// scenario that did not pass (the scenario, the step, what the prototype
  /// asked and what the screen showed) and the reason for each intended
  /// difference.
  @override
  String toString() {
    final lines = [scoreLine];
    for (final (result, checkpoint) in stale) {
      lines.add(
        '$stalePrefix ${result.scenario.id} '
        '"${checkpoint.checkpoint.description}" holds; remove it from the list',
      );
    }
    for (final result in results.where((r) => !r.passed)) {
      lines.add('');
      lines.addAll(describeFailure(result));
    }
    for (final result in results.where((r) => r.passed)) {
      for (final checkpoint in result.intendedCheckpoints) {
        lines.add('');
        lines.addAll(describeIntended(result, checkpoint));
      }
    }
    return lines.join('\n');
  }

  /// The reason one checkpoint differs on purpose.
  static List<String> describeIntended(
    ScenarioResult result,
    CheckpointResult checkpoint,
  ) => [
    '${result.scenario.id} ${result.scenario.name} — DIFFERS ON PURPOSE at '
        'step ${checkpoint.stepIndex + 1} '
        '"${checkpoint.checkpoint.description}"',
    '  reason:   ${checkpoint.difference?.reason}',
  ];

  /// The readable diff of one scenario that did not pass.
  static List<String> describeFailure(ScenarioResult result) {
    final scenario = result.scenario;
    if (result.difference case final difference?) {
      return [
        '${scenario.id} ${scenario.name} — DIFFERS ON PURPOSE',
        '  reason:   ${difference.reason}',
      ];
    }
    final failure = result.firstFailure;
    if (failure != null) {
      final snapshot = failure.snapshot ?? const Snapshot();
      return [
        '${scenario.id} ${scenario.name} — FAILED at step '
            '${failure.stepIndex + 1} "${failure.checkpoint.description}"',
        '  expected: ${describeCheck(failure.checkpoint.check)}',
        '  actual:   ${describeSnapshot(snapshot)}',
        '  source:   ${failure.checkpoint.source}',
      ];
    }
    final index = result.unsupportedStepIndex;
    if (index != null) {
      return [
        '${scenario.id} ${scenario.name} — UNSUPPORTED step ${index + 1}: '
            '${scenario.steps[index]}',
      ];
    }
    return ['${scenario.id} ${scenario.name} — passed'];
  }
}

/// A check in the words of the prototype's snapshot: `strip[0] == 'Area'`.
String describeCheck(Check check) {
  String q(String? text) => "'${text ?? ''}'";
  final i = check.index;
  return switch (check.kind) {
    CheckKind.value => 'value == ${q(check.text)}',
    CheckKind.valueStartsWith => 'value startsWith ${q(check.text)}',
    CheckKind.valueIncludes => 'value includes ${q(check.text)}',
    CheckKind.valueEndsWith => 'value endsWith ${q(check.text)}',
    CheckKind.label => 'label == ${q(check.text)}',
    CheckKind.labelStartsWith => 'label startsWith ${q(check.text)}',
    CheckKind.labelIncludes => 'label includes ${q(check.text)}',
    CheckKind.labelEndsWith => 'label endsWith ${q(check.text)}',
    CheckKind.tapeAt => 'tape[$i] == ${q(check.text)}',
    CheckKind.tapeAtStartsWith => 'tape[$i] startsWith ${q(check.text)}',
    CheckKind.tapeAtIncludes => 'tape[$i] includes ${q(check.text)}',
    CheckKind.tapeAtPresent => 'tape[$i] exists',
    CheckKind.tape => 'tape == ${check.list}',
    CheckKind.tapeLength => 'tape.length == ${check.number}',
    CheckKind.tapeAny => 'tape contains ${q(check.text)}',
    CheckKind.tapeAnyStartsWith => 'tape any startsWith ${q(check.text)}',
    CheckKind.tapeLast => 'tape.last == ${q(check.text)}',
    CheckKind.tapeJoined => 'tape joined == ${q(check.text)}',
    CheckKind.tapeKindAt => 'tapeKinds[$i] == ${q(check.text)}',
    CheckKind.tapeKinds => 'tapeKinds == ${check.list}',
    CheckKind.tapeBracketAt => 'tapeBracket[$i] == ${check.flag}',
    CheckKind.tapeBracketOpenAt => 'tapeBracketOpen[$i] == ${check.flag}',
    CheckKind.tapeFrozenAt => 'tapeFrozen[$i] == ${check.flag}',
    CheckKind.stripAt => 'strip[$i] == ${q(check.text)}',
    CheckKind.stripAtStartsWith => 'strip[$i] startsWith ${q(check.text)}',
    CheckKind.stripAtIncludes => 'strip[$i] includes ${q(check.text)}',
    CheckKind.stripAtPresent => 'strip[$i] exists',
    CheckKind.strip => 'strip == ${check.list}',
    CheckKind.stripLength => 'strip.length == ${check.number}',
    CheckKind.stripLengthAbove => 'strip.length > ${check.number}',
    CheckKind.stripAny => 'strip contains ${q(check.text)}',
    CheckKind.stripAnyStartsWith => 'strip any startsWith ${q(check.text)}',
    CheckKind.stripAnyIncludes => 'strip any includes ${q(check.text)}',
    CheckKind.stripAnyEndsWith => 'strip any endsWith ${q(check.text)}',
    CheckKind.stripAllStartWithAny =>
      'strip all startWith ${q(check.text)} or ${q(check.otherText)}',
    CheckKind.strip2At => 'strip2[$i] == ${q(check.text)}',
    CheckKind.strip2 => 'strip2 == ${check.list}',
    CheckKind.strip2LengthAbove => 'strip2.length > ${check.number}',
    CheckKind.depKey => 'depKey == ${q(check.text)}',
    CheckKind.depKeyStartsWith => 'depKey startsWith ${q(check.text)}',
    CheckKind.depKeyIncludes => 'depKey includes ${q(check.text)}',
    CheckKind.depKeyShown => 'depKey shown == ${check.flag}',
    CheckKind.toastIncludes => 'toast includes ${q(check.text)}',
    CheckKind.toastStartsWith => 'toast startsWith ${q(check.text)}',
    CheckKind.toastShown => 'toast shown == ${check.flag}',
    CheckKind.actionToastIncludes => 'actionToast includes ${q(check.text)}',
    CheckKind.actionToastShown => 'actionToast shown == ${check.flag}',
    CheckKind.hintIncludes => 'hint includes ${q(check.text)}',
    CheckKind.hint => 'hint == ${q(check.text)}',
    CheckKind.hintShown => 'hint shown == ${check.flag}',
    CheckKind.equalsLabel => 'equalsLabel == ${q(check.text)}',
    CheckKind.more => 'more == ${q(check.text)}',
    CheckKind.memory => 'memory == ${q(check.text)}',
    CheckKind.memoryCount => 'memoryCount == ${check.number}',
    CheckKind.overflowMarkerOnScreen =>
      'overflow marker shown == ${check.flag}',
    CheckKind.historyStage => 'historyStage == ${check.number}',
    CheckKind.historyStageAtLeast => 'historyStage >= ${check.number}',
    CheckKind.historyCountAbove => 'historyCount > ${check.number}',
    CheckKind.historyCountAfterSaves =>
      'historyCount == base + ${check.number}',
    CheckKind.historyBlocks => 'historyBlocks.length == ${check.number}',
    CheckKind.historyBlockAt => 'historyBlocks[$i] == ${q(check.text)}',
    CheckKind.historyBlockAtIncludes =>
      'historyBlocks[$i] includes ${q(check.text)}',
    CheckKind.historyBlockAtPresent => 'historyBlocks[$i] exists',
    CheckKind.bracketOpen => 'bracketOpen == ${check.flag}',
    CheckKind.system => 'system == ${q(check.text)}',
    CheckKind.unitToggleLabel => 'unitToggleLabel == ${q(check.text)}',
    CheckKind.unitToggleShown => 'unitToggleShown == ${check.flag}',
    CheckKind.functionGroup => 'functionGroup == ${q(check.text)}',
    CheckKind.sheetHidden => 'sheetHidden == ${check.flag}',
    CheckKind.stripToggleShown => 'stripToggleShown == ${check.flag}',
    CheckKind.collapsed => 'collapsed == ${check.flag}',
    CheckKind.sizeRowsAnyIncludes => 'sizeRows any includes ${q(check.text)}',
    CheckKind.tilesAnyIncludes => 'tiles any includes ${q(check.text)}',
    CheckKind.all => '(${check.checks.map(describeCheck).join(' && ')})',
    CheckKind.any => '(${check.checks.map(describeCheck).join(' || ')})',
    CheckKind.not => switch (check.inner) {
      null => '!()',
      final inner => '!(${describeCheck(inner)})',
    },
    CheckKind.js => 'js: ${check.source}',
  };
}

/// The surfaces a failure is usually about, on one line.
String describeSnapshot(Snapshot r) =>
    "label='${r.label}' value='${r.value}' tape=${r.tape} strip=${r.strip} "
    'strip2=${r.strip2} depKey=${r.depKey == null ? 'null' : "'${r.depKey}'"} '
    'toast=${r.toast == null ? 'null' : "'${r.toast}'"} '
    "equalsLabel='${r.equalsLabel}' bracketOpen=${r.bracketOpen}";

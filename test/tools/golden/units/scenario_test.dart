import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/golden/check.dart';
import '../../../../scripts/golden/scenario.dart';

Iterable<String> _texts(Check check) => [
  ?check.text,
  ...check.checks.expand(_texts),
  if (check.inner case final inner?) ..._texts(inner),
];

void main() {
  group('scenarios.json', () {
    late List<Scenario> scenarios;

    setUpAll(() {
      scenarios = loadScenarios(File('test/golden/scenarios.json'));
    });

    test('holds every scenario of the prototype with unique ids', () {
      expect(scenarios, hasLength(134));
      expect(scenarios.map((s) => s.id).toSet(), hasLength(134));
      expect(scenarios.first.id, 'S01');
      expect(scenarios.first.name, 'Area happy path');
      expect(scenarios.first.category, 'Calculation journeys');
    });

    test('holds every step and checkpoint, each of a known kind', () {
      final steps = scenarios.expand((s) => s.steps).toList();
      expect(steps.whereType<KeyStep>(), hasLength(1919));
      expect(steps.whereType<CheckpointStep>(), hasLength(734));
      expect(steps.whereType<ClickStep>(), hasLength(197));
      expect(steps.whereType<SheetKeyStep>(), hasLength(46));
      expect(steps.whereType<AcceptStep>(), hasLength(46));
      expect(steps.whereType<TapChipStep>(), hasLength(30));
      expect(steps.whereType<CollapseStep>(), hasLength(23));
      expect(steps.whereType<JsStep>(), hasLength(15));
      expect(steps.whereType<ExpandStep>(), hasLength(13));
      expect(steps.whereType<SwipeStep>(), hasLength(10));
      expect(steps.whereType<ToggleStep>(), hasLength(2));
    });

    test('ports most checkpoints and keeps the source of the rest', () {
      final checkpoints = scenarios.expand((s) => s.checkpoints).toList();
      final ported = checkpoints.where((c) => c.check.isPorted).length;
      expect(ported, greaterThanOrEqualTo(642));
      for (final checkpoint in checkpoints) {
        expect(
          checkpoint.source,
          contains('=>'),
          reason: checkpoint.description,
        );
        expect(checkpoint.description, isNotEmpty);
      }
      final texts = checkpoints.map((c) => c.check).expand(_texts);
      expect(texts, isNot(contains('Area:410.67ft²')));
      expect(texts, contains('Area: 410.67ft²'));
    });

    test('a checkpoint left as js asks what no snapshot can answer', () {
      // Reads of the DOM, a regular expression, or arithmetic on the history
      // count: anything else is a snapshot shape the classifier should have
      // recognised, so an export that loses one fails here.
      final beyondTheSnapshot = RegExp(
        r'document|getComputedStyle|querySelector|classList|offset|window|'
        r'localStorage|state\.|Engine|REPLAY|tapeRowCount|PITCH_MAX|Math\.|'
        r'\.test\(|histAfterSaves\(\d+\)-|\.some\(.*&&',
      );
      final unported = scenarios
          .expand((s) => s.checkpoints)
          .where((c) => !c.check.isPorted);
      expect(unported, isNotEmpty);
      for (final checkpoint in unported) {
        expect(
          checkpoint.source,
          matches(beyondTheSnapshot),
          reason: checkpoint.description,
        );
      }
    });

    test('S01 reads as the walkthrough 11.1 keys and checks', () {
      final s01 = scenarios.first;
      expect(s01.keys, 'Length 22ft → Width 18ft 8in → accept Area');
      expect(s01.steps.first, const KeyStep('fk:Length'));
      final first = s01.checkpoints.first;
      expect(first.description, 'top chip Area: 410.67ft²');
      expect(
        first.check,
        const Check(CheckKind.stripAt, index: 0, text: 'Area: 410.67ft²'),
      );
      final rows = s01.checkpoints.elementAt(1).check;
      expect(rows.kind, CheckKind.all);
      expect(
        rows.checks.last,
        const Check(CheckKind.strip2, list: ['224in', '5.69m']),
      );
      expect(s01.steps.whereType<AcceptStep>().first.prefix, 'Area');
    });

    test('a step of an unknown kind is a format error', () {
      expect(
        () => ScenarioStep.fromJson({'kind': 'teleport'}),
        throwsFormatException,
      );
    });

    test('every step kind reads from JSON', () {
      expect(
        ScenarioStep.fromJson({'kind': 'key', 'key': 'd:2'}),
        const KeyStep('d:2'),
      );
      expect(
        ScenarioStep.fromJson({'kind': 'sheetKey', 'key': 'd:4'}),
        const SheetKeyStep('d:4'),
      );
      expect(
        ScenarioStep.fromJson({'kind': 'accept', 'prefix': 'Area'}),
        const AcceptStep('Area'),
      );
      expect(
        ScenarioStep.fromJson({'kind': 'tapChip', 'prefix': 'Width'}),
        const TapChipStep('Width'),
      );
      expect(ScenarioStep.fromJson({'kind': 'toggle'}), const ToggleStep());
      expect(ScenarioStep.fromJson({'kind': 'collapse'}), const CollapseStep());
      expect(ScenarioStep.fromJson({'kind': 'expand'}), const ExpandStep());
      expect(
        ScenarioStep.fromJson({
          'kind': 'swipe',
          'direction': 'down',
          'on': null,
        }),
        const SwipeStep('down'),
      );
      expect(
        ScenarioStep.fromJson({
          'kind': 'click',
          'selector': '.x',
          'withText': 'Undo',
        }),
        const ClickStep('.x', withText: 'Undo'),
      );
      expect(
        ScenarioStep.fromJson({'kind': 'js', 'source': '() => render()'}),
        const JsStep('() => render()'),
      );
      expect(
        ScenarioStep.fromJson({
          'kind': 'checkpoint',
          'description': 'd',
          'check': {'kind': 'value', 'equals': '1'},
          'source': 'r=>r.value===\'1\'',
        }),
        const CheckpointStep(
          'd',
          Check(CheckKind.value, text: '1'),
          source: 'r=>r.value===\'1\'',
        ),
      );
    });
  });
}

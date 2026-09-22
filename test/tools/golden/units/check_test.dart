import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/golden/check.dart';
import '../../../../scripts/golden/snapshot.dart';

void main() {
  const snapshot = Snapshot(
    label: 'Addition · (3×4)',
    value: '410.67ft²',
    depKey: 'Sheet size: 47.24in x 94.49in',
    hint: 'Type the angle in degrees',
    tape: ['Length22ft', 'Width18ft 8in', 'Area410.67ft²'],
    tapeKinds: ['t-input', 't-input', 't-result'],
    tapeBracket: [false, true, false],
    tapeBracketOpen: [false, false, false],
    tapeFrozen: [true, false, false],
    strip: ['Area: 410.67ft²', 'Diagonal: 28.85ft', 'Perimeter: 81.33ft'],
    strip2: ['224in', '5.69m'],
    more: '+1',
    memory: '22ft',
    memoryCount: 1,
    overflowMarkerOnScreen: true,
    equalsLabel: 'Area',
    bracketOpen: true,
    unitToggleShown: false,
    unitToggleLabel: 'Metric',
    system: 'metric',
    functionGroup: 'Materials',
    tiles: ['Area 410.67ft²'],
    sizeRows: ['48in x 96in'],
    toast:
        'Calculation cannot be processed as weight (pounds) and dimensions (feet) are incompatible.',
    actionToast: 'Saved to history · Calc 60ft²',
    historyCount: 3,
    historyStage: 2,
    historyBlocks: ['12ft × 5ft = Calc 60ft²'],
    sheetHidden: true,
    stripToggleShown: true,
  );

  Check check(
    CheckKind kind, {
    int? index,
    String? text,
    String? other,
    List<String>? list,
    int? number,
    bool? flag,
    String? separator,
  }) => Check(
    kind,
    index: index,
    text: text,
    otherText: other,
    list: list,
    number: number,
    flag: flag,
    separator: separator,
  );

  group('Check', () {
    group('holds against a snapshot, one row per kind', () {
      final rows = <String, (Check, Check)>{
        'value': (
          check(CheckKind.value, text: '410.67ft²'),
          check(CheckKind.value, text: '410.64ft²'),
        ),
        'valueStartsWith': (
          check(CheckKind.valueStartsWith, text: '410'),
          check(CheckKind.valueStartsWith, text: '411'),
        ),
        'valueIncludes': (
          check(CheckKind.valueIncludes, text: 'ft²'),
          check(CheckKind.valueIncludes, text: 'yd²'),
        ),
        'label': (
          check(CheckKind.label, text: 'Addition · (3×4)'),
          check(CheckKind.label, text: 'Value'),
        ),
        'labelStartsWith': (
          check(CheckKind.labelStartsWith, text: 'Addition'),
          check(CheckKind.labelStartsWith, text: 'Value'),
        ),
        'labelIncludes': (
          check(CheckKind.labelIncludes, text: '(3×4)'),
          check(CheckKind.labelIncludes, text: '(2+3)'),
        ),
        'tapeAt': (
          check(CheckKind.tapeAt, index: 1, text: 'Width18ft 8in'),
          check(CheckKind.tapeAt, index: 5, text: 'Width18ft 8in'),
        ),
        'tapeAtStartsWith': (
          check(CheckKind.tapeAtStartsWith, index: 2, text: 'Area'),
          check(CheckKind.tapeAtStartsWith, index: 2, text: 'Width'),
        ),
        'tape': (
          check(
            CheckKind.tape,
            list: ['Length22ft', 'Width18ft 8in', 'Area410.67ft²'],
          ),
          check(CheckKind.tape, list: ['Length22ft']),
        ),
        'tapeLength': (
          check(CheckKind.tapeLength, number: 3),
          check(CheckKind.tapeLength, number: 2),
        ),
        'tapeAny': (
          check(CheckKind.tapeAny, text: 'Length22ft'),
          check(CheckKind.tapeAny, text: 'Height8ft'),
        ),
        'tapeLast': (
          check(CheckKind.tapeLast, text: 'Area410.67ft²'),
          check(CheckKind.tapeLast, text: 'Length22ft'),
        ),
        'tapeJoined': (
          check(
            CheckKind.tapeJoined,
            separator: ' ',
            text: 'Length22ft Width18ft 8in Area410.67ft²',
          ),
          check(CheckKind.tapeJoined, separator: '', text: 'x'),
        ),
        'tapeKindAt': (
          check(CheckKind.tapeKindAt, index: 2, text: 't-result'),
          check(CheckKind.tapeKindAt, index: 2, text: 't-error'),
        ),
        'tapeKinds': (
          check(CheckKind.tapeKinds, list: ['t-input', 't-input', 't-result']),
          check(CheckKind.tapeKinds, list: ['t-input']),
        ),
        'tapeBracketAt': (
          check(CheckKind.tapeBracketAt, index: 1, flag: true),
          check(CheckKind.tapeBracketAt, index: 0, flag: true),
        ),
        'tapeBracketOpenAt': (
          check(CheckKind.tapeBracketOpenAt, index: 1, flag: false),
          check(CheckKind.tapeBracketOpenAt, index: 1, flag: true),
        ),
        'stripAt': (
          check(CheckKind.stripAt, index: 0, text: 'Area: 410.67ft²'),
          check(CheckKind.stripAt, index: 0, text: 'Cost: \$1'),
        ),
        'stripAtStartsWith': (
          check(CheckKind.stripAtStartsWith, index: 1, text: 'Diagonal'),
          check(CheckKind.stripAtStartsWith, index: 9, text: 'Diagonal'),
        ),
        'stripAtIncludes': (
          check(CheckKind.stripAtIncludes, index: 2, text: '81.33'),
          check(CheckKind.stripAtIncludes, index: 2, text: '80'),
        ),
        'strip': (
          check(
            CheckKind.strip,
            list: [
              'Area: 410.67ft²',
              'Diagonal: 28.85ft',
              'Perimeter: 81.33ft',
            ],
          ),
          check(CheckKind.strip, list: []),
        ),
        'stripLength': (
          check(CheckKind.stripLength, number: 3),
          check(CheckKind.stripLength, number: 0),
        ),
        'stripLengthAbove': (
          check(CheckKind.stripLengthAbove, number: 2),
          check(CheckKind.stripLengthAbove, number: 3),
        ),
        'stripAny': (
          check(CheckKind.stripAny, text: 'Diagonal: 28.85ft'),
          check(CheckKind.stripAny, text: 'Diagonal'),
        ),
        'stripAnyStartsWith': (
          check(CheckKind.stripAnyStartsWith, text: 'Perimeter'),
          check(CheckKind.stripAnyStartsWith, text: 'Cost'),
        ),
        'stripAnyIncludes': (
          check(CheckKind.stripAnyIncludes, text: '28.85'),
          check(CheckKind.stripAnyIncludes, text: '?'),
        ),
        'stripAnyEndsWith': (
          check(CheckKind.stripAnyEndsWith, text: 'ft'),
          check(CheckKind.stripAnyEndsWith, text: '?'),
        ),
        'strip2At': (
          check(CheckKind.strip2At, index: 1, text: '5.69m'),
          check(CheckKind.strip2At, index: 1, text: '6.71m'),
        ),
        'strip2': (
          check(CheckKind.strip2, list: ['224in', '5.69m']),
          check(CheckKind.strip2, list: ['224in']),
        ),
        'depKey': (
          check(CheckKind.depKey, text: 'Sheet size: 47.24in x 94.49in'),
          check(CheckKind.depKey, text: 'Rate'),
        ),
        'depKeyStartsWith': (
          check(CheckKind.depKeyStartsWith, text: 'Sheet size'),
          check(CheckKind.depKeyStartsWith, text: 'Rate'),
        ),
        'depKeyIncludes': (
          check(CheckKind.depKeyIncludes, text: '94.49in'),
          check(CheckKind.depKeyIncludes, text: '96in'),
        ),
        'depKeyShown': (
          check(CheckKind.depKeyShown, flag: true),
          check(CheckKind.depKeyShown, flag: false),
        ),
        'toastIncludes': (
          check(CheckKind.toastIncludes, text: 'incompatible'),
          check(CheckKind.toastIncludes, text: 'Saved'),
        ),
        'toastShown': (
          check(CheckKind.toastShown, flag: true),
          check(CheckKind.toastShown, flag: false),
        ),
        'actionToastIncludes': (
          check(CheckKind.actionToastIncludes, text: 'Saved to history'),
          check(CheckKind.actionToastIncludes, text: 'Undo'),
        ),
        'actionToastShown': (
          check(CheckKind.actionToastShown, flag: true),
          check(CheckKind.actionToastShown, flag: false),
        ),
        'hintIncludes': (
          check(CheckKind.hintIncludes, text: 'degrees'),
          check(CheckKind.hintIncludes, text: 'ratio'),
        ),
        'hintShown': (
          check(CheckKind.hintShown, flag: true),
          check(CheckKind.hintShown, flag: false),
        ),
        'equalsLabel': (
          check(CheckKind.equalsLabel, text: 'Area'),
          check(CheckKind.equalsLabel, text: 'Calc'),
        ),
        'more': (
          check(CheckKind.more, text: '+1'),
          check(CheckKind.more, text: '+2'),
        ),
        'memory': (
          check(CheckKind.memory, text: '22ft'),
          check(CheckKind.memory, text: '18ft'),
        ),
        'historyStage': (
          check(CheckKind.historyStage, number: 2),
          check(CheckKind.historyStage, number: 0),
        ),
        'historyBlocks': (
          check(CheckKind.historyBlocks, number: 1),
          check(CheckKind.historyBlocks, number: 0),
        ),
        'bracketOpen': (
          check(CheckKind.bracketOpen, flag: true),
          check(CheckKind.bracketOpen, flag: false),
        ),
        'system': (
          check(CheckKind.system, text: 'metric'),
          check(CheckKind.system, text: 'imperial'),
        ),
        'unitToggleLabel': (
          check(CheckKind.unitToggleLabel, text: 'Metric'),
          check(CheckKind.unitToggleLabel, text: 'Imperial'),
        ),
        'unitToggleShown': (
          check(CheckKind.unitToggleShown, flag: false),
          check(CheckKind.unitToggleShown, flag: true),
        ),
        'functionGroup': (
          check(CheckKind.functionGroup, text: 'Materials'),
          check(CheckKind.functionGroup, text: 'Shapes'),
        ),
        'sheetHidden': (
          check(CheckKind.sheetHidden, flag: true),
          check(CheckKind.sheetHidden, flag: false),
        ),
        'stripToggleShown': (
          check(CheckKind.stripToggleShown, flag: true),
          check(CheckKind.stripToggleShown, flag: false),
        ),
        'sizeRowsAnyIncludes': (
          check(CheckKind.sizeRowsAnyIncludes, text: '96in'),
          check(CheckKind.sizeRowsAnyIncludes, text: '108in'),
        ),
        'tilesAnyIncludes': (
          check(CheckKind.tilesAnyIncludes, text: 'Area'),
          check(CheckKind.tilesAnyIncludes, text: 'Volume'),
        ),
        'valueEndsWith': (
          check(CheckKind.valueEndsWith, text: 'ft²'),
          check(CheckKind.valueEndsWith, text: 'yd²'),
        ),
        'labelEndsWith': (
          check(CheckKind.labelEndsWith, text: '(3×4)'),
          check(CheckKind.labelEndsWith, text: '…'),
        ),
        'tapeAtIncludes': (
          check(CheckKind.tapeAtIncludes, index: 1, text: '8in'),
          check(CheckKind.tapeAtIncludes, index: 1, text: 'yd'),
        ),
        'tapeAtPresent': (
          check(CheckKind.tapeAtPresent, index: 2),
          check(CheckKind.tapeAtPresent, index: 3),
        ),
        'tapeAnyStartsWith': (
          check(CheckKind.tapeAnyStartsWith, text: 'Width'),
          check(CheckKind.tapeAnyStartsWith, text: 'Height'),
        ),
        'tapeFrozenAt': (
          check(CheckKind.tapeFrozenAt, index: 0, flag: true),
          check(CheckKind.tapeFrozenAt, index: 1, flag: true),
        ),
        'stripAtPresent': (
          check(CheckKind.stripAtPresent, index: 0),
          check(CheckKind.stripAtPresent, index: 5),
        ),
        'strip2LengthAbove': (
          check(CheckKind.strip2LengthAbove, number: 1),
          check(CheckKind.strip2LengthAbove, number: 2),
        ),
        'toastStartsWith': (
          check(CheckKind.toastStartsWith, text: 'Calculation'),
          check(CheckKind.toastStartsWith, text: 'Saved'),
        ),
        'hint': (
          check(CheckKind.hint, text: 'Type the angle in degrees'),
          check(CheckKind.hint, text: 'Type the ratio'),
        ),
        'memoryCount': (
          check(CheckKind.memoryCount, number: 1),
          check(CheckKind.memoryCount, number: 2),
        ),
        'overflowMarkerOnScreen': (
          check(CheckKind.overflowMarkerOnScreen, flag: true),
          check(CheckKind.overflowMarkerOnScreen, flag: false),
        ),
        'historyStageAtLeast': (
          check(CheckKind.historyStageAtLeast, number: 2),
          check(CheckKind.historyStageAtLeast, number: 3),
        ),
        'historyCountAbove': (
          check(CheckKind.historyCountAbove, number: 2),
          check(CheckKind.historyCountAbove, number: 3),
        ),
        'historyBlockAt': (
          check(
            CheckKind.historyBlockAt,
            index: 0,
            text: '12ft × 5ft = Calc 60ft²',
          ),
          check(CheckKind.historyBlockAt, index: 0, text: '12ft × 5ft'),
        ),
        'historyBlockAtIncludes': (
          check(CheckKind.historyBlockAtIncludes, index: 0, text: 'Calc'),
          check(CheckKind.historyBlockAtIncludes, index: 0, text: 'Volume'),
        ),
        'historyBlockAtPresent': (
          check(CheckKind.historyBlockAtPresent, index: 0),
          check(CheckKind.historyBlockAtPresent, index: 1),
        ),
        'collapsed': (
          check(CheckKind.collapsed, flag: false),
          check(CheckKind.collapsed, flag: true),
        ),
      };
      for (final entry in rows.entries) {
        test(entry.key, () {
          final (holds, fails) = entry.value;
          expect(holds.holds(snapshot), isTrue, reason: 'should hold');
          expect(fails.holds(snapshot), isFalse, reason: 'should fail');
        });
      }
    });

    test('every strip chip starts with one of two prefixes', () {
      final conversions = check(
        CheckKind.stripAllStartWithAny,
        text: 'Conv:',
        other: 'Cost:',
      );
      expect(
        conversions.holds(const Snapshot(strip: ['Conv: 1', 'Cost: \$2'])),
        isTrue,
      );
      expect(conversions.holds(snapshot), isFalse);
    });

    test(
      'a history count after saves counts from the base and caps at fifty',
      () {
        final afterTwo = check(CheckKind.historyCountAfterSaves, number: 2);
        expect(afterTwo.holds(const Snapshot(historyCount: 2)), isTrue);
        expect(
          afterTwo.holds(const Snapshot(historyCount: 5), baseHistory: 3),
          isTrue,
        );
        expect(
          afterTwo.holds(const Snapshot(historyCount: 50), baseHistory: 49),
          isTrue,
        );
        expect(afterTwo.holds(const Snapshot(historyCount: 3)), isFalse);
      },
    );

    test('all, any and not compose', () {
      final value = check(CheckKind.value, text: '410.67ft²');
      final wrong = check(CheckKind.value, text: 'x');
      expect(
        Check(CheckKind.all, checks: [value, value]).holds(snapshot),
        isTrue,
      );
      expect(
        Check(CheckKind.all, checks: [value, wrong]).holds(snapshot),
        isFalse,
      );
      expect(
        Check(CheckKind.any, checks: [wrong, value]).holds(snapshot),
        isTrue,
      );
      expect(
        Check(CheckKind.any, checks: [wrong, wrong]).holds(snapshot),
        isFalse,
      );
      expect(Check(CheckKind.not, inner: wrong).holds(snapshot), isTrue);
      expect(Check(CheckKind.not, inner: value).holds(snapshot), isFalse);
      expect(const Check(CheckKind.not).holds(snapshot), isFalse);
    });

    test('an unported closure never holds and says so', () {
      const js = Check(
        CheckKind.js,
        source: 'r => document.querySelectorAll(".x").length === 2',
      );
      expect(js.holds(snapshot), isFalse);
      expect(js.isPorted, isFalse);
      expect(
        Check(
          CheckKind.all,
          checks: [
            check(CheckKind.value, text: 'a'),
            js,
          ],
        ).isPorted,
        isFalse,
      );
      expect(const Check(CheckKind.not, inner: js).isPorted, isFalse);
      expect(const Check(CheckKind.not).isPorted, isFalse);
      expect(check(CheckKind.value, text: 'a').isPorted, isTrue);
    });

    test('an index past the end of a list never holds', () {
      expect(
        check(CheckKind.tapeAt, index: 9, text: 'x').holds(snapshot),
        isFalse,
      );
      expect(
        check(CheckKind.tapeBracketAt, index: 9, flag: false).holds(snapshot),
        isFalse,
      );
      expect(
        check(
          CheckKind.strip2At,
          index: 0,
          text: '224in',
        ).holds(const Snapshot()),
        isFalse,
      );
      expect(
        check(CheckKind.tapeLast, text: 'x').holds(const Snapshot()),
        isFalse,
      );
    });

    group('fromJson', () {
      test('reads each field the export writes', () {
        expect(
          Check.fromJson({
            'kind': 'tapeAt',
            'index': 1,
            'equals': 'Width18ft 8in',
          }),
          check(CheckKind.tapeAt, index: 1, text: 'Width18ft 8in'),
        );
        expect(
          Check.fromJson({
            'kind': 'tape',
            'equals': ['a', 'b'],
          }),
          check(CheckKind.tape, list: ['a', 'b']),
        );
        expect(
          Check.fromJson({'kind': 'stripLengthAbove', 'above': 2}),
          check(CheckKind.stripLengthAbove, number: 2),
        );
        expect(
          Check.fromJson({'kind': 'historyCountAfterSaves', 'saves': 1}),
          check(CheckKind.historyCountAfterSaves, number: 1),
        );
        expect(
          Check.fromJson({'kind': 'historyStageAtLeast', 'atLeast': 2}),
          check(CheckKind.historyStageAtLeast, number: 2),
        );
        expect(
          Check.fromJson({'kind': 'more', 'equals': null}),
          check(CheckKind.more),
        );
        expect(
          Check.fromJson({'kind': 'strip2', 'equals': null}),
          check(CheckKind.strip2),
        );
        expect(
          Check.fromJson({'kind': 'bracketOpen', 'equals': true}),
          check(CheckKind.bracketOpen, flag: true),
        );
        expect(
          Check.fromJson({'kind': 'stripAnyStartsWith', 'prefix': 'Cost'}),
          check(CheckKind.stripAnyStartsWith, text: 'Cost'),
        );
        expect(
          Check.fromJson({'kind': 'toastIncludes', 'text': 'incompatible'}),
          check(CheckKind.toastIncludes, text: 'incompatible'),
        );
        expect(
          Check.fromJson({'kind': 'stripAnyEndsWith', 'suffix': '?'}),
          check(CheckKind.stripAnyEndsWith, text: '?'),
        );
        expect(
          Check.fromJson({
            'kind': 'tapeJoined',
            'separator': ' ',
            'equals': 'a b',
          }),
          check(CheckKind.tapeJoined, separator: ' ', text: 'a b'),
        );
        expect(
          Check.fromJson({
            'kind': 'stripAllStartWithAny',
            'prefixes': ['Conv:', 'Cost:'],
          }),
          check(CheckKind.stripAllStartWithAny, text: 'Conv:', other: 'Cost:'),
        );
      });

      test('reads nested all, any and not', () {
        final json = {
          'kind': 'all',
          'checks': [
            {'kind': 'value', 'equals': '3'},
            {
              'kind': 'not',
              'check': {
                'kind': 'any',
                'checks': [
                  {'kind': 'js', 'source': 'x'},
                ],
              },
            },
          ],
        };
        final parsed = Check.fromJson(json);
        expect(parsed.kind, CheckKind.all);
        expect(parsed.checks.first, check(CheckKind.value, text: '3'));
        expect(parsed.checks.last.kind, CheckKind.not);
        expect(parsed.checks.last.inner!.checks.single.kind, CheckKind.js);
        expect(parsed.isPorted, isFalse);
      });
    });
  });
}

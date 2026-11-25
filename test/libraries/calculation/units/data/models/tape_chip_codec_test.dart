import 'dart:convert';

import 'package:construculator/libraries/calculation/data/models/tape_chip_codec.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const length = ValueChip(
    key: 'Length',
    entry: EntryBuffer([Token(digits: '22', unit: Unit.foot)]),
    isActive: false,
  );
  const width = ValueChip(
    key: 'Width',
    entry: EntryBuffer([
      Token(digits: '18', unit: Unit.foot),
      Token(digits: '8', unit: Unit.inch),
    ]),
    isActive: false,
  );
  final area = ResultChip(
    key: 'Area',
    value: Area(410.67 * 4096 * 144, unit: Unit.foot),
  );
  const two = ValueChip(
    entry: EntryBuffer([Token(digits: '2')]),
    isActive: false,
  );
  const three = ValueChip(
    operator: Operator.add,
    entry: EntryBuffer([Token(digits: '3')]),
    isActive: false,
  );
  const four = ValueChip(
    operator: Operator.multiply,
    entry: EntryBuffer([Token(digits: '4')]),
    isActive: false,
  );

  group('TapeChipCodec', () {
    test('every chip kind round-trips with its payload: a named value, a '
        'bare number, a result, an open and a closed bracket with what a '
        'reopened one restores to, and an error', () {
      const converted = ValueChip(
        key: 'Width',
        entry: EntryBuffer([
          Token(digits: '6.222', unit: Unit.yard, typedAs: '18ft 8in'),
        ]),
        exact: (
          value: Length(14336, unit: Unit.footInch),
          spelled: EntryBuffer([Token(digits: '6.222', unit: Unit.yard)]),
        ),
        isActive: false,
      );
      const ton = ValueChip(
        operator: Operator.add,
        entry: EntryBuffer([Token(digits: '2', unit: Unit.ton)]),
        poundsPerTon: 2240,
        isActive: false,
      );
      const pitch = ValueChip(
        key: 'Pitch',
        entry: EntryBuffer([Token(digits: '30')]),
        keyWantsUnit: false,
        readsDegrees: true,
      );
      final chips = <TapeChip>[
        length,
        width,
        area,
        converted,
        ton,
        pitch,
        const ResultChip(
          key: 'Calc',
          value: Scalar(14),
          operator: Operator.multiply,
        ),
        const BracketChip(
          operator: Operator.add,
          inner: [three, four],
          isOpen: false,
        ),
        const BracketChip(
          operator: Operator.multiply,
          inner: [two],
          original: [two, three],
        ),
        const BracketChip(),
        const ErrorChip(CalculationError.dimensionError),
        const ErrorChip(CalculationError.divisionByZero),
        const ErrorChip(CalculationError.outOfRange),
        const ValueChip(key: 'Height', entry: EntryBuffer([])),
        const BracketChip(
          inner: [
            two,
            BracketChip(operator: Operator.add, inner: [three], isOpen: false),
          ],
          isOpen: false,
        ),
        const BracketChip(inner: [two], isOpen: false),
        length,
      ];
      final json = TapeChipCodec.encode(chips);
      final read = TapeChipCodec.decode(json);
      expect(read, chips);
      for (final (index, chip) in read.indexed) {
        expect(chip.runtimeType, chips[index].runtimeType, reason: '$chip');
      }
      final readPitch = read[5] as ValueChip;
      expect(readPitch.keyWantsUnit, isFalse);
      expect(readPitch.readsDegrees, isTrue);
      expect(readPitch.isActive, isTrue);
      expect((read[3] as ValueChip).exact, converted.exact);
      expect((read[4] as ValueChip).poundsPerTon, 2240);
      final nested = read[14] as BracketChip;
      expect(nested.inner.last, isA<BracketChip>());
      expect((nested.inner.last as BracketChip).inner, [three]);
      expect(read.sublist(15), [
        const BracketChip(inner: [two], isOpen: false),
        length,
      ]);
    });

    test('an empty tape round-trips as an empty chip list', () {
      final json = TapeChipCodec.encode([]);
      expect(jsonDecode(json), {'schema_version': 1, 'chips': []});
      expect(TapeChipCodec.decode(json), isEmpty);
    });

    test('the JSON is versioned and types its chips the way Appendix D '
        'does: fn_key, common, result, bracket, and error', () {
      final json = jsonDecode(
        TapeChipCodec.encode([
          length,
          two,
          area,
          const BracketChip(inner: [three], isOpen: false),
          const ErrorChip(CalculationError.outOfRange),
        ]),
      );
      expect(json['schema_version'], 1);
      expect(
        [for (final chip in json['chips'] as List) chip['type']],
        ['fn_key', 'common', 'result', 'bracket', 'error'],
      );
      final first = (json['chips'] as List).first as Map;
      expect(first['key'], 'Length');
      expect(first['tokens'], [
        {
          'n': '22',
          'd': null,
          'unit': 'foot',
          'p': 1,
          'm': null,
          's': null,
          't': null,
        },
      ]);
      expect(first['op'], isNull);
      expect(first['exact'], isNull);
      expect(first['active'], isFalse);
      expect(first, isNot(contains('text')));
      final bracket = (json['chips'] as List)[3] as Map;
      expect((bracket['inner'] as List).single['op'], 'add');
      expect(bracket['open'], isFalse);
      expect(bracket['original'], isNull);
    });

    test('a text beside each chip is written when asked for, and ignored '
        'on read', () {
      final json = TapeChipCodec.encode(
        [length, area],
        text: (chip) => switch (chip) {
          ValueChip(:final entry) => entry.text,
          ResultChip(:final key) => key,
          BracketChip() || ErrorChip() => '',
        },
      );
      expect(
        [for (final chip in jsonDecode(json)['chips'] as List) chip['text']],
        ['22ft', 'Area'],
      );
      expect(TapeChipCodec.decode(json), [length, area]);
    });

    test('the version-1 wire format of a banked rectangle is pinned', () {
      const wire =
          '{"schema_version":1,"chips":['
          '{"type":"fn_key","key":"Length","op":null,'
          '"tokens":[{"n":"22","d":null,"unit":"foot","p":1,"m":null,"s":null,"t":null}],'
          '"exact":null,"lbs_per_ton":null,"wants_unit":true,"degrees":false,"active":false},'
          '{"type":"result","key":"Area","op":null,'
          '"value":{"dim":"area","value":242221056.0,"unit":"foot"}}]}';
      expect(TapeChipCodec.decode(wire), [
        length,
        const ResultChip(
          key: 'Area',
          value: Area(242221056, unit: Unit.foot),
        ),
      ]);
      expect(
        TapeChipCodec.encode([
          length,
          const ResultChip(
            key: 'Area',
            value: Area(242221056, unit: Unit.foot),
          ),
        ]),
        wire,
      );
    });

    test('a tape of another schema version, or no JSON, is refused whole', () {
      for (final json in [
        '{"schema_version":2,"chips":[]}',
        '{"schema_version":0,"chips":[]}',
        '{"schema_version":-1,"chips":[]}',
        '{"schema_version":"1","chips":[]}',
        '{"chips":[]}',
        '{"schema_version":1}',
        '[]',
        'not json',
        '',
      ]) {
        expect(
          () => TapeChipCodec.decode(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              startsWith('Unreadable tape'),
            ),
          ),
          reason: json,
        );
      }
    });

    test('a chip that cannot be read names where it sits, as a format '
        'error', () {
      final cases = <String, Object?>{
        'chips': 'none',
        'chips[0]': [7],
        'chips[0].type': [
          {'type': 'rune'},
        ],
        'chips[0].tokens': [
          {
            'type': 'common',
            'wants_unit': true,
            'degrees': false,
            'active': true,
          },
        ],
        'chips[0].wants_unit': [
          {'type': 'common', 'tokens': [], 'degrees': false, 'active': true},
        ],
        'chips[0].op': [
          {
            'type': 'common',
            'op': 'plus',
            'tokens': [],
            'wants_unit': true,
            'degrees': false,
            'active': true,
          },
        ],
        'chips[0].lbs_per_ton': [
          {
            'type': 'common',
            'tokens': [],
            'lbs_per_ton': '2000',
            'wants_unit': true,
            'degrees': false,
            'active': true,
          },
        ],
        'chips[0].exact.value': [
          {
            'type': 'common',
            'tokens': [],
            'exact': {'tokens': []},
            'wants_unit': true,
            'degrees': false,
            'active': true,
          },
        ],
        'chips[0].key': [
          {
            'type': 'result',
            'value': {'dim': 'scalar', 'value': 1, 'pads': false},
          },
        ],
        'chips[0].value': [
          {'type': 'result', 'key': 'Calc', 'value': 1},
        ],
        'chips[0].inner': [
          {'type': 'bracket', 'open': true},
        ],
        'chips[0].inner[0].type': [
          {
            'type': 'bracket',
            'inner': [
              {'type': 'rune'},
            ],
            'open': true,
          },
        ],
        'chips[0].original': [
          {'type': 'bracket', 'inner': [], 'open': false, 'original': {}},
        ],
        'chips[0].error': [
          {'type': 'error', 'error': 'overflow'},
        ],
      };
      for (final MapEntry(key: where, value: chips) in cases.entries) {
        final json = jsonEncode({'schema_version': 1, 'chips': chips});
        expect(
          () => TapeChipCodec.decode(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Unreadable tape: $where',
            ),
          ),
          reason: where,
        );
      }
    });
  });
}

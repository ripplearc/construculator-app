import 'package:construculator/libraries/calculation/data/models/tape_value_codec.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TapeValueCodec quantities', () {
    test('every kind of quantity round-trips at full precision, in the unit '
        'it was spelled in', () {
      final values = <Quantity>[
        const Length(16896, unit: Unit.foot),
        const Length(14336, unit: Unit.footInch),
        const Length.exact(Rational(6000, 127), unit: Unit.millimetre),
        Length.computed(18.38 * Length.ticksPerFoot + 0.3, unit: Unit.foot),
        const Length(-1260, unit: Unit.centimetre),
        Area(410.67 * 4096 * 144, unit: Unit.foot),
        const Area(43560 * 4096 * 144, unit: Unit.acre),
        const Volume(960, unit: Unit.yard),
        const Volume(50.1751 / 12, unit: Unit.boardFoot),
        const Weight(292000, unit: Unit.ton),
        const Weight(1620, unit: Unit.kilogram),
        const Angle(38.5),
        const Angle(38.05, spelling: AngleSpelling.degreesMinutesSeconds),
        const Angle(-0.5),
        const Scalar(13.25),
        const Scalar(0.013, decimals: 3),
        const Scalar(12, decimals: 2, padsDecimals: true),
        const Scalar(0),
        const Length(0, unit: Unit.inch),
      ];
      for (final value in values) {
        final json = TapeValueCodec.quantity(value);
        final read = TapeValueCodec.quantityFrom(json, 'value');
        expect(read, value, reason: '$value');
        expect(read.runtimeType, value.runtimeType, reason: '$value');
        if (value is Scalar) {
          expect((read as Scalar).decimals, value.decimals);
          expect(read.padsDecimals, value.padsDecimals);
        }
        if (value is Angle) {
          expect((read as Angle).spelling, value.spelling);
        }
      }
    });

    test('a length is written as its exact inches, so a metric length and '
        'a computed one lose nothing', () {
      expect(
        TapeValueCodec.quantity(
          const Length.exact(Rational(6000, 127), unit: Unit.millimetre),
        ),
        {'dim': 'length', 'inches': '6000/127', 'unit': 'millimetre'},
      );
      expect(TapeValueCodec.quantity(const Length(16896, unit: Unit.foot)), {
        'dim': 'length',
        'inches': '16896/64',
        'unit': 'foot',
      });
      final computed = Length.computed(1234.5678, unit: Unit.foot);
      final read =
          TapeValueCodec.quantityFrom(
                TapeValueCodec.quantity(computed),
                'value',
              )
              as Length;
      expect(read.inches, computed.inches);
      expect(read.preciseTicks, computed.preciseTicks);
    });

    test('a length of nothing is written as a fraction of zero inches and '
        'reads back as zero', () {
      final json = TapeValueCodec.quantity(const Length(0, unit: Unit.inch));
      expect(json['inches'], '0/64');
      final read = TapeValueCodec.quantityFrom(json, 'value') as Length;
      expect(read.inches.isZero, isTrue);
      expect(read, const Length(0, unit: Unit.inch));
    });

    test('a magnitude written as a whole number reads as the same bare '
        'number', () {
      expect(
        TapeValueCodec.quantityFrom({
          'dim': 'scalar',
          'value': 2,
          'pads': false,
        }, 'value'),
        const Scalar(2),
      );
    });

    test('a bare number and an angle carry no unit', () {
      expect(TapeValueCodec.quantity(const Scalar(2)), {
        'dim': 'scalar',
        'value': 2.0,
        'decimals': null,
        'pads': false,
      });
      expect(TapeValueCodec.quantity(const Angle(90)), {
        'dim': 'angle',
        'value': 90.0,
        'spelling': 'degrees',
      });
    });

    test('a quantity that cannot be read names where, as a format error', () {
      final bad = <Object?>[
        null,
        'length',
        {'dim': 'cubit', 'value': 1},
        {'dim': 'length', 'inches': '1/0', 'unit': 'foot'},
        {'dim': 'length', 'inches': '12', 'unit': 'foot'},
        {'dim': 'length', 'inches': 'a/b', 'unit': 'foot'},
        {'dim': 'length', 'inches': '12/-1', 'unit': 'foot'},
        {'dim': 'length', 'inches': '1/2/3', 'unit': 'foot'},
        {'dim': 'length', 'inches': '12345678901234567890/1', 'unit': 'foot'},
        {'dim': 'length', 'inches': '12/1', 'unit': 'cubit'},
        {'dim': 'length', 'inches': '12/1'},
        {'dim': 'area', 'value': 'wide', 'unit': 'foot'},
        {'dim': 'volume', 'value': 1, 'unit': 7},
        {'dim': 'weight', 'value': null, 'unit': 'ton'},
        {'dim': 'angle', 'value': 1, 'spelling': 'radians'},
        {'dim': 'scalar', 'value': 1, 'decimals': 'two', 'pads': false},
        {'dim': 'scalar', 'value': 1, 'pads': 'no'},
      ];
      for (final json in bad) {
        expect(
          () => TapeValueCodec.quantityFrom(json, 'chips[0].value'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              startsWith('Unreadable tape: chips[0].value'),
            ),
          ),
          reason: '$json',
        );
      }
    });
  });

  group('TapeValueCodec entries', () {
    test('an entry round-trips token for token: digits, a fraction, a unit '
        'with its power, an angle\'s parts and a re-spelling', () {
      const entries = [
        EntryBuffer(),
        EntryBuffer([Token(digits: '22', unit: Unit.foot)]),
        EntryBuffer([
          Token(digits: '18', unit: Unit.foot),
          Token(digits: '8', unit: Unit.inch),
        ]),
        EntryBuffer([Token(digits: '3', denominator: '16', unit: Unit.inch)]),
        EntryBuffer([Token(digits: '410.67', unit: Unit.foot, power: 2)]),
        EntryBuffer([Token(digits: '960', unit: Unit.yard, power: 3)]),
        EntryBuffer([Token(digits: '38', minutes: '30', seconds: '00')]),
        EntryBuffer([Token(digits: '38', minutes: '7')]),
        EntryBuffer([
          Token(digits: '6.222', unit: Unit.yard, typedAs: '18ft 8in'),
        ]),
        EntryBuffer([Token(digits: '0.65')]),
      ];
      for (final entry in entries) {
        final json = TapeValueCodec.entry(entry);
        expect(
          TapeValueCodec.entryFrom(json, 'tokens'),
          entry,
          reason: '$entry',
        );
      }
    });

    test('a token is written field for field, with its power', () {
      expect(
        TapeValueCodec.entry(
          const EntryBuffer([
            Token(digits: '3', denominator: '16', unit: Unit.inch, power: 1),
          ]),
        ),
        [
          {
            'n': '3',
            'd': '16',
            'unit': 'inch',
            'p': 1,
            'm': null,
            's': null,
            't': null,
          },
        ],
      );
    });

    test('a token written without a power reads with the power of one', () {
      expect(
        TapeValueCodec.entryFrom([
          {'n': '22', 'unit': 'foot'},
        ], 'tokens'),
        const EntryBuffer([Token(digits: '22', unit: Unit.foot)]),
      );
      expect(
        TapeValueCodec.entryFrom([
          {'n': '22', 'unit': 'foot'},
        ], 'tokens').tokens.single.power,
        1,
      );
    });

    test('an entry that cannot be read names where, as a format error', () {
      final bad = <Object?>[
        null,
        {},
        [7],
        [
          {'d': '16'},
        ],
        [
          {'n': 7},
        ],
        [
          {'n': '3', 'unit': 'cubit'},
        ],
        [
          {'n': '3', 'p': 'two'},
        ],
        [
          {'n': '3', 'm': 30},
        ],
      ];
      for (final json in bad) {
        expect(
          () => TapeValueCodec.entryFrom(json, 'chips[1].tokens'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              startsWith('Unreadable tape: chips[1].tokens'),
            ),
          ),
          reason: '$json',
        );
      }
    });
  });
}

import 'package:construculator/features/calculator/data/models/recent_row_mapper.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecentRowMapper', () {
    const values = <Quantity>[
      Length(14336, unit: Unit.footInch),
      Length(2520, unit: Unit.metre),
      Area(589824.0 * 180, unit: Unit.foot),
      Volume(136.8833333, unit: Unit.boardFoot),
      Weight(7800, unit: Unit.ton),
      Angle(26.57),
      Scalar(0.013),
    ];

    test('every dimension survives the round trip through a row', () {
      for (final value in values) {
        final row = RecentRowMapper.toRow('Length', 0, value);
        expect(RecentRowMapper.quantityFromRow(row), value, reason: '$value');
      }
    });

    test('writes the drawer, the position and the dimension by name', () {
      final row = RecentRowMapper.toRow('angle', 2, const Angle(38.05));
      expect(row['drawer'], 'angle');
      expect(row['position'], 2);
      expect(row['dimension'], 'angle');
      expect(row['magnitude'], 38.05);
      expect(row['unit'], '');
    });

    test('a length keeps its whole ticks through the real column', () {
      final row = RecentRowMapper.toRow(
        'Width',
        0,
        const Length(772, unit: Unit.inch),
      );
      expect(row['magnitude'], 772.0);
      expect(
        RecentRowMapper.quantityFromRow({...row, 'magnitude': 772.0}),
        const Length(772, unit: Unit.inch),
      );
    });

    test('an unreadable row is a FormatException', () {
      expect(
        () => RecentRowMapper.quantityFromRow({
          'dimension': 'length',
          'magnitude': 'x',
          'unit': 'foot',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => RecentRowMapper.quantityFromRow({
          'dimension': 'length',
          'magnitude': 1.0,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

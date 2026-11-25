import 'package:construculator/libraries/calculation/data/models/calculation_session_dto.dart';
import 'package:construculator/libraries/calculation/domain/entities/calculation_session.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final banked = DateTime.utc(2026, 11, 25, 9, 30);
  final later = DateTime.utc(2026, 11, 25, 10);

  CalculationSession session({Quantity? result, String? resultText}) =>
      CalculationSession(
        id: 'session-1',
        creatorUserId: 'user-1',
        title: 'Drywall for the hall',
        resultText: resultText,
        result: result,
        createdAt: banked,
        updatedAt: later,
        lastCalculationAt: later,
      );

  group('CalculationSessionDto', () {
    test('a session with an area result round-trips through its row, the '
        'result laid flat as dimension, magnitude and unit', () {
      final area = Area(410.67 * 4096 * 144, unit: Unit.foot);
      final dto = CalculationSessionDto.fromEntity(
        session(result: area, resultText: '410.67ft²'),
      );
      final row = dto.toRow();
      expect(row, {
        'id': 'session-1',
        'creator_user_id': 'user-1',
        'title': 'Drywall for the hall',
        'result_text': '410.67ft²',
        'result_value': area.squareTicks,
        'result_dimension': 'area',
        'result_unit': 'foot',
        'created_at': '2026-11-25T09:30:00.000Z',
        'updated_at': '2026-11-25T10:00:00.000Z',
        'last_calculation_at': '2026-11-25T10:00:00.000Z',
      });
      final read = CalculationSessionDto.fromRow(row);
      expect(read, dto);
      expect(read.toEntity(), session(result: area, resultText: '410.67ft²'));
    });

    test('every dimension round-trips: a length keeps its fraction of a '
        'tick, an angle and a bare number carry no unit', () {
      final values = <Quantity>[
        Length.computed(18.38 * Length.ticksPerFoot, unit: Unit.foot),
        const Length(1536, unit: Unit.millimetre),
        const Volume(960, unit: Unit.yard),
        const Weight(292000, unit: Unit.ton),
        const Angle(38.5),
        const Scalar(13.25),
        const Scalar(0),
        const Length(0, unit: Unit.foot),
        const Length(-1260, unit: Unit.centimetre),
        const Angle(-0.5),
      ];
      for (final value in values) {
        final row = CalculationSessionDto.fromEntity(
          session(result: value),
        ).toRow();
        final read = CalculationSessionDto.fromRow(row).result;
        expect(read, value, reason: '$value');
        expect(read!.dimension, value.dimension);
        if (value is Angle || value is Scalar) {
          expect(row['result_unit'], isNull, reason: '$value');
        }
      }
    });

    test('a tape banked without a result has a null result and null text', () {
      final row = CalculationSessionDto.fromEntity(session()).toRow();
      expect(row['result_value'], isNull);
      expect(row['result_dimension'], isNull);
      expect(row['result_unit'], isNull);
      expect(row['result_text'], isNull);
      final read = CalculationSessionDto.fromRow(row);
      expect(read.result, isNull);
      expect(read.toEntity(), session());
    });

    test('a magnitude SQLite hands back as a whole number reads as the same '
        'bare number', () {
      final row = CalculationSessionDto.fromEntity(
        session(result: const Scalar(2), resultText: '2'),
      ).toRow();
      final read = CalculationSessionDto.fromRow({...row, 'result_value': 2});
      expect(read.result, const Scalar(2));
    });

    test('a row with a magnitude but no dimension reads no result: the '
        'orphan value is ignored', () {
      final row = CalculationSessionDto.fromEntity(session()).toRow();
      final read = CalculationSessionDto.fromRow({
        ...row,
        'result_value': 5.0,
        'result_unit': 'foot',
      });
      expect(read.result, isNull);
      expect(read.toEntity(), session());
    });

    test('timestamps are written in UTC whatever zone they were made in', () {
      final local = DateTime(2026, 11, 25, 12, 30);
      final row = CalculationSessionDto(
        id: 's',
        creatorUserId: 'u',
        createdAt: local,
        updatedAt: local,
        lastCalculationAt: local,
      ).toRow();
      expect(row['created_at'], local.toUtc().toIso8601String());
      expect(
        CalculationSessionDto.fromRow(row).createdAt.isAtSameMomentAs(local),
        isTrue,
      );
    });

    test('a row a column of which cannot be read is a format error', () {
      final good = CalculationSessionDto.fromEntity(
        session(result: const Scalar(2), resultText: '2'),
      ).toRow();
      final bad = <Map<String, Object?>>[
        {...good, 'id': null},
        {...good, 'creator_user_id': 7},
        {...good, 'title': 7},
        {...good, 'created_at': 'yesterday'},
        {...good, 'last_calculation_at': null},
        {...good, 'result_value': 'two'},
        {...good, 'result_dimension': 'cubits'},
        {...good, 'result_dimension': 'length', 'result_unit': 'cubit'},
        {...good, 'result_dimension': 'area', 'result_unit': null},
      ];
      for (final row in bad) {
        expect(
          () => CalculationSessionDto.fromRow(row),
          throwsFormatException,
          reason: '$row',
        );
      }
    });
  });
}

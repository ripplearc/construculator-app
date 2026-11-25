import 'package:construculator/libraries/calculation/data/models/calculation_tape_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final written = DateTime.utc(2026, 11, 25, 9, 30);

  group('CalculationTapeDto', () {
    test('a tape round-trips through its row with its JSON and version', () {
      final dto = CalculationTapeDto(
        id: 'tape-1',
        sessionId: 'session-1',
        computation: '{"schema_version":1,"chips":[]}',
        schemaVersion: 1,
        createdAt: written,
      );
      final row = dto.toRow();
      expect(row, {
        'id': 'tape-1',
        'session_id': 'session-1',
        'computation': '{"schema_version":1,"chips":[]}',
        'schema_version': 1,
        'created_at': '2026-11-25T09:30:00.000Z',
      });
      expect(CalculationTapeDto.fromRow(row), dto);
    });

    test('a version of zero or the largest whole number SQLite holds '
        'round-trips: the codec, not the row, judges the version', () {
      for (final version in [0, 9223372036854775807]) {
        final dto = CalculationTapeDto(
          id: 'tape-1',
          sessionId: 'session-1',
          computation: '{"schema_version":$version,"chips":[]}',
          schemaVersion: version,
          createdAt: written,
        );
        final row = dto.toRow();
        expect(row['schema_version'], version);
        expect(CalculationTapeDto.fromRow(row), dto, reason: '$version');
      }
    });

    test('a row a column of which cannot be read is a format error', () {
      final good = CalculationTapeDto(
        id: 'tape-1',
        sessionId: 'session-1',
        computation: '{}',
        schemaVersion: 1,
        createdAt: written,
      ).toRow();
      final bad = <Map<String, Object?>>[
        {...good, 'id': null},
        {...good, 'session_id': 3},
        {...good, 'computation': null},
        {...good, 'schema_version': '1'},
        {...good, 'schema_version': 1.5},
        {...good, 'created_at': 'now'},
      ];
      for (final row in bad) {
        expect(
          () => CalculationTapeDto.fromRow(row),
          throwsFormatException,
          reason: '$row',
        );
      }
    });
  });
}

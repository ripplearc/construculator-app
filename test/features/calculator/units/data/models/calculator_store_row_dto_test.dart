import 'package:construculator/features/calculator/data/models/calculator_store_row_dto.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 2, 9);
  final updatedAt = DateTime.utc(2026, 11, 2, 10);
  final row = CalculatorStoreRowDto(
    id: 'row-1',
    userId: 'user-1',
    storeKind: CalculatorStoreKind.density,
    values: const {'seed': 'density_concrete', 'name': 'concrete'},
    unitSystem: MeasurementSystem.imperial,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  group('CalculatorStoreKind', () {
    test('spells the seven server labels and reads them back', () {
      expect(CalculatorStoreKind.values.map((k) => k.wire), [
        'sheet_size',
        'masonry_piece',
        'footing_section',
        'on_centre_spacing',
        'fence_config',
        'waste',
        'density',
      ]);
      for (final kind in CalculatorStoreKind.values) {
        expect(CalculatorStoreKind.fromWire(kind.wire), kind);
      }
    });

    test(
      'a label this build does not know, such as rate, is a format error',
      () {
        expect(
          () => CalculatorStoreKind.fromWire('rate'),
          throwsFormatException,
        );
      },
    );
  });

  group('CalculatorStoreRowDto', () {
    test('writes its columns with values as JSON text and UTC stamps', () {
      expect(row.toColumns(), {
        'user_id': 'user-1',
        'store_kind': 'density',
        'values': '{"seed":"density_concrete","name":"concrete"}',
        'unit_system': 'imperial',
        'created_at': '2026-11-02T09:00:00.000Z',
        'updated_at': '2026-11-02T10:00:00.000Z',
        'deleted_at': null,
      });
      expect(row.seed, 'density_concrete');
      expect(row.isDeleted, isFalse);
    });

    test('reads a row back equal to itself, deleted or live', () {
      expect(
        CalculatorStoreRowDto.fromRow({'id': 'row-1', ...row.toColumns()}),
        row,
      );
      final deleted = row.copyWith(deletedAt: updatedAt);
      expect(deleted.isDeleted, isTrue);
      expect(
        CalculatorStoreRowDto.fromRow({'id': 'row-1', ...deleted.toColumns()}),
        deleted,
      );
      expect(deleted.copyWith(clearDeletedAt: true).deletedAt, isNull);
    });

    test('a stamp from the server in another spelling is still read', () {
      final synced = CalculatorStoreRowDto.fromRow({
        ...row.toColumns(),
        'id': 'row-1',
        'created_at': '2026-11-02 09:00:00+00',
      });
      expect(synced.createdAt, createdAt);
    });

    test('a row without a seed key is one the user added', () {
      final added = row.copyWith(values: const {'name': 'slag'});
      expect(added.seed, isNull);
    });

    test('a row that cannot be read is a format error', () {
      final columns = {'id': 'row-1', ...row.toColumns()};
      expect(
        () => CalculatorStoreRowDto.fromRow({...columns, 'values': '[1, 2]'}),
        throwsFormatException,
      );
      expect(
        () => CalculatorStoreRowDto.fromRow({...columns, 'store_kind': 'rate'}),
        throwsFormatException,
      );
      expect(
        () => CalculatorStoreRowDto.fromRow({...columns, 'created_at': 'soon'}),
        throwsFormatException,
      );
      expect(
        () => CalculatorStoreRowDto.fromRow({...columns, 'user_id': null}),
        throwsFormatException,
      );
      expect(
        () => CalculatorStoreRowDto.fromRow({
          ...columns,
          'unit_system': 'cubits',
        }),
        throwsArgumentError,
      );
    });
  });
}

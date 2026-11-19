import 'package:construculator/libraries/powersync/testing/fake_cost_item_refusal_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeCostItemRefusalDatabase', () {
    const selectCostItem = 'SELECT * FROM cost_items WHERE id = ?';
    const insertRefusal =
        'INSERT OR REPLACE INTO cost_item_refusals '
        '(id, estimate_id, line, reason, refused_at) VALUES (?, ?, ?, ?, ?)';
    const deleteRefusal = 'DELETE FROM cost_item_refusals WHERE id = ?';

    late FakeCostItemRefusalDatabase database;

    setUp(() {
      database = FakeCostItemRefusalDatabase();
    });

    group('getOptional', () {
      test('returns the seeded cost line by id', () async {
        database.seedCostItem({'id': 'line-1', 'item_name': 'Plywood'});

        final row = await database.getOptional(selectCostItem, ['line-1']);

        expect(row!['item_name'], 'Plywood');
      });

      test('returns null for an id that was not seeded', () async {
        final row = await database.getOptional(selectCostItem, ['line-2']);

        expect(row, isNull);
      });

      test('rejects a statement other than the one cost line read', () {
        expect(
          () => database.getOptional('SELECT * FROM estimates'),
          throwsStateError,
        );
      });

      test('throws the configured statementError', () {
        final error = Exception('disk full');
        database.statementError = error;

        expect(
          () => database.getOptional(selectCostItem, ['line-1']),
          throwsA(same(error)),
        );
      });
    });

    group('execute', () {
      test('records a refusal under the id of its cost line', () async {
        await database.execute(insertRefusal, [
          'line-1',
          'estimate-1',
          '{"id":"line-1"}',
          '42501',
          '2026-11-18T09:30:00.000Z',
        ]);

        expect(database.refusals['line-1'], {
          'id': 'line-1',
          'estimate_id': 'estimate-1',
          'line': '{"id":"line-1"}',
          'reason': '42501',
          'refused_at': '2026-11-18T09:30:00.000Z',
        });
      });

      test('replaces the refusal already recorded for the same line', () async {
        await database.execute(insertRefusal, [
          'line-1',
          'estimate-1',
          '{}',
          '42501',
          'first',
        ]);
        await database.execute(insertRefusal, [
          'line-1',
          'estimate-1',
          '{}',
          'PGRST116',
          'second',
        ]);

        expect(database.refusals.length, 1);
        expect(database.refusals['line-1']!['reason'], 'PGRST116');
      });

      test('deletes the refusal of one line and keeps the others', () async {
        for (final id in ['line-1', 'line-2']) {
          await database.execute(insertRefusal, [
            id,
            'estimate-1',
            '{}',
            '42501',
            'now',
          ]);
        }

        await database.execute(deleteRefusal, ['line-1']);

        expect(database.refusals.keys, ['line-2']);
      });

      test('rejects an insert that names a column the table lacks', () {
        expect(
          () => database.execute(
            'INSERT OR REPLACE INTO cost_item_refusals (id, nope) '
            'VALUES (?, ?)',
            ['line-1', 'x'],
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('no column named nope'),
            ),
          ),
        );
      });

      test('rejects an insert that lists no columns', () {
        expect(
          () => database.execute(
            'INSERT OR REPLACE INTO cost_item_refusals DEFAULT VALUES',
          ),
          throwsStateError,
        );
      });

      test('rejects an insert whose parameters do not match the columns', () {
        expect(
          () => database.execute(insertRefusal, ['line-1']),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('differ in length'),
            ),
          ),
        );
      });

      test('rejects a statement it does not emulate', () {
        expect(
          () => database.execute('DELETE FROM cost_items WHERE id = ?', ['a']),
          throwsStateError,
        );
      });

      test('throws the configured statementError', () {
        final error = Exception('disk full');
        database.statementError = error;

        expect(
          () => database.execute(deleteRefusal, ['line-1']),
          throwsA(same(error)),
        );
      });

      test('does not let a caller change the recorded refusals', () async {
        await database.execute(insertRefusal, [
          'line-1',
          'estimate-1',
          '{}',
          '42501',
          'now',
        ]);

        database.refusals['line-1']!['reason'] = 'changed';

        expect(database.refusals['line-1']!['reason'], '42501');
      });
    });

    group('reset', () {
      test(
        'clears the cost lines, the refusals and the statementError',
        () async {
          database.seedCostItem({'id': 'line-1'});
          await database.execute(insertRefusal, [
            'line-1',
            'estimate-1',
            '{}',
            '42501',
            'now',
          ]);
          database.statementError = Exception('disk full');

          database.reset();

          expect(database.statementError, isNull);
          expect(database.refusals, isEmpty);
          expect(
            await database.getOptional(selectCostItem, ['line-1']),
            isNull,
          );
        },
      );
    });
  });
}

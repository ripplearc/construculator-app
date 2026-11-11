import 'package:async/async.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimates_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const projectSql =
      'SELECT * FROM cost_estimates WHERE project_id = ? ORDER BY created_at DESC LIMIT ?';
  const ascendingSql =
      'SELECT * FROM cost_estimates WHERE project_id = ? ORDER BY created_at ASC';

  Map<String, dynamic> row(
    String id, {
    String projectId = 'project-1',
    String createdAt = '2026-01-01T00:00:00.000Z',
    String name = 'Estimate',
    bool isLocked = false,
  }) => {
    'id': id,
    'project_id': projectId,
    'created_at': createdAt,
    'estimate_name': name,
    'is_locked': isLocked,
  };

  List<Object?> ids(List<Map<String, dynamic>> rows) =>
      rows.map((r) => r['id']).toList();

  late FakeCostEstimatesDatabase database;

  setUp(() {
    database = FakeCostEstimatesDatabase();
  });

  tearDown(() {
    database.dispose();
  });

  group('FakeCostEstimatesDatabase', () {
    test('returns only the rows of the requested project', () async {
      database.seedRows([row('a'), row('b', projectId: 'project-2')]);

      final rows = await database
          .watch(projectSql, parameters: ['project-1', 5])
          .first;

      expect(ids(rows), equals(['a']));
    });

    test('sorts by the column and direction in the SQL', () async {
      database.seedRows([
        row('old', createdAt: '2026-01-01T00:00:00.000Z'),
        row('new', createdAt: '2026-01-02T00:00:00.000Z'),
      ]);

      final newestFirst = await database
          .watch(projectSql, parameters: ['project-1', 5])
          .first;
      final oldestFirst = await database
          .watch(ascendingSql, parameters: ['project-1'])
          .first;

      expect(ids(newestFirst), equals(['new', 'old']));
      expect(ids(oldestFirst), equals(['old', 'new']));
    });

    test('cuts the rows to the limit parameter', () async {
      database.seedRows([
        row('old', createdAt: '2026-01-01T00:00:00.000Z'),
        row('new', createdAt: '2026-01-02T00:00:00.000Z'),
      ]);

      final rows = await database
          .watch(projectSql, parameters: ['project-1', 1])
          .first;

      expect(ids(rows), equals(['new']));
    });

    test('stores a locked row as 1 and an unlocked row as 0', () async {
      database.seedRows([row('a', isLocked: true), row('b')]);

      final rows = await database
          .watch(ascendingSql, parameters: ['project-1'])
          .first;

      expect(rows.map((r) => r['is_locked']).toList(), equals([1, 0]));
    });

    test('emits again when a row is replaced or removed', () async {
      database.seedRows([row('a', name: 'Before')]);
      // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
      final queue = StreamQueue(
        database.watch(ascendingSql, parameters: ['project-1']),
      );
      await queue.next;

      database.replaceRow(row('a', name: 'After'));
      final replaced = await queue.next;
      database.removeRow('a');
      final removed = await queue.next;

      expect(replaced.single['estimate_name'], equals('After'));
      expect(removed, isEmpty);
      await queue.cancel();
    });

    test('fails a new watch with watchError', () async {
      database.watchError = StateError('phone copy unavailable');

      await expectLater(
        database.watch(ascendingSql, parameters: ['project-1']),
        emitsError(isA<StateError>()),
      );
    });

    test('refuses SQL that has no ORDER BY clause', () {
      expect(
        () => database.watch(
          'SELECT * FROM cost_estimates',
          parameters: ['project-1'],
        ),
        throwsArgumentError,
      );
    });

    test('reset removes the rows and clears watchError', () async {
      database.seedRows([row('a')]);
      database.watchError = StateError('phone copy unavailable');

      database.reset();
      final rows = await database
          .watch(ascendingSql, parameters: ['project-1'])
          .first;

      expect(rows, isEmpty);
    });

    test('records each watch call', () {
      database.watch(ascendingSql, parameters: ['project-1']);

      expect(database.watchCalls.single.sql, equals(ascendingSql));
    });
    group('writes', () {
      const byIdSql = 'SELECT * FROM cost_estimates WHERE id = ? LIMIT 1';

      test('an INSERT adds the row and sends it to an open watch', () async {
        // ignore: no_direct_instantiation, reason: StreamQueue is a test utility from package:async
        final queue = StreamQueue(
          database.watch(ascendingSql, parameters: ['project-1']),
        );
        expect(ids(await queue.next), isEmpty);

        await database.execute(
          'INSERT INTO cost_estimates (id, project_id, created_at, is_locked) '
          'VALUES (?, ?, ?, ?)',
          ['new', 'project-1', '2026-01-01T00:00:00.000Z', 0],
        );

        final shown = await queue.next;
        expect(ids(shown), ['new']);
        expect(shown.single['is_locked'], 0);
        await queue.cancel();
      });

      test('an UPDATE of one column changes only that column', () async {
        database.seedRows([row('a', name: 'Old')]);

        await database.execute(
          'UPDATE cost_estimates SET estimate_name = ? WHERE id = ?',
          ['New', 'a'],
        );

        final stored = (await database.getAll(byIdSql, ['a'])).single;
        expect(stored['estimate_name'], 'New');
        expect(stored['project_id'], 'project-1');
      });

      test('a DELETE removes the row', () async {
        database.seedRows([row('a'), row('b')]);

        await database.execute('DELETE FROM cost_estimates WHERE id = ?', [
          'a',
        ]);

        expect(await database.getAll(byIdSql, ['a']), isEmpty);
        expect(await database.getAll(byIdSql, ['b']), hasLength(1));
      });

      test('a write is recorded and fails with executeError', () async {
        database.executeError = Exception('disk full');

        await expectLater(
          database.execute('DELETE FROM cost_estimates WHERE id = ?', ['a']),
          throwsException,
        );
        expect(database.executeCalls, hasLength(1));
      });

      test(
        'a read by id returns a copy, so a caller cannot edit the row',
        () async {
          database.seedRows([row('a', name: 'Old')]);

          (await database.getAll(byIdSql, ['a'])).single['estimate_name'] = 'X';

          final stored = (await database.getAll(byIdSql, ['a'])).single;
          expect(stored['estimate_name'], 'Old');
        },
      );
    });
  });
}

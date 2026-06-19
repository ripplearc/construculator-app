import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakePowerSyncDatabaseWrapper', () {
    late FakePowerSyncDatabaseWrapper fakeWrapper;

    setUp(() {
      fakeWrapper = FakePowerSyncDatabaseWrapper();
    });

    tearDown(() {
      fakeWrapper.dispose();
    });

    group('getAll', () {
      test('returns an empty list when nothing is stubbed', () async {
        final rows = await fakeWrapper.getAll('SELECT * FROM projects');

        expect(rows, isEmpty);
      });

      test('returns the stubbed rows for the matching sql', () async {
        const sql = 'SELECT * FROM projects WHERE id = ?';
        fakeWrapper.stubGetAll(sql, [
          {'id': 'p1', 'project_name': 'Foundation'},
        ]);

        final rows = await fakeWrapper.getAll(sql, ['p1']);

        expect(rows, hasLength(1));
        expect(rows.single['id'], 'p1');
      });

      test('records the sql and parameters of each call', () async {
        await fakeWrapper.getAll('SELECT 1', ['a', 2]);

        expect(fakeWrapper.getAllCalls, hasLength(1));
        expect(fakeWrapper.getAllCalls.single.sql, 'SELECT 1');
        expect(fakeWrapper.getAllCalls.single.parameters, ['a', 2]);
      });

      test('throws the configured error and still records the call', () async {
        final error = Exception('read failed');
        fakeWrapper.getAllError = error;

        await expectLater(
          fakeWrapper.getAll('SELECT 1'),
          throwsA(same(error)),
        );
        expect(fakeWrapper.getAllCalls, hasLength(1));
      });
    });

    group('execute', () {
      test('records the sql and parameters of each call', () async {
        await fakeWrapper.execute('DELETE FROM projects WHERE id = ?', ['p1']);

        expect(fakeWrapper.executeCalls, hasLength(1));
        expect(
          fakeWrapper.executeCalls.single.sql,
          'DELETE FROM projects WHERE id = ?',
        );
        expect(fakeWrapper.executeCalls.single.parameters, ['p1']);
      });

      test('throws the configured error and still records the call', () async {
        final error = Exception('write failed');
        fakeWrapper.executeError = error;

        await expectLater(
          fakeWrapper.execute('DELETE FROM projects'),
          throwsA(same(error)),
        );
        expect(fakeWrapper.executeCalls, hasLength(1));
      });
    });

    group('watch', () {
      const sql = 'SELECT * FROM projects';

      test('records the sql and parameters of each call', () {
        fakeWrapper.watch(sql, parameters: ['p1']);

        expect(fakeWrapper.watchCalls, hasLength(1));
        expect(fakeWrapper.watchCalls.single.sql, sql);
        expect(fakeWrapper.watchCalls.single.parameters, ['p1']);
      });

      test('emits rows passed to emitWatch to active listeners', () async {
        final emission = expectLater(
          fakeWrapper.watch(sql),
          emits([
            {'id': 'p1'},
          ]),
        );

        fakeWrapper.emitWatch(sql, [
          {'id': 'p1'},
        ]);

        await emission;
      });

      test('replays the latest emitted value to a later listener', () {
        fakeWrapper.emitWatch(sql, [
          {'id': 'p1'},
        ]);

        return expectLater(
          fakeWrapper.watch(sql),
          emits([
            {'id': 'p1'},
          ]),
        );
      });

      test('forwards errors passed to emitWatchError', () async {
        final error = Exception('stream failed');

        final emission = expectLater(
          fakeWrapper.watch(sql),
          emitsError(same(error)),
        );

        fakeWrapper.emitWatchError(sql, error);

        await emission;
      });
    });

    group('syncStream', () {
      test('records each activation by stream name', () async {
        await fakeWrapper.syncStream('user_cost_estimates');

        expect(fakeWrapper.syncStreamCalls, ['user_cost_estimates']);
      });

      test('returned handle records its release on unsubscribe', () async {
        final handle = await fakeWrapper.syncStream('user_cost_estimates');

        expect(fakeWrapper.syncStreamUnsubscribes, isEmpty);

        handle.unsubscribe();

        expect(fakeWrapper.syncStreamUnsubscribes, ['user_cost_estimates']);
      });

      test('throws the configured error and still records the call', () async {
        final error = Exception('activation failed');
        fakeWrapper.syncStreamError = error;

        await expectLater(
          fakeWrapper.syncStream('user_cost_estimates'),
          throwsA(same(error)),
        );
        expect(fakeWrapper.syncStreamCalls, ['user_cost_estimates']);
      });
    });

    group('reset', () {
      test('clears recorded calls, stubs, errors, and watch seeds', () async {
        const sql = 'SELECT * FROM projects';
        fakeWrapper.stubGetAll(sql, [
          {'id': 'p1'},
        ]);
        fakeWrapper.emitWatch(sql, [
          {'id': 'p1'},
        ]);
        await fakeWrapper.getAll(sql);
        await fakeWrapper.execute('DELETE FROM projects');
        final handle = await fakeWrapper.syncStream('user_cost_estimates');
        handle.unsubscribe();
        fakeWrapper.getAllError = Exception('x');
        fakeWrapper.executeError = Exception('y');
        fakeWrapper.syncStreamError = Exception('z');

        fakeWrapper.reset();

        expect(fakeWrapper.getAllCalls, isEmpty);
        expect(fakeWrapper.executeCalls, isEmpty);
        expect(fakeWrapper.watchCalls, isEmpty);
        expect(fakeWrapper.syncStreamCalls, isEmpty);
        expect(fakeWrapper.syncStreamUnsubscribes, isEmpty);
        expect(fakeWrapper.getAllError, isNull);
        expect(fakeWrapper.executeError, isNull);
        expect(fakeWrapper.syncStreamError, isNull);
        expect(await fakeWrapper.getAll(sql), isEmpty);

        // The cleared seed must not replay: the first value a new listener sees
        // is the post-reset emission, not the pre-reset 'p1'.
        final emission = expectLater(
          fakeWrapper.watch(sql),
          emits([
            {'id': 'p2'},
          ]),
        );
        fakeWrapper.emitWatch(sql, [
          {'id': 'p2'},
        ]);
        await emission;
      });
    });
  });
}

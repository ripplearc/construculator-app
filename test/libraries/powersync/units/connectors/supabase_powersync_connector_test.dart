import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/powersync/data/connectors/supabase_powersync_connector.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';

void main() {
  late SupabasePowerSyncConnector connector;
  late FakeSupabaseWrapper fakeSupabase;
  late FakeEnvLoader fakeEnvLoader;
  late FakePowerSyncDatabase fakeDatabase;

  setUp(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    fakeEnvLoader = FakeEnvLoader();
    fakeDatabase = FakePowerSyncDatabase();
    connector = SupabasePowerSyncConnector(
      supabaseWrapper: fakeSupabase,
      envLoader: fakeEnvLoader,
    );
  });

  void signIn({String id = 'user-1', String email = 'user@example.com'}) {
    fakeSupabase.setCurrentUser(
      FakeUser(id: id, email: email, createdAt: '2000-01-01T00:00:00.000Z'),
    );
  }

  group('SupabasePowerSyncConnector', () {
    group('fetchCredentials', () {
      test('returns null when POWERSYNC_URL is not configured', () async {
        signIn();

        expect(await connector.fetchCredentials(), isNull);
      });

      test('returns null when POWERSYNC_URL is empty', () async {
        fakeEnvLoader.setEnvVar('POWERSYNC_URL', '');
        signIn();

        expect(await connector.fetchCredentials(), isNull);
      });

      test('returns null when user is not authenticated', () async {
        fakeEnvLoader.setEnvVar('POWERSYNC_URL', 'https://ps.example.com');

        expect(await connector.fetchCredentials(), isNull);
      });

      test('returns null when refreshSession throws', () async {
        fakeEnvLoader.setEnvVar('POWERSYNC_URL', 'https://ps.example.com');
        signIn();
        fakeSupabase.shouldThrowOnRefreshSession = true;

        expect(await connector.fetchCredentials(), isNull);
      });

      test('returns credentials with correct endpoint and access token', () async {
        const url = 'https://ps.example.com';
        fakeEnvLoader.setEnvVar('POWERSYNC_URL', url);
        signIn(id: 'user-1');

        final credentials = await connector.fetchCredentials();

        expect(credentials, isNotNull);
        expect(credentials!.endpoint, equals(url));
        expect(credentials.token, equals('fake-access-token-user-1'));
      });

      test('refreshes the session before building credentials', () async {
        fakeEnvLoader.setEnvVar('POWERSYNC_URL', 'https://ps.example.com');
        signIn();

        await connector.fetchCredentials();

        expect(fakeSupabase.getMethodCallsFor('refreshSession'), hasLength(1));
      });
    });

    group('uploadData', () {
      test('returns early when no transaction is pending', () async {
        await connector.uploadData(fakeDatabase);

        expect(fakeSupabase.getMethodCalls(), isEmpty);
      });

      test('PUT dispatches upsert with correct table, data, and onConflict', () async {
        fakeDatabase.setNextTransaction(FakeCrudTransaction([
          CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, {
            'id': 'proj-1',
            'name': 'Test',
          }),
        ]));

        await connector.uploadData(fakeDatabase);

        final calls = fakeSupabase.getMethodCallsFor('upsert');
        expect(calls, hasLength(1));
        expect(calls.first['table'], equals('projects'));
        expect(calls.first['data'], containsPair('id', 'proj-1'));
        expect(calls.first['onConflict'], equals('id'));
      });

      test('PATCH dispatches update with id as filter', () async {
        fakeDatabase.setNextTransaction(FakeCrudTransaction([
          CrudEntry(1, UpdateType.patch, 'projects', 'proj-1', null, {
            'name': 'Updated',
          }),
        ]));

        await connector.uploadData(fakeDatabase);

        final calls = fakeSupabase.getMethodCallsFor('update');
        expect(calls, hasLength(1));
        expect(calls.first['table'], equals('projects'));
        expect(calls.first['filterColumn'], equals('id'));
        expect(calls.first['filterValue'], equals('proj-1'));
        expect(calls.first['data'], containsPair('name', 'Updated'));
      });

      test('DELETE dispatches delete with id as filter', () async {
        fakeDatabase.setNextTransaction(FakeCrudTransaction([
          CrudEntry(1, UpdateType.delete, 'users', 'user-1', null, null),
        ]));

        await connector.uploadData(fakeDatabase);

        final calls = fakeSupabase.getMethodCallsFor('delete');
        expect(calls, hasLength(1));
        expect(calls.first['table'], equals('users'));
        expect(calls.first['filterColumn'], equals('id'));
        expect(calls.first['filterValue'], equals('user-1'));
      });

      test('completes the transaction after all operations succeed', () async {
        final transaction = FakeCrudTransaction([
          CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, {'id': 'proj-1'}),
        ]);
        fakeDatabase.setNextTransaction(transaction);

        await connector.uploadData(fakeDatabase);

        expect(transaction.isCompleted, isTrue);
      });

      test('processes all operations before completing the transaction', () async {
        final transaction = FakeCrudTransaction([
          CrudEntry(1, UpdateType.put, 'projects', 'a', null, {'id': 'a'}),
          CrudEntry(2, UpdateType.patch, 'projects', 'b', null, {'name': 'X'}),
          CrudEntry(3, UpdateType.delete, 'users', 'c', null, null),
        ]);
        fakeDatabase.setNextTransaction(transaction);

        await connector.uploadData(fakeDatabase);

        expect(fakeSupabase.getMethodCallsFor('upsert'), hasLength(1));
        expect(fakeSupabase.getMethodCallsFor('update'), hasLength(1));
        expect(fakeSupabase.getMethodCallsFor('delete'), hasLength(1));
        expect(transaction.isCompleted, isTrue);
      });

      test('PUT with null opData throws StateError', () async {
        fakeDatabase.setNextTransaction(FakeCrudTransaction([
          CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, null),
        ]));

        await expectLater(
          connector.uploadData(fakeDatabase),
          throwsA(isA<StateError>()),
        );
      });

      test('PATCH with null opData throws StateError', () async {
        fakeDatabase.setNextTransaction(FakeCrudTransaction([
          CrudEntry(1, UpdateType.patch, 'projects', 'proj-1', null, null),
        ]));

        await expectLater(
          connector.uploadData(fakeDatabase),
          throwsA(isA<StateError>()),
        );
      });

      group('error handling', () {
        test('RLS denial (42501) completes transaction without rethrowing', () async {
          fakeSupabase.shouldThrowOnUpsert = true;
          fakeSupabase.upsertExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabase.postgrestErrorCode = PostgresErrorCode.rlsViolation;
          fakeSupabase.upsertErrorMessage = 'permission denied for table projects';
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, {'id': 'proj-1'}),
          ]);
          fakeDatabase.setNextTransaction(transaction);

          await connector.uploadData(fakeDatabase);

          expect(transaction.isCompleted, isTrue);
        });

        test('non-RLS error is rethrown and transaction is not completed', () async {
          fakeSupabase.shouldThrowOnUpsert = true;
          final transaction = FakeCrudTransaction([
            CrudEntry(1, UpdateType.put, 'projects', 'proj-1', null, {'id': 'proj-1'}),
          ]);
          fakeDatabase.setNextTransaction(transaction);

          await expectLater(
            connector.uploadData(fakeDatabase),
            throwsException,
          );

          expect(transaction.isCompleted, isFalse);
        });
      });
    });
  });
}

import 'dart:convert';

import 'package:construculator/libraries/auth/check/start_up_recovery.dart';
import 'package:construculator/libraries/auth/queue/auth_event_queue.dart';
import 'package:construculator/libraries/powersync/models/local_only_table_registry.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/testing/fake_synced_data_service.dart';
import 'package:construculator/libraries/storage/local_data_delete_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:construculator/libraries/storage/testing/fake_owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

const _historyKey = 'calculator_history';
const _table = 'calculator_recents';

String _savedSessionOf(String userId) => json.encode({
  'access_token': 'fake-access-token-$userId',
  'token_type': 'bearer',
  'refresh_token': 'r-$userId',
  'user': {'id': userId},
});

class _Scenario {
  final String name;
  final OwnerRecord record;
  final String? sessionOfUser;
  final OwnerRecord? recordAfterDelete;

  const _Scenario(
    this.name,
    this.record,
    this.sessionOfUser,
    this.recordAfterDelete,
  );
}

void main() {
  late FakeOwnerRecordStorageService ownerRecords;
  late FakeSyncedDataService syncedData;
  late FakeStorageService userSpace;
  late FakePowerSyncDatabaseWrapper database;
  late FakeSupabaseWrapper wrapper;

  FakeUser user(String id) => FakeUser(id: id, createdAt: '2026-01-01');

  Future<void> startApp() async {
    // ignore: no_direct_instantiation, reason: unit test builds the queue from its settings
    final queue = AuthEventQueue(
      actionTimeout: const Duration(milliseconds: 50),
      onUnstoppedRun: () {},
    );
    // ignore: no_direct_instantiation, reason: the class under test is built from its fakes
    final recovery = StartUpRecovery(
      ownerRecords: ownerRecords,
      // ignore: no_direct_instantiation, reason: the real delete routine runs on fakes
      deleteService: LocalDataDeleteService(
        ownerRecords: ownerRecords,
        database: database,
        syncedData: syncedData,
        userSpace: userSpace,
        registrations: const [
          LocalOnlyTableRegistration(
            tableName: _table,
            policy: LocalOnlyTablePolicy.clearWhenUserChanges,
          ),
        ],
      ),
      wrapper: wrapper,
      clock: FakeClockImpl(DateTime.utc(2026, 11, 25, 9)),
      removalPollInterval: const Duration(milliseconds: 1),
    );
    Object? error;
    await queue.enqueueWithoutEvent(
      item: (run) async {
        try {
          await recovery.run(run);
        } catch (e) {
          error = e;
          rethrow;
        }
      },
      settle: (outcome) async {},
    );
    if (error != null) throw error!;
  }

  void disarmEveryCrash() {
    ownerRecords.shouldThrowOnWrite = false;
    ownerRecords.shouldThrowOnRemove = false;
    ownerRecords.afterWrite = null;
    database.executeError = null;
    userSpace.shouldThrowOnClear = false;
    syncedData.shouldThrowOnDelete = false;
    syncedData.afterDelete = null;
  }

  final crashes = <String, void Function()>{
    'before the flag is written': () => ownerRecords.shouldThrowOnWrite = true,
    'right after the flag is written': () =>
        ownerRecords.afterWrite = (_) => throw Exception('crash'),
    'while the local-only tables are cleared': () =>
        database.executeError = Exception('crash'),
    'while the user space is cleared': () =>
        userSpace.shouldThrowOnClear = true,
    'while the synced data is deleted': () =>
        syncedData.shouldThrowOnDelete = true,
    'right after the synced data is deleted': () =>
        syncedData.afterDelete = () => throw Exception('crash'),
    'while the owner record is finished': () => syncedData.afterDelete = () {
      ownerRecords.shouldThrowOnWrite = true;
      ownerRecords.shouldThrowOnRemove = true;
    },
  };

  final scenarios = <_Scenario>[
    _Scenario(
      'a logout',
      OwnerRecord(
        userId: 'user-a',
        pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
      ),
      null,
      null,
    ),
    _Scenario(
      'a logout whose session is still saved',
      OwnerRecord(
        userId: 'user-a',
        pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
      ),
      'user-a',
      null,
    ),
    _Scenario(
      'a user change',
      OwnerRecord(
        userId: 'user-a',
        pendingDelete: const PendingDelete.arrivalOf('user-b'),
      ),
      'user-b',
      OwnerRecord(userId: 'user-b'),
    ),
    _Scenario(
      'a sign-out with no owner record',
      OwnerRecord(pendingDelete: const PendingDelete.logoutOrNoOwnerRecord()),
      null,
      null,
    ),
  ];

  setUp(() {
    ownerRecords = FakeOwnerRecordStorageService();
    syncedData = FakeSyncedDataService();
    userSpace = FakeStorageService();
    database = FakePowerSyncDatabaseWrapper();
    wrapper = FakeSupabaseWrapper(clock: FakeClockImpl());
  });

  group('StartUpRecovery after a crash', () {
    for (final scenario in scenarios) {
      for (final crash in crashes.entries) {
        test('${scenario.name}: a crash ${crash.key} is finished at the next '
            'start', () async {
          await userSpace.saveData(_historyKey, 'the previous user\'s data');
          ownerRecords.seed(scenario.record);
          final sessionOfUser = scenario.sessionOfUser;
          if (sessionOfUser != null) {
            wrapper.seedSavedSession(_savedSessionOf(sessionOfUser));
            wrapper.setCurrentUser(user(sessionOfUser));
          }
          crash.value();

          await expectLater(startApp(), throwsA(anything));

          expect(
            ownerRecords.record?.pendingDelete,
            scenario.record.pendingDelete,
            reason: 'a crashed delete leaves the flag it started with',
          );

          disarmEveryCrash();
          final deletesBeforeRestart = syncedData.deleteCallCount;
          await startApp();

          disarmEveryCrash();
          await startApp();

          expect(await userSpace.getData<String>(_historyKey), isNull);
          expect(ownerRecords.record, scenario.recordAfterDelete);
          expect(syncedData.deleteCallCount, deletesBeforeRestart + 1);
          expect(
            database.executeCalls.map((call) => call.sql),
            contains('DELETE FROM $_table'),
          );
        });
      }
    }
  });

  group('StartUpRecovery when the world is not what it read', () {
    final loggedOut = OwnerRecord(
      userId: 'user-a',
      pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
    );

    setUp(() async {
      await userSpace.saveData(_historyKey, 'the previous user\'s data');
      ownerRecords.seed(loggedOut);
    });

    test('a failed read of the saved session deletes nothing, and the next '
        'start finishes the delete', () async {
      wrapper.shouldFailReadSavedSession = true;

      await expectLater(
        startApp(),
        throwsA(isA<SavedSessionUnreadableException>()),
      );

      expect(await userSpace.getData<String>(_historyKey), isNotNull);
      expect(ownerRecords.record, loggedOut);

      wrapper.shouldFailReadSavedSession = false;
      await startApp();

      expect(await userSpace.getData<String>(_historyKey), isNull);
      expect(ownerRecords.record, isNull);
    });

    test('a saved value that is not a session counts as no session, so the '
        'delete is finished without a sign-out', () async {
      wrapper.seedSavedSession('{broken');

      await startApp();

      expect(await userSpace.getData<String>(_historyKey), isNull);
      expect(ownerRecords.record, isNull);
      expect(wrapper.getMethodCallsFor('signOut'), isEmpty);
    });

    test('a different user who signs in while recovery reads is not signed '
        'out and nothing is deleted', () async {
      wrapper.seedSavedSession(_savedSessionOf('user-a'));
      wrapper.setCurrentUser(user('user-a'));
      wrapper.afterReadSavedSession = () {
        wrapper.afterReadSavedSession = null;
        wrapper.setCurrentUser(user('user-b'));
      };

      await startApp();

      expect(wrapper.getMethodCallsFor('signOut'), isEmpty);
      expect(wrapper.currentSession?.user.id, 'user-b');
      expect(await userSpace.getData<String>(_historyKey), isNotNull);
      expect(ownerRecords.record, loggedOut);
    });

    test('a saved session whose user is signed out while recovery reads '
        'deletes nothing and signs out nobody', () async {
      wrapper.seedSavedSession(_savedSessionOf('user-a'));
      wrapper.setCurrentUser(user('user-a'));
      wrapper.afterReadSavedSession = () {
        wrapper.afterReadSavedSession = null;
        wrapper.setCurrentUser(null);
      };

      await startApp();

      expect(wrapper.getMethodCallsFor('signOut'), isEmpty);
      expect(ownerRecords.record, loggedOut);
    });
  });
}

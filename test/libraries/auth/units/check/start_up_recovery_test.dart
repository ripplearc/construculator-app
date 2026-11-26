import 'dart:convert';

import 'package:construculator/libraries/auth/check/start_up_recovery.dart';
import 'package:construculator/libraries/auth/queue/auth_event_queue.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/testing/fake_synced_data_service.dart';
import 'package:construculator/libraries/storage/local_data_delete_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:construculator/libraries/storage/testing/fake_owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

String _savedSessionOf(String userId) => json.encode({
  'access_token': 'a-$userId',
  'token_type': 'bearer',
  'refresh_token': 'r-$userId',
  'user': {'id': userId},
});

void main() {
  late FakeOwnerRecordStorageService ownerRecords;
  late FakeSyncedDataService syncedData;
  late FakeSupabaseWrapper wrapper;
  late AuthEventQueue queue;
  late StartUpRecovery recovery;

  Future<void> runRecovery() async {
    Object? error;
    await queue.enqueue(
      eventNumber: queue.numberNextEvent(),
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

  setUp(() {
    ownerRecords = FakeOwnerRecordStorageService();
    syncedData = FakeSyncedDataService();
    wrapper = FakeSupabaseWrapper(clock: FakeClockImpl());
    // ignore: no_direct_instantiation, reason: unit test builds the queue from its settings
    queue = AuthEventQueue(
      actionTimeout: const Duration(milliseconds: 50),
      onUnstoppedRun: () {},
    );
    // ignore: no_direct_instantiation, reason: the class under test is built from its fakes
    recovery = StartUpRecovery(
      ownerRecords: ownerRecords,
      // ignore: no_direct_instantiation, reason: the real delete routine runs on fakes
      deleteService: LocalDataDeleteService(
        ownerRecords: ownerRecords,
        database: FakePowerSyncDatabaseWrapper(),
        syncedData: syncedData,
        userSpace: FakeStorageService(),
        registrations: const [],
      ),
      wrapper: wrapper,
    );
  });

  group('StartUpRecovery', () {
    group('with no pending delete', () {
      test('does nothing when there is no owner record', () async {
        await runRecovery();

        expect(syncedData.deleteCallCount, 0);
        expect(ownerRecords.writes, isEmpty);
      });

      test('does nothing when the record has no flag', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        wrapper.seedSavedSession(_savedSessionOf('user-a'));

        await runRecovery();

        expect(syncedData.deleteCallCount, 0);
        expect(ownerRecords.record, OwnerRecord(userId: 'user-a'));
      });

      test('fails on an unreadable owner record without deleting', () async {
        ownerRecords.shouldReadUnknown = true;

        await expectLater(
          runRecovery(),
          throwsA(isA<OwnerRecordUnreadableException>()),
        );

        expect(syncedData.deleteCallCount, 0);
      });
    });

    group('with a logout flag', () {
      setUp(() {
        ownerRecords.seed(
          OwnerRecord(
            userId: 'user-a',
            pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
          ),
        );
      });

      test('with no saved session it deletes and removes the record', () async {
        await runRecovery();

        expect(syncedData.deleteCallCount, 1);
        expect(ownerRecords.record, isNull);
      });

      test('with a saved session it deletes nothing', () async {
        wrapper.seedSavedSession(_savedSessionOf('user-a'));

        await runRecovery();

        expect(syncedData.deleteCallCount, 0);
        expect(ownerRecords.writes, isEmpty);
      });

      test('with a failed session read it deletes nothing and fails', () async {
        wrapper.shouldFailReadSavedSession = true;

        await expectLater(
          runRecovery(),
          throwsA(isA<SavedSessionUnreadableException>()),
        );

        expect(syncedData.deleteCallCount, 0);
        expect(ownerRecords.writes, isEmpty);
      });
    });

    group('with an arrival flag', () {
      setUp(() {
        ownerRecords.seed(
          OwnerRecord(
            userId: 'user-a',
            pendingDelete: const PendingDelete.arrivalOf('user-b'),
          ),
        );
      });

      test('with a saved session of the arriving user it deletes and '
          'replaces the record with that user', () async {
        wrapper.seedSavedSession(_savedSessionOf('user-b'));

        await runRecovery();

        expect(syncedData.deleteCallCount, 1);
        expect(ownerRecords.record, OwnerRecord(userId: 'user-b'));
      });

      test('with no saved session it deletes and removes the record', () async {
        await runRecovery();

        expect(syncedData.deleteCallCount, 1);
        expect(ownerRecords.record, isNull);
      });

      test('with a saved session of another user it deletes and removes '
          'the record', () async {
        wrapper.seedSavedSession(_savedSessionOf('user-c'));

        await runRecovery();

        expect(syncedData.deleteCallCount, 1);
        expect(ownerRecords.record, isNull);
      });

      test('with a saved value that is not a session it deletes and removes '
          'the record', () async {
        wrapper.seedSavedSession('{broken');

        await runRecovery();

        expect(syncedData.deleteCallCount, 1);
        expect(ownerRecords.record, isNull);
      });

      test('with a failed session read it deletes nothing and fails', () async {
        wrapper.shouldFailReadSavedSession = true;

        await expectLater(
          runRecovery(),
          throwsA(isA<SavedSessionUnreadableException>()),
        );

        expect(syncedData.deleteCallCount, 0);
      });
    });

    test('keeps the flag when a step of the delete fails', () async {
      ownerRecords.seed(
        OwnerRecord(
          userId: 'user-a',
          pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
        ),
      );
      syncedData.shouldThrowOnDelete = true;

      await expectLater(runRecovery(), throwsException);

      expect(
        ownerRecords.record?.pendingDelete,
        const PendingDelete.logoutOrNoOwnerRecord(),
      );
    });
  });
}

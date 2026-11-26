import 'dart:async';
import 'dart:convert';

import 'package:construculator/libraries/auth/check/start_up_recovery.dart';
import 'package:construculator/libraries/auth/queue/auth_event_queue.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/testing/fake_synced_data_service.dart';
import 'package:construculator/libraries/storage/local_data_delete_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:construculator/libraries/storage/testing/fake_owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
import 'package:construculator/libraries/supabase/data/saved_session_read.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

String _savedSessionOf(String userId) => json.encode({
  'access_token': 'fake-access-token-$userId',
  'token_type': 'bearer',
  'refresh_token': 'r-$userId',
  'user': {'id': userId},
});

void main() {
  late FakeOwnerRecordStorageService ownerRecords;
  late FakeSyncedDataService syncedData;
  late FakeSupabaseWrapper wrapper;
  late FakeClockImpl clock;
  late AuthEventQueue queue;
  late StartUpRecovery recovery;

  Future<void> runRecovery({bool isFirstAttempt = true}) async {
    Object? error;
    await queue.enqueue(
      eventNumber: queue.numberNextEvent(),
      item: (run) async {
        try {
          await recovery.run(run, isFirstAttempt: isFirstAttempt);
        } catch (e) {
          error = e;
          rethrow;
        }
      },
      settle: (outcome) async {},
    );
    if (error != null) throw error!;
  }

  Future<bool> runRemoval() async {
    Object? error;
    var removed = false;
    await queue.enqueue(
      eventNumber: queue.numberNextEvent(),
      item: (run) async {
        try {
          removed = await recovery.removeUnreadableSavedSession(run);
        } catch (e) {
          error = e;
          rethrow;
        }
      },
      settle: (outcome) async {},
    );
    if (error != null) throw error!;
    return removed;
  }

  setUp(() {
    ownerRecords = FakeOwnerRecordStorageService();
    syncedData = FakeSyncedDataService();
    clock = FakeClockImpl(DateTime.utc(2026, 11, 25, 9));
    wrapper = FakeSupabaseWrapper(clock: clock);
    wrapper.setCurrentUser(FakeUser(id: 'user-a', createdAt: '2026-01-01'));
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
      clock: clock,
      removalPollInterval: const Duration(milliseconds: 1),
    );
  });

  group('StartUpRecovery', () {
    group('with no pending delete', () {
      test('does nothing when there is no owner record', () async {
        await runRecovery();

        expect(syncedData.deleteCallCount, 0);
        expect(ownerRecords.writes, isEmpty);
      });

      test('does nothing when a session is saved', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        wrapper.seedSavedSession(_savedSessionOf('user-a'));

        await runRecovery();

        expect(syncedData.deleteCallCount, 0);
        expect(ownerRecords.record, OwnerRecord(userId: 'user-a'));
      });

      test('saves today as the sign-out date when no session is saved and '
          'none was saved before', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));

        await runRecovery();

        expect(
          ownerRecords.record,
          OwnerRecord(
            userId: 'user-a',
            signOutDate: DateTime.utc(2026, 11, 25, 9),
          ),
        );
        expect(syncedData.deleteCallCount, 0);
      });

      test('keeps the earlier sign-out date', () async {
        final earlier = DateTime.utc(2026, 11, 1);
        ownerRecords.seed(OwnerRecord(userId: 'user-a', signOutDate: earlier));

        await runRecovery();

        expect(ownerRecords.writes, isEmpty);
        expect(ownerRecords.record?.signOutDate, earlier);
      });

      test('saves no date and deletes nothing when the saved session cannot '
          'be read', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        wrapper.shouldFailReadSavedSession = true;

        await expectLater(
          runRecovery(),
          throwsA(isA<SavedSessionUnreadableException>()),
        );

        expect(ownerRecords.writes, isEmpty);
        expect(syncedData.deleteCallCount, 0);
      });

      test('saves no date when a saved value is not a session', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        wrapper.seedSavedSession('{broken');

        await runRecovery();

        expect(ownerRecords.writes, isEmpty);
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

      test('with the current session saved it signs out, then deletes and '
          'removes the record', () async {
        wrapper.seedSavedSession(_savedSessionOf('user-a'));

        await runRecovery();

        expect(wrapper.getMethodCallsFor('signOut'), hasLength(1));
        expect(wrapper.currentSession, isNull);
        expect(syncedData.deleteCallCount, 1);
        expect(ownerRecords.record, isNull);
      });

      test('waits until Supabase has removed the saved session before it '
          'deletes', () async {
        wrapper.seedSavedSession(_savedSessionOf('user-a'));
        wrapper.savedSessionReadsAfterSignOutBeforeRemoval = 3;
        var readsWhenDeleteStarted = 0;
        ownerRecords.afterWrite = (_) {
          ownerRecords.afterWrite = null;
          readsWhenDeleteStarted = wrapper
              .getMethodCallsFor('readSavedSession')
              .length;
        };

        await runRecovery();

        expect(readsWhenDeleteStarted, 1 + 3 + 1);
        expect(syncedData.deleteCallCount, 1);
      });

      test('with a saved session that is not the current one it signs out '
          'nobody and deletes nothing', () async {
        wrapper.seedSavedSession(_savedSessionOf('user-a'));
        wrapper.setCurrentUser(FakeUser(id: 'user-b', createdAt: '2026-01-01'));

        await runRecovery();

        expect(wrapper.getMethodCallsFor('signOut'), isEmpty);
        expect(syncedData.deleteCallCount, 0);
        expect(ownerRecords.writes, isEmpty);
      });

      test('with a saved session and no current session it signs out nobody '
          'and deletes nothing', () async {
        wrapper.seedSavedSession(_savedSessionOf('user-a'));
        wrapper.setCurrentUser(null);

        await runRecovery();

        expect(wrapper.getMethodCallsFor('signOut'), isEmpty);
        expect(syncedData.deleteCallCount, 0);
      });

      test('with a saved value that is not a session it deletes without a '
          'sign-out, because that value is no session', () async {
        wrapper.seedSavedSession('{broken');

        await runRecovery();

        expect(wrapper.getMethodCallsFor('signOut'), isEmpty);
        expect(syncedData.deleteCallCount, 1);
        expect(ownerRecords.record, isNull);
      });

      test('with a saved value that is not a session and no current session '
          'it deletes without a sign-out', () async {
        wrapper.seedSavedSession('{broken');
        wrapper.setCurrentUser(null);

        await runRecovery();

        expect(wrapper.getMethodCallsFor('signOut'), isEmpty);
        expect(syncedData.deleteCallCount, 1);
      });

      test('a retry signs out nobody and deletes nothing, even when the saved '
          'session is the current one', () async {
        wrapper.seedSavedSession(_savedSessionOf('user-a'));

        await runRecovery(isFirstAttempt: false);

        expect(wrapper.getMethodCallsFor('signOut'), isEmpty);
        expect(syncedData.deleteCallCount, 0);
        expect(
          ownerRecords.record?.pendingDelete,
          const PendingDelete.logoutOrNoOwnerRecord(),
        );
      });

      test('finishes the delete when the sign-out call fails after the '
          'session ended', () async {
        wrapper.seedSavedSession(_savedSessionOf('user-a'));
        wrapper.shouldThrowAfterSignOutEndedSession = true;

        await runRecovery();

        expect(wrapper.getMethodCallsFor('signOut'), hasLength(1));
        expect(syncedData.deleteCallCount, 1);
        expect(ownerRecords.record, isNull);
      });

      test('a sign-out that runs past the timeout fails the run instead of '
          'being taken for a finished one', () async {
        wrapper.seedSavedSession(_savedSessionOf('user-a'));
        wrapper.signOutGate = Completer<void>();

        await expectLater(runRecovery(), throwsA(isA<QueueTimeoutException>()));

        expect(syncedData.deleteCallCount, 0);
        wrapper.signOutGate?.complete();
      });

      test(
        'a retry finishes the delete that its own sign-out left behind',
        () async {
          wrapper.seedSavedSession(_savedSessionOf('user-a'));
          wrapper.savedSessionReadsAfterSignOutBeforeRemoval = 5;
          wrapper.afterReadSavedSession = () {
            wrapper.afterReadSavedSession = null;
            wrapper.shouldFailReadSavedSession = true;
          };
          await expectLater(
            runRecovery(),
            throwsA(isA<SavedSessionUnreadableException>()),
          );
          wrapper.shouldFailReadSavedSession = false;

          await runRecovery(isFirstAttempt: false);

          expect(wrapper.getMethodCallsFor('signOut'), hasLength(1));
          expect(syncedData.deleteCallCount, 1);
          expect(ownerRecords.record, isNull);
        },
      );

      test('stops waiting for the removal and fails when the saved session '
          'cannot be read', () async {
        wrapper.seedSavedSession(_savedSessionOf('user-a'));
        wrapper.savedSessionReadsAfterSignOutBeforeRemoval = 5;
        wrapper.afterReadSavedSession = () {
          wrapper.afterReadSavedSession = null;
          wrapper.shouldFailReadSavedSession = true;
        };

        await expectLater(
          runRecovery(),
          throwsA(isA<SavedSessionUnreadableException>()),
        );

        expect(syncedData.deleteCallCount, 0);
      });

      test(
        'keeps the flag and deletes nothing when the sign-out fails',
        () async {
          wrapper.seedSavedSession(_savedSessionOf('user-a'));
          wrapper.shouldThrowOnSignOut = true;

          await expectLater(runRecovery(), throwsA(isA<ServerException>()));

          expect(syncedData.deleteCallCount, 0);
          expect(
            ownerRecords.record?.pendingDelete,
            const PendingDelete.logoutOrNoOwnerRecord(),
          );
        },
      );

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

    group('removing a saved value Supabase could not load', () {
      const brokenValue = '{broken';

      setUp(() => wrapper.setCurrentUser(null));

      test('does nothing when no value is saved', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));

        final removed = await runRemoval();

        expect(removed, isFalse);
        expect(wrapper.getMethodCallsFor('removeSavedSession'), isEmpty);
        expect(ownerRecords.writes, isEmpty);
      });

      test('removes the value and saves the sign-out date', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        wrapper.seedSavedSession(brokenValue);

        final removed = await runRemoval();

        expect(removed, isTrue);
        expect(await wrapper.readSavedSession(), isA<SavedSessionAbsent>());
        expect(
          ownerRecords.record,
          OwnerRecord(
            userId: 'user-a',
            signOutDate: DateTime.utc(2026, 11, 25, 9),
          ),
        );
        expect(wrapper.getMethodCallsFor('signOut'), isEmpty);
        expect(syncedData.deleteCallCount, 0);
      });

      test('removes the value and writes nothing when no owner record '
          'exists', () async {
        wrapper.seedSavedSession(brokenValue);

        final removed = await runRemoval();

        expect(removed, isTrue);
        expect(ownerRecords.writes, isEmpty);
      });

      test('keeps the earlier sign-out date', () async {
        final earlier = DateTime.utc(2026, 11, 1);
        ownerRecords.seed(OwnerRecord(userId: 'user-a', signOutDate: earlier));
        wrapper.seedSavedSession(brokenValue);

        await runRemoval();

        expect(ownerRecords.record?.signOutDate, earlier);
      });

      test('keeps a pending-delete flag and saves no date', () async {
        ownerRecords.seed(
          OwnerRecord(
            userId: 'user-a',
            pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
          ),
        );
        wrapper.seedSavedSession(brokenValue);

        final removed = await runRemoval();

        expect(removed, isTrue);
        expect(ownerRecords.writes, isEmpty);
        expect(
          ownerRecords.record?.pendingDelete,
          const PendingDelete.logoutOrNoOwnerRecord(),
        );
      });

      test(
        'keeps a pending-delete flag that names nobody, without failing',
        () async {
          ownerRecords.seed(
            OwnerRecord(
              pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
            ),
          );
          wrapper.seedSavedSession(brokenValue);

          await runRemoval();

          expect(ownerRecords.writes, isEmpty);
        },
      );

      test(
        'removes nothing when a session has been current since the read',
        () async {
          ownerRecords.seed(OwnerRecord(userId: 'user-a'));
          wrapper.seedSavedSession(brokenValue);
          wrapper.setCurrentUser(
            FakeUser(id: 'user-b', createdAt: '2026-01-01'),
          );

          final removed = await runRemoval();

          expect(removed, isFalse);
          expect(wrapper.getMethodCallsFor('removeSavedSession'), isEmpty);
          expect(await wrapper.readSavedSession(), isA<SavedSessionFound>());
        },
      );

      test('keeps a value that reads fine and fails', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        wrapper.seedSavedSession(_savedSessionOf('user-a'));

        await expectLater(
          runRemoval(),
          throwsA(isA<SavedSessionNotLoadedException>()),
        );

        expect(wrapper.getMethodCallsFor('removeSavedSession'), isEmpty);
        expect(ownerRecords.writes, isEmpty);
      });

      test('removes and saves nothing when the read fails', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        wrapper.seedSavedSession(brokenValue);
        wrapper.shouldFailReadSavedSession = true;

        await expectLater(
          runRemoval(),
          throwsA(isA<SavedSessionUnreadableException>()),
        );

        expect(wrapper.getMethodCallsFor('removeSavedSession'), isEmpty);
        expect(ownerRecords.writes, isEmpty);
      });

      test('saves no date when the removal fails', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        wrapper.seedSavedSession(brokenValue);
        wrapper.shouldThrowOnRemoveSavedSession = true;

        await expectLater(runRemoval(), throwsException);

        expect(ownerRecords.writes, isEmpty);
      });
    });
  });
}

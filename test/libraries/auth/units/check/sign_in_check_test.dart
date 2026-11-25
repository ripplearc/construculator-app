import 'dart:async';

import 'package:construculator/libraries/auth/check/sign_in_check.dart';
import 'package:construculator/libraries/auth/queue/auth_event_queue.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_manager.dart';
import 'package:construculator/libraries/powersync/testing/fake_synced_data_service.dart';
import 'package:construculator/libraries/session/testing/fake_session_service.dart';
import 'package:construculator/libraries/storage/local_data_delete_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:construculator/libraries/storage/testing/fake_owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeOwnerRecordStorageService ownerRecords;
  late FakeSyncedDataService syncedData;
  late FakeSessionService sessionService;
  late FakePowerSyncManager powerSync;
  late FakeSupabaseWrapper wrapper;
  late int identityResets;
  late AuthEventQueue queue;
  late SignInCheck check;

  FakeUser user(String id) => FakeUser(id: id, createdAt: '2026-01-01');

  Future<void> runCheck(String userId, {bool isFreshSignIn = false}) async {
    Object? error;
    await queue.enqueue(
      eventNumber: queue.numberNextEvent(),
      item: (run) async {
        try {
          await check.run(run, userId: userId, isFreshSignIn: isFreshSignIn);
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
    sessionService = FakeSessionService();
    powerSync = FakePowerSyncManager();
    wrapper = FakeSupabaseWrapper(clock: FakeClockImpl());
    identityResets = 0;
    wrapper.setCurrentUser(user('user-a'));
    // ignore: no_direct_instantiation, reason: unit test builds the queue from its settings
    queue = AuthEventQueue(
      actionTimeout: const Duration(milliseconds: 50),
      onUnstoppedRun: () {},
    );
    // ignore: no_direct_instantiation, reason: the class under test is built from its fakes
    check = SignInCheck(
      ownerRecords: ownerRecords,
      // ignore: no_direct_instantiation, reason: the real delete routine runs on fakes
      deleteService: LocalDataDeleteService(
        ownerRecords: ownerRecords,
        database: FakePowerSyncDatabaseWrapper(),
        syncedData: syncedData,
        userSpace: FakeStorageService(),
        registrations: const [],
      ),
      sessionService: sessionService,
      powerSync: powerSync,
      wrapper: wrapper,
      resetIdentity: () async => identityResets++,
    );
  });

  group('SignInCheck', () {
    group('same user as the owner record', () {
      test(
        'with the module not added yet it adds the module and connects',
        () async {
          ownerRecords.seed(OwnerRecord(userId: 'user-a'));

          await runCheck('user-a');

          expect(sessionService.isActive, isTrue);
          expect(powerSync.connectCallCount, 1);
          expect(check.activeModuleUserId, 'user-a');
          expect(syncedData.deleteCallCount, 0);
        },
      );

      test('with the module already added it changes nothing', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        await runCheck('user-a');

        await runCheck('user-a');

        expect(sessionService.startCount, 1);
        expect(powerSync.connectCallCount, 1);
        expect(ownerRecords.writes, isEmpty);
      });

      test('removes the sign-out date when the module is not added', () async {
        ownerRecords.seed(
          OwnerRecord(userId: 'user-a', signOutDate: DateTime.utc(2026, 11, 1)),
        );

        await runCheck('user-a');

        expect(ownerRecords.record, OwnerRecord(userId: 'user-a'));
        expect(powerSync.connectCallCount, 1);
      });
    });

    test('an event that is not a sign-in for the user already connected reads '
        'no owner record, so an unreadable one cannot block it', () async {
      ownerRecords.seed(OwnerRecord(userId: 'user-a'));
      await runCheck('user-a');
      ownerRecords.shouldReadUnknown = true;

      await runCheck('user-a');

      expect(powerSync.connectCallCount, 1);
    });

    test('the same user signing in again after the session ended gets the '
        'module and PowerSync again', () async {
      ownerRecords.seed(OwnerRecord(userId: 'user-a'));
      await runCheck('user-a');
      sessionService.endSession();
      expect(check.activeModuleUserId, isNull);

      await runCheck('user-a');

      expect(sessionService.isActive, isTrue);
      expect(check.activeModuleUserId, 'user-a');
      expect(powerSync.connectCallCount, 2);
    });

    group('different user from the owner record', () {
      setUp(() => ownerRecords.seed(OwnerRecord(userId: 'user-old')));

      test(
        'deletes, saves the new user, adds the module and connects',
        () async {
          await runCheck('user-a');

          expect(syncedData.deleteCallCount, 1);
          expect(ownerRecords.record, OwnerRecord(userId: 'user-a'));
          expect(sessionService.isActive, isTrue);
          expect(powerSync.connectCallCount, 1);
          expect(identityResets, 0);
        },
      );

      test('resets the identity and replaces the module when another user '
          'was active', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        await runCheck('user-a');
        wrapper.setCurrentUser(user('user-b'));

        await runCheck('user-b');

        expect(identityResets, 1);
        expect(sessionService.endCount, 1);
        expect(sessionService.startCount, 2);
        expect(check.activeModuleUserId, 'user-b');
        expect(ownerRecords.record, OwnerRecord(userId: 'user-b'));
      });
    });

    group('no owner record', () {
      test('a fresh sign-in is treated as a different user', () async {
        await runCheck('user-a', isFreshSignIn: true);

        expect(syncedData.deleteCallCount, 1);
        expect(ownerRecords.record, OwnerRecord(userId: 'user-a'));
        expect(sessionService.isActive, isTrue);
      });

      test(
        'a restored session sets the flag and signs out, adding nothing',
        () async {
          await runCheck('user-a');

          expect(
            ownerRecords.record,
            OwnerRecord(
              pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
            ),
          );
          expect(wrapper.currentSession, isNull);
          expect(sessionService.isActive, isFalse);
          expect(powerSync.connectCallCount, 0);
          expect(syncedData.deleteCallCount, 0);
        },
      );
    });

    group('a leftover pending-delete flag', () {
      test('is finished first, then a fresh sign-in takes over', () async {
        ownerRecords.seed(
          OwnerRecord(
            userId: 'user-old',
            pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
          ),
        );

        await runCheck('user-a', isFreshSignIn: true);

        expect(syncedData.deleteCallCount, 2);
        expect(ownerRecords.record, OwnerRecord(userId: 'user-a'));
        expect(sessionService.isActive, isTrue);
      });

      test('an arrival flag for this user is replaced by the user without '
          'signing out', () async {
        ownerRecords.seed(
          OwnerRecord(
            userId: 'user-old',
            pendingDelete: const PendingDelete.arrivalOf('user-a'),
          ),
        );

        await runCheck('user-a');

        expect(syncedData.deleteCallCount, 1);
        expect(ownerRecords.record, OwnerRecord(userId: 'user-a'));
        expect(wrapper.currentSession, isNotNull);
        expect(sessionService.isActive, isTrue);
        expect(powerSync.connectCallCount, 1);
      });

      test(
        'a logout flag with a restored session signs the session out',
        () async {
          ownerRecords.seed(
            OwnerRecord(
              userId: 'user-a',
              pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
            ),
          );

          await runCheck('user-a');

          expect(syncedData.deleteCallCount, 1);
          expect(wrapper.currentSession, isNull);
          expect(sessionService.isActive, isFalse);
        },
      );

      test('an arrival flag for another user is finished without keeping that '
          'user', () async {
        ownerRecords.seed(
          OwnerRecord(
            userId: 'user-old',
            pendingDelete: const PendingDelete.arrivalOf('user-other'),
          ),
        );

        await runCheck('user-a', isFreshSignIn: true);

        expect(ownerRecords.record, OwnerRecord(userId: 'user-a'));
        expect(sessionService.isActive, isTrue);
      });

      test('a flag on a record for the module user already added is left '
          'to the logout that set it', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        await runCheck('user-a');
        ownerRecords.seed(
          OwnerRecord(
            userId: 'user-a',
            pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
          ),
        );

        await runCheck('user-a');

        expect(syncedData.deleteCallCount, 0);
        expect(sessionService.isActive, isTrue);
      });
    });

    group('failures', () {
      test('an unreadable owner record throws and deletes nothing', () async {
        ownerRecords.shouldReadUnknown = true;

        await expectLater(
          runCheck('user-a', isFreshSignIn: true),
          throwsA(isA<OwnerRecordUnreadableException>()),
        );

        expect(syncedData.deleteCallCount, 0);
        expect(sessionService.isActive, isFalse);
      });

      test('a failed delete throws and adds no module', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-old'));
        syncedData.shouldThrowOnDelete = true;

        await expectLater(runCheck('user-a'), throwsException);

        expect(sessionService.isActive, isFalse);
        expect(powerSync.connectCallCount, 0);
        expect(check.activeModuleUserId, isNull);
      });

      test('a failed connect removes the module it added', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        powerSync.shouldThrowOnConnect = true;

        await expectLater(runCheck('user-a'), throwsA(isA<StateError>()));

        expect(sessionService.isActive, isFalse);
        expect(check.activeModuleUserId, isNull);
      });

      test('a connect that hangs times out and removes the module', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        powerSync.connectGate = Completer<void>();

        await expectLater(
          runCheck('user-a'),
          throwsA(isA<QueueTimeoutException>()),
        );

        expect(sessionService.isActive, isFalse);
        expect(check.activeModuleUserId, isNull);
      });
    });

    group('the session changed while the check ran', () {
      test('does nothing when the user signed out before the delete', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-old'));
        wrapper.setCurrentUser(null);

        await runCheck('user-a');

        expect(syncedData.deleteCallCount, 0);
        expect(sessionService.isActive, isFalse);
      });

      test('does nothing when another user is signed in now', () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-old'));
        wrapper.setCurrentUser(user('user-b'));

        await runCheck('user-a');

        expect(syncedData.deleteCallCount, 0);
        expect(powerSync.connectCallCount, 0);
      });
    });
  });
}

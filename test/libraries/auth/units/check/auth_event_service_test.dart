import 'dart:async';

import 'package:construculator/libraries/auth/check/auth_event_service.dart';
import 'package:construculator/libraries/auth/check/check_finished_state_impl.dart';
import 'package:construculator/libraries/auth/check/check_state.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  late FakeOwnerRecordStorageService ownerRecords;
  late FakeSyncedDataService syncedData;
  late FakeSessionService sessionService;
  late FakePowerSyncManager powerSync;
  late FakeSupabaseWrapper wrapper;
  late CheckFinishedStateImpl state;
  late AuthEventQueue queue;
  late AuthEventService service;
  late SignInCheck check;
  late int identityResets;
  late int unstoppedRuns;

  FakeUser user(String id) => FakeUser(id: id, createdAt: '2026-01-01');

  void signIn(String id, {supabase.AuthChangeEvent? event}) {
    wrapper.signInEvent = event ?? supabase.AuthChangeEvent.signedIn;
    wrapper.setCurrentUser(user(id));
  }

  setUp(() {
    ownerRecords = FakeOwnerRecordStorageService();
    syncedData = FakeSyncedDataService();
    sessionService = FakeSessionService();
    powerSync = FakePowerSyncManager();
    wrapper = FakeSupabaseWrapper(clock: FakeClockImpl());
    identityResets = 0;
    unstoppedRuns = 0;
    // ignore: no_direct_instantiation, reason: the service under test is built from its collaborators
    state = CheckFinishedStateImpl();
    // ignore: no_direct_instantiation, reason: the service under test is built from its collaborators
    queue = AuthEventQueue(
      actionTimeout: const Duration(milliseconds: 100),
      onUnstoppedRun: () => unstoppedRuns++,
    );
    // ignore: no_direct_instantiation, reason: the service under test is built from its collaborators
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
    // ignore: no_direct_instantiation, reason: the service under test is built from its collaborators
    service = AuthEventService(
      wrapper: wrapper,
      queue: queue,
      state: state,
      signInCheck: check,
    );
  });

  tearDown(() {
    service.dispose();
    state.dispose();
  });

  group('AuthEventService', () {
    test('a fresh sign-in finishes for that user with the module added and '
        'PowerSync connected', () async {
      final finished = expectLater(
        state.changes,
        emitsInOrder([const Checking(), const FinishedFor('user-a')]),
      );

      signIn('user-a');
      await finished;

      expect(sessionService.isActive, isTrue);
      expect(powerSync.connectCallCount, 1);
      expect(ownerRecords.record, OwnerRecord(userId: 'user-a'));
    });

    test('a first event with nobody signed in finishes with nobody', () async {
      final finished = expectLater(
        state.changes,
        emitsInOrder([const Checking(), const FinishedNobodySignedIn()]),
      );

      wrapper.setCurrentUser(null);
      await finished;

      expect(sessionService.isActive, isFalse);
    });

    test('a restored session with no owner record is signed out and ends with '
        'nobody signed in', () async {
      final finished = expectLater(
        state.changes,
        emitsThrough(const FinishedNobodySignedIn()),
      );

      signIn('user-a', event: supabase.AuthChangeEvent.initialSession);
      await finished;

      expect(wrapper.currentSession, isNull);
      expect(powerSync.connectCallCount, 0);
      expect(
        ownerRecords.record,
        OwnerRecord(pendingDelete: const PendingDelete.logoutOrNoOwnerRecord()),
      );
    });

    test('two accounts on one phone: the second sign-in goes back to checking '
        'at once, deletes the first account\'s data and finishes for the '
        'second', () async {
      final firstFinished = expectLater(
        state.changes,
        emitsThrough(const FinishedFor('user-a')),
      );
      signIn('user-a');
      await firstFinished;

      final secondFinished = expectLater(
        state.changes,
        emitsInOrder([
          const FinishedFor('user-a'),
          const Checking(),
          const FinishedFor('user-b'),
        ]),
      );
      signIn('user-b');
      await secondFinished;

      expect(syncedData.deleteCallCount, 2);
      expect(ownerRecords.record, OwnerRecord(userId: 'user-b'));
      expect(identityResets, 1);
      expect(sessionService.endCount, 1);
    });

    test('an event for a different user disconnects PowerSync before the event '
        'is handled', () async {
      final firstFinished = expectLater(
        state.changes,
        emitsThrough(const FinishedFor('user-a')),
      );
      signIn('user-a');
      await firstFinished;
      powerSync.connectGate = Completer<void>();

      signIn('user-b');

      expect(powerSync.disconnectKeepingDataCallCount, 1);
      expect(powerSync.connectCallCount, 1);
      powerSync.connectGate?.complete();
    });

    test('the first sign-in and a token renewal for the same user disconnect '
        'nothing', () async {
      final firstFinished = expectLater(
        state.changes,
        emitsThrough(const FinishedFor('user-a')),
      );
      signIn('user-a');
      await firstFinished;

      signIn('user-a', event: supabase.AuthChangeEvent.tokenRefreshed);
      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async {},
        settle: (outcome) async {},
      );

      expect(powerSync.disconnectKeepingDataCallCount, 0);
    });

    test('a failed disconnect is logged and the check still runs', () async {
      final firstFinished = expectLater(
        state.changes,
        emitsThrough(const FinishedFor('user-a')),
      );
      signIn('user-a');
      await firstFinished;
      powerSync.shouldThrowOnDisconnect = true;
      final secondFinished = expectLater(
        state.changes,
        emitsThrough(const FinishedFor('user-b')),
      );

      signIn('user-b');
      await secondFinished;

      expect(ownerRecords.record, OwnerRecord(userId: 'user-b'));
    });

    test('a token renewal for the same user changes nothing', () async {
      final firstFinished = expectLater(
        state.changes,
        emitsThrough(const FinishedFor('user-a')),
      );
      signIn('user-a');
      await firstFinished;
      final seen = <CheckState>[];
      final subscription = state.changes.listen(seen.add);

      signIn('user-a', event: supabase.AuthChangeEvent.tokenRefreshed);
      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async {},
        settle: (outcome) async {},
      );
      await subscription.cancel();

      expect(seen, [const FinishedFor('user-a')]);
      expect(powerSync.connectCallCount, 1);
      expect(syncedData.deleteCallCount, 1);
    });

    test('a replayed event is handled once', () async {
      ownerRecords.seed(OwnerRecord(userId: 'user-a'));
      final finished = expectLater(
        state.changes,
        emitsThrough(const FinishedFor('user-a')),
      );

      signIn('user-a');
      signIn('user-a');
      await finished;

      expect(queue.newestEventNumber, 1);
      expect(powerSync.connectCallCount, 1);
    });

    test('an event that arrives while a check runs waits, and the state '
        'finishes only after the newest event is handled', () async {
      ownerRecords.seed(OwnerRecord(userId: 'user-a'));
      powerSync.connectGate = Completer<void>();
      final seen = <CheckState>[];
      final subscription = state.changes.listen(seen.add);
      final finished = expectLater(
        state.changes,
        emitsThrough(const FinishedFor('user-a')),
      );

      signIn('user-a', event: supabase.AuthChangeEvent.initialSession);
      signIn('user-a', event: supabase.AuthChangeEvent.tokenRefreshed);
      powerSync.connectGate?.complete();
      await finished;
      await subscription.cancel();

      expect(seen, [const Checking(), const FinishedFor('user-a')]);
      expect(powerSync.connectCallCount, 1);
    });

    test(
      'a run that times out blocks the state and removes the module',
      () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-a'));
        powerSync.connectGate = Completer<void>();
        final blocked = expectLater(
          state.changes,
          emitsThrough(const Blocked('user-a')),
        );

        signIn('user-a', event: supabase.AuthChangeEvent.initialSession);
        await blocked;

        expect(sessionService.isActive, isFalse);
      },
    );

    test('while blocked an event for the same user starts no check', () async {
      ownerRecords.seed(OwnerRecord(userId: 'user-a'));
      powerSync.shouldThrowOnConnect = true;
      final blocked = expectLater(
        state.changes,
        emitsThrough(const Blocked('user-a')),
      );
      signIn('user-a', event: supabase.AuthChangeEvent.initialSession);
      await blocked;
      final connectsWhenBlocked = powerSync.connectCallCount;

      signIn('user-a', event: supabase.AuthChangeEvent.tokenRefreshed);
      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async {},
        settle: (outcome) async {},
      );

      expect(powerSync.connectCallCount, connectsWhenBlocked);
      expect(state.value, const Blocked('user-a'));
    });

    test(
      'a password recovery with no owner record keeps the user signed in',
      () async {
        final finished = expectLater(
          state.changes,
          emitsThrough(const FinishedFor('user-a')),
        );

        signIn('user-a', event: supabase.AuthChangeEvent.passwordRecovery);
        await finished;

        expect(wrapper.currentSession, isNotNull);
        expect(ownerRecords.record, OwnerRecord(userId: 'user-a'));
      },
    );

    test('once a restart is required later events start no check', () async {
      state.requireRestart();

      signIn('user-a');
      await queue.enqueue(
        eventNumber: queue.numberNextEvent(),
        item: (run) async {},
        settle: (outcome) async {},
      );

      expect(powerSync.connectCallCount, 0);
      expect(state.value, const RestartRequired());
    });

    test(
      'a sign-out clears PowerSync and ends with nobody signed in',
      () async {
        final firstFinished = expectLater(
          state.changes,
          emitsThrough(const FinishedFor('user-a')),
        );
        signIn('user-a');
        await firstFinished;
        final signedOut = expectLater(
          state.changes,
          emitsThrough(const FinishedNobodySignedIn()),
        );

        wrapper.setCurrentUser(null);
        await signedOut;

        expect(powerSync.clearCallCount, 1);
      },
    );

    test('the same user signing in again after a sign-out connects PowerSync '
        'again', () async {
      final firstFinished = expectLater(
        state.changes,
        emitsThrough(const FinishedFor('user-a')),
      );
      signIn('user-a');
      await firstFinished;
      final signedOut = expectLater(
        state.changes,
        emitsThrough(const FinishedNobodySignedIn()),
      );
      wrapper.setCurrentUser(null);
      await signedOut;
      final signedInAgain = expectLater(
        state.changes,
        emitsThrough(const FinishedFor('user-a')),
      );

      signIn('user-a', event: supabase.AuthChangeEvent.tokenRefreshed);
      await signedInAgain;

      expect(powerSync.connectCallCount, 2);
      expect(check.activeModuleUserId, 'user-a');
    });

    test('a failed check blocks the state for the signed-in user', () async {
      ownerRecords.shouldReadUnknown = true;
      final blocked = expectLater(
        state.changes,
        emitsThrough(const Blocked('user-a')),
      );

      signIn('user-a');
      await blocked;

      expect(syncedData.deleteCallCount, 0);
      expect(sessionService.isActive, isFalse);
    });

    test('a stream error is logged and does not stop later events', () async {
      wrapper.emitAuthStateError('network down');
      final finished = expectLater(
        state.changes,
        emitsThrough(const FinishedFor('user-a')),
      );

      signIn('user-a');
      await finished;

      expect(unstoppedRuns, 0);
    });
  });
}

import 'dart:io';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:construculator/libraries/powersync/interfaces/synced_data_service.dart';
import 'package:construculator/libraries/powersync/models/local_only_table_registry.dart';
import 'package:construculator/libraries/powersync/powersync_manager_impl.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/powersync/powersync_synced_data_service.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/testing/fake_synced_data_service.dart';
import 'package:construculator/libraries/storage/file_owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/interfaces/owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/local_data_delete_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

FileOwnerRecordStorageService buildFileStorage(Directory directory) =>
    // ignore: no_direct_instantiation, reason: the real file storage is the boundary under test
    FileOwnerRecordStorageService(directory: () async => directory);

PowerSyncSyncedDataService buildSyncedData(PowerSyncManager manager) =>
    // ignore: no_direct_instantiation, reason: the real service over the real manager is under test
    PowerSyncSyncedDataService(manager: manager);

LocalDataDeleteService buildRoutine({
  required OwnerRecordStorageService ownerRecords,
  required FakePowerSyncDatabaseWrapper database,
  required SyncedDataService syncedData,
}) =>
    // ignore: no_direct_instantiation, reason: the routine under test is wired to its real collaborators
    LocalDataDeleteService(
      ownerRecords: ownerRecords,
      database: database,
      syncedData: syncedData,
    );

void main() {
  final fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
  final fakeDatabase = FakePowerSyncDatabase();
  final bootstrap = FakeAppBootstrapFactory.create(
    supabaseWrapper: fakeSupabase,
    powerSyncDatabase: fakeDatabase,
  );

  setUpAll(() => Modular.init(_PowerSyncTestModule(bootstrap)));

  tearDownAll(() {
    Modular.destroy();
    fakeSupabase.dispose();
  });

  group('LocalDataDeleteService with its real collaborators', () {
    late Directory directory;
    late FileOwnerRecordStorageService ownerRecords;
    late FakePowerSyncDatabaseWrapper tables;

    setUp(() async {
      (Modular.get<PowerSyncManager>() as Disposable).dispose();
      Modular.dispose<PowerSyncManager>();
      fakeSupabase.reset();
      fakeDatabase.reset();
      directory = await Directory.systemTemp.createTemp('delete_routine_test');
      ownerRecords = buildFileStorage(directory);
      tables = FakePowerSyncDatabaseWrapper();
    });

    tearDown(() => directory.delete(recursive: true));

    Future<void> settle() async {
      await (Modular.get<PowerSyncManager>() as PowerSyncManagerImpl)
          .pendingOperations;
    }

    void signIn() {
      fakeSupabase.setCurrentUser(
        FakeUser(
          id: 'user-1',
          email: 'user@example.com',
          createdAt: '2000-01-01T00:00:00.000Z',
        ),
      );
    }

    test('replaces the record on disk with the arriving user', () async {
      await ownerRecords.write(OwnerRecord(userId: 'user-1'));
      final routine = buildRoutine(
        ownerRecords: ownerRecords,
        database: tables,
        syncedData: FakeSyncedDataService(),
      );

      await routine.deleteLocalData(arrivingUserId: 'user-2');

      final read = await ownerRecords.read() as OwnerRecordFound;
      expect(read.record, OwnerRecord(userId: 'user-2'));
      expect(tables.executeCalls, isNotEmpty);
      expect(
        [for (final call in tables.executeCalls) call.sql],
        [
          for (final entry in LocalOnlyTableRegistry.registrations)
            if (entry.policy == LocalOnlyTablePolicy.clearWhenUserChanges)
              'DELETE FROM ${entry.tableName}',
        ],
      );
    });

    test('removes the file after a logout delete', () async {
      await ownerRecords.write(OwnerRecord(userId: 'user-1'));
      final routine = buildRoutine(
        ownerRecords: ownerRecords,
        database: tables,
        syncedData: FakeSyncedDataService(),
      );

      await routine.deleteLocalData();

      expect(await ownerRecords.read(), isA<OwnerRecordAbsent>());
    });

    test('leaves the flag on disk when a clear step fails', () async {
      await ownerRecords.write(OwnerRecord(userId: 'user-1'));
      tables.executeError = StateError('disk full');
      final routine = buildRoutine(
        ownerRecords: ownerRecords,
        database: tables,
        syncedData: FakeSyncedDataService(),
      );

      await expectLater(routine.deleteLocalData(), throwsStateError);

      final read = await ownerRecords.read() as OwnerRecordFound;
      expect(
        read.record.pendingDelete,
        const PendingDelete.logoutOrNoOwnerRecord(),
      );
      expect(read.record.userId, 'user-1');
    });

    test(
      'clears PowerSync through the real manager and lets it reconnect',
      () async {
        signIn();
        final manager = Modular.get<PowerSyncManager>();
        await settle();
        expect(fakeDatabase.connectCallCount, 1);
        await ownerRecords.write(OwnerRecord(userId: 'user-1'));
        final routine = buildRoutine(
          ownerRecords: ownerRecords,
          database: tables,
          syncedData: buildSyncedData(manager),
        );

        await routine.deleteLocalData(arrivingUserId: 'user-2');
        await manager.connect();

        expect(fakeDatabase.disconnectAndClearCallCount, 1);
        expect(fakeDatabase.lastClearLocal, isFalse);
        expect(fakeDatabase.connectCallCount, 2);
        final read = await ownerRecords.read() as OwnerRecordFound;
        expect(read.record, OwnerRecord(userId: 'user-2'));
      },
    );

    test(
      'keeps the flag when the PowerSync clear fails, and a retry finishes',
      () async {
        signIn();
        final manager = Modular.get<PowerSyncManager>();
        await settle();
        await ownerRecords.write(OwnerRecord(userId: 'user-1'));
        final routine = buildRoutine(
          ownerRecords: ownerRecords,
          database: tables,
          syncedData: buildSyncedData(manager),
        );
        fakeDatabase.disconnectAndClearError = Exception('disk error');

        await expectLater(
          routine.deleteLocalData(arrivingUserId: 'user-2'),
          throwsException,
        );

        final flagged = await ownerRecords.read() as OwnerRecordFound;
        expect(
          flagged.record.pendingDelete,
          const PendingDelete.arrivalOf('user-2'),
        );

        fakeDatabase.disconnectAndClearError = null;
        await routine.deleteLocalData(arrivingUserId: 'user-2');

        final finished = await ownerRecords.read() as OwnerRecordFound;
        expect(finished.record, OwnerRecord(userId: 'user-2'));
      },
    );
  });
}

class _PowerSyncTestModule extends Module {
  final AppBootstrap appBootstrap;
  _PowerSyncTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [PowerSyncModule(appBootstrap)];
}

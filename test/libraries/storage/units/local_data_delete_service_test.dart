import 'package:construculator/libraries/powersync/models/local_only_table_registry.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/testing/fake_synced_data_service.dart';
import 'package:construculator/libraries/storage/local_data_delete_service.dart';
import 'package:construculator/libraries/storage/models/owner_record.dart';
import 'package:construculator/libraries/storage/testing/fake_owner_record_storage_service.dart';
import 'package:construculator/libraries/storage/testing/fake_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

LocalDataDeleteService buildService({
  required FakeOwnerRecordStorageService ownerRecords,
  required FakePowerSyncDatabaseWrapper database,
  required FakeSyncedDataService syncedData,
  required FakeStorageService userSpace,
  List<LocalOnlyTableRegistration>? registrations,
}) =>
    // ignore: no_direct_instantiation, reason: the service under test is built from its fakes
    LocalDataDeleteService(
      ownerRecords: ownerRecords,
      database: database,
      syncedData: syncedData,
      userSpace: userSpace,
      registrations: registrations ?? LocalOnlyTableRegistry.registrations,
    );

void main() {
  group('LocalDataDeleteService', () {
    const clearedNotes = LocalOnlyTableRegistration(
      tableName: 'notes',
      policy: LocalOnlyTablePolicy.clearWhenUserChanges,
    );
    const clearedDrafts = LocalOnlyTableRegistration(
      tableName: 'drafts',
      policy: LocalOnlyTablePolicy.clearWhenUserChanges,
    );
    const keptSetting = LocalOnlyTableRegistration(
      tableName: 'settings',
      policy: LocalOnlyTablePolicy.keepAsDeviceSetting,
    );

    late FakeOwnerRecordStorageService ownerRecords;
    late FakePowerSyncDatabaseWrapper database;
    late FakeSyncedDataService syncedData;
    late FakeStorageService userSpace;
    late LocalDataDeleteService service;

    final signedOutAt = DateTime.utc(2026, 11, 1);

    List<String> executedSql() => [
      for (final call in database.executeCalls) call.sql,
    ];

    setUp(() {
      ownerRecords = FakeOwnerRecordStorageService();
      database = FakePowerSyncDatabaseWrapper();
      syncedData = FakeSyncedDataService();
      userSpace = FakeStorageService();
      service = buildService(
        ownerRecords: ownerRecords,
        database: database,
        syncedData: syncedData,
        userSpace: userSpace,
        registrations: [clearedNotes, keptSetting, clearedDrafts],
      );
    });

    group('after a logout', () {
      setUp(() => ownerRecords.seed(OwnerRecord(userId: 'user-1')));

      test(
        'runs every registered clear step and leaves device settings',
        () async {
          await service.deleteLocalData();

          expect(executedSql(), ['DELETE FROM notes', 'DELETE FROM drafts']);
        },
      );

      test('empties the user space of the storage library', () async {
        await userSpace.saveData<String>(
          'last_used_unit.user-1.material',
          'kg',
        );

        await service.deleteLocalData();

        expect(userSpace.valueOf('last_used_unit.user-1.material'), isNull);
      });

      test('deletes the synced data and the unsent edits once', () async {
        await service.deleteLocalData();

        expect(syncedData.deleteCallCount, 1);
      });

      test(
        'sets a flag that names nobody and keeps the user id and date first',
        () async {
          ownerRecords.seed(
            OwnerRecord(userId: 'user-1', signOutDate: signedOutAt),
          );

          await service.deleteLocalData();

          expect(
            ownerRecords.writes.single,
            OwnerRecord(
              userId: 'user-1',
              pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
              signOutDate: signedOutAt,
            ),
          );
        },
      );

      test('removes the owner record at the end', () async {
        await service.deleteLocalData();

        expect(ownerRecords.record, isNull);
      });
    });

    test(
      'with no owner record, sets a flag with no user id and then removes it',
      () async {
        await service.deleteLocalData();

        expect(
          ownerRecords.writes.single,
          OwnerRecord(
            pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
          ),
        );
        expect(ownerRecords.record, isNull);
        expect(executedSql(), ['DELETE FROM notes', 'DELETE FROM drafts']);
      },
    );

    group('when a different user arrives', () {
      setUp(
        () => ownerRecords.seed(
          OwnerRecord(userId: 'user-1', signOutDate: signedOutAt),
        ),
      );

      test('names the arriving user in the flag first', () async {
        await service.deleteLocalData(arrivingUserId: 'user-2');

        expect(
          ownerRecords.writes.first,
          OwnerRecord(
            userId: 'user-1',
            pendingDelete: const PendingDelete.arrivalOf('user-2'),
            signOutDate: signedOutAt,
          ),
        );
      });

      test(
        'ends with a record for the new user, with no flag and no date',
        () async {
          await service.deleteLocalData(arrivingUserId: 'user-2');

          expect(ownerRecords.record, OwnerRecord(userId: 'user-2'));
          expect(ownerRecords.writes, hasLength(2));
        },
      );
    });

    group('keeps the flag set and rethrows when', () {
      final flagged = OwnerRecord(
        userId: 'user-1',
        pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
      );

      setUp(() => ownerRecords.seed(OwnerRecord(userId: 'user-1')));

      test(
        'the first clear step fails, so the flag was set before it ran',
        () async {
          database.executeError = StateError('disk full');

          await expectLater(service.deleteLocalData(), throwsStateError);

          expect(ownerRecords.record, flagged);
        },
      );

      test('a clear step fails, and no later step runs', () async {
        database.executeError = StateError('disk full');

        await expectLater(service.deleteLocalData(), throwsStateError);

        expect(syncedData.deleteCallCount, 0);
      });

      test(
        'the synced data cannot be deleted, after the clear steps ran',
        () async {
          syncedData.shouldThrowOnDelete = true;

          await expectLater(service.deleteLocalData(), throwsStateError);

          expect(executedSql(), ['DELETE FROM notes', 'DELETE FROM drafts']);
          expect(ownerRecords.record, flagged);
        },
      );

      test(
        'the user space cannot be cleared, after the table clear steps ran',
        () async {
          userSpace.shouldThrowOnClear = true;

          await expectLater(service.deleteLocalData(), throwsStateError);

          expect(executedSql(), ['DELETE FROM notes', 'DELETE FROM drafts']);
          expect(syncedData.deleteCallCount, 0);
          expect(ownerRecords.record, flagged);
        },
      );

      test('the last write fails, after everything was deleted', () async {
        ownerRecords.shouldThrowOnRemove = true;

        await expectLater(service.deleteLocalData(), throwsStateError);

        expect(syncedData.deleteCallCount, 1);
        expect(ownerRecords.record, flagged);
      });
    });

    group('a delete that an earlier run left flagged for an arriving user', () {
      setUp(
        () => ownerRecords.seed(
          OwnerRecord(
            userId: 'user-1',
            pendingDelete: const PendingDelete.arrivalOf('user-2'),
          ),
        ),
      );

      test('keeps naming that user when it runs again with no user', () async {
        database.executeError = StateError('disk full');

        await expectLater(service.deleteLocalData(), throwsStateError);

        expect(
          ownerRecords.record!.pendingDelete,
          const PendingDelete.arrivalOf('user-2'),
        );
      });

      test('names a different arriving user when one is given', () async {
        database.executeError = StateError('disk full');

        await expectLater(
          service.deleteLocalData(arrivingUserId: 'user-3'),
          throwsStateError,
        );

        expect(
          ownerRecords.record!.pendingDelete,
          const PendingDelete.arrivalOf('user-3'),
        );
      });
    });

    test('keeps the arrival flag set when a clear step fails', () async {
      ownerRecords.seed(OwnerRecord(userId: 'user-1'));
      database.executeError = StateError('disk full');

      await expectLater(
        service.deleteLocalData(arrivingUserId: 'user-2'),
        throwsStateError,
      );

      expect(
        ownerRecords.record!.pendingDelete,
        const PendingDelete.arrivalOf('user-2'),
      );
    });

    test(
      'refuses an empty arriving user id before deleting anything',
      () async {
        ownerRecords.seed(OwnerRecord(userId: 'user-1'));

        await expectLater(
          service.deleteLocalData(arrivingUserId: ''),
          throwsArgumentError,
        );

        expect(executedSql(), isEmpty);
        expect(syncedData.deleteCallCount, 0);
        expect(ownerRecords.writes, isEmpty);
      },
    );

    test('deletes nothing when the flag cannot be saved', () async {
      ownerRecords.seed(OwnerRecord(userId: 'user-1'));
      ownerRecords.shouldThrowOnWrite = true;

      await expectLater(service.deleteLocalData(), throwsStateError);

      expect(executedSql(), isEmpty);
      expect(syncedData.deleteCallCount, 0);
    });

    test('names the unreadable owner record in the exception text', () {
      expect(
        const OwnerRecordUnreadableException().toString(),
        contains('owner record could not be read'),
      );
    });

    test('deletes nothing when the owner record cannot be read', () async {
      ownerRecords.shouldReadUnknown = true;

      await expectLater(
        service.deleteLocalData(),
        throwsA(isA<OwnerRecordUnreadableException>()),
      );

      expect(executedSql(), isEmpty);
      expect(syncedData.deleteCallCount, 0);
      expect(ownerRecords.writes, isEmpty);
    });

    test('finishes a delete that an earlier run left flagged', () async {
      ownerRecords.seed(
        OwnerRecord(
          userId: 'user-1',
          pendingDelete: const PendingDelete.logoutOrNoOwnerRecord(),
        ),
      );

      await service.deleteLocalData();

      expect(ownerRecords.record, isNull);
      expect(executedSql(), ['DELETE FROM notes', 'DELETE FROM drafts']);
    });

    test('uses the production registry when none is given', () async {
      // ignore: no_direct_instantiation, reason: the default registrations are under test
      final production = LocalDataDeleteService(
        ownerRecords: ownerRecords,
        database: database,
        syncedData: syncedData,
        userSpace: userSpace,
      );

      await production.deleteLocalData();

      expect(executedSql(), [
        for (final entry in LocalOnlyTableRegistry.registrations)
          if (entry.policy == LocalOnlyTablePolicy.clearWhenUserChanges)
            'DELETE FROM ${entry.tableName}',
      ]);
    });
  });
}

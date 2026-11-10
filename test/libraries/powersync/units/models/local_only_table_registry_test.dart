import 'package:construculator/libraries/powersync/models/local_only_table_registry.dart';
import 'package:construculator/libraries/powersync/models/schema.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';

void main() {
  group('LocalOnlyTableRegistry', () {
    const clearedNote = LocalOnlyTableRegistration(
      tableName: 'notes',
      policy: LocalOnlyTablePolicy.clearWhenUserChanges,
    );

    Schema schemaOf({
      List<String> localOnly = const [],
      List<String> synced = const [],
    }) => Schema([
      for (final name in localOnly)
        Table.localOnly(name, [Column.text('value')]),
      for (final name in synced) Table(name, [Column.text('value')]),
    ]);

    List<String> problemsOf(
      Schema schema,
      List<LocalOnlyTableRegistration> registrations,
    ) {
      final localOnlyNames = {
        for (final table in schema.tables)
          if (table.localOnly) table.name,
      };
      final allNames = {for (final table in schema.tables) table.name};
      final seen = <String>{};
      return [
        for (final name in localOnlyNames)
          if (!registrations.any((entry) => entry.tableName == name))
            'local-only table "$name" is not registered',
        for (final entry in registrations)
          if (!seen.add(entry.tableName))
            'table "${entry.tableName}" is registered twice'
          else if (!allNames.contains(entry.tableName))
            'registered table "${entry.tableName}" is not in the schema'
          else if (!localOnlyNames.contains(entry.tableName))
            'registered table "${entry.tableName}" is not local-only',
      ];
    }

    test(
      'every local-only table of the schema is registered, and only those',
      () {
        expect(
          problemsOf(schema, LocalOnlyTableRegistry.registrations),
          isEmpty,
        );
      },
    );

    test('registers current_company to clear when the user changes', () {
      final entry = LocalOnlyTableRegistry.registrations.singleWhere(
        (entry) => entry.tableName == DatabaseConstants.currentCompanyTable,
      );

      expect(entry.policy, LocalOnlyTablePolicy.clearWhenUserChanges);
    });

    test('registers your_rate_refusals to clear when the user changes', () {
      final entry = LocalOnlyTableRegistry.registrations.singleWhere(
        (entry) => entry.tableName == DatabaseConstants.yourRateRefusalsTable,
      );

      expect(entry.policy, LocalOnlyTablePolicy.clearWhenUserChanges);
    });

    test('reports a local-only table that is not registered', () {
      final problems = problemsOf(schemaOf(localOnly: ['notes', 'drafts']), [
        clearedNote,
      ]);

      expect(problems, ['local-only table "drafts" is not registered']);
    });

    test('does not ask a synced table to be registered', () {
      final problems = problemsOf(
        schemaOf(localOnly: ['notes'], synced: ['projects']),
        [clearedNote],
      );

      expect(problems, isEmpty);
    });

    test('reports a registered table that is synced, not local-only', () {
      final problems = problemsOf(schemaOf(synced: ['notes']), [clearedNote]);

      expect(problems, ['registered table "notes" is not local-only']);
    });

    test('reports a registered table that left the schema', () {
      final problems = problemsOf(schemaOf(), [clearedNote]);

      expect(problems, ['registered table "notes" is not in the schema']);
    });

    test('reports a table registered twice', () {
      final problems = problemsOf(schemaOf(localOnly: ['notes']), [
        clearedNote,
        const LocalOnlyTableRegistration(
          tableName: 'notes',
          policy: LocalOnlyTablePolicy.keepAsDeviceSetting,
        ),
      ]);

      expect(problems, ['table "notes" is registered twice']);
    });

    group('clearForUserChange', () {
      late FakePowerSyncDatabaseWrapper database;

      setUp(() {
        database = FakePowerSyncDatabaseWrapper();
      });

      test(
        'deletes every row of a table that clears when the user changes',
        () async {
          await clearedNote.clearForUserChange(database);

          expect(database.executeCalls.map((call) => call.sql), [
            'DELETE FROM notes',
          ]);
        },
      );

      test('leaves a device setting alone', () async {
        const setting = LocalOnlyTableRegistration(
          tableName: 'onboarding_seen',
          policy: LocalOnlyTablePolicy.keepAsDeviceSetting,
        );

        await setting.clearForUserChange(database);

        expect(database.executeCalls, isEmpty);
      });

      test('lets a failed delete reach the caller', () async {
        database.executeError = StateError('disk full');

        await expectLater(
          clearedNote.clearForUserChange(database),
          throwsA(isA<StateError>()),
        );
      });

      test('clears every registered table whose policy says clear', () async {
        for (final entry in LocalOnlyTableRegistry.registrations) {
          await entry.clearForUserChange(database);
        }

        expect(
          database.executeCalls.map((call) => call.sql),
          unorderedEquals([
            for (final entry in LocalOnlyTableRegistry.registrations)
              if (entry.policy == LocalOnlyTablePolicy.clearWhenUserChanges)
                'DELETE FROM ${entry.tableName}',
          ]),
        );
      });
    });
  });
}

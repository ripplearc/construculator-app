import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/models/calculator_store_row_dto.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late PowerSyncLocalTradeStoresDataSource dataSource;

  final now = DateTime.utc(2026, 11, 2, 10);
  final later = DateTime.utc(2026, 11, 2, 11);
  const user = 'user-1';
  const other = 'user-2';

  CalculatorStoreRowDto row({
    String userId = user,
    CalculatorStoreKind kind = CalculatorStoreKind.density,
    Map<String, Object?> values = const {'name': 'slag', 'position': 3},
    MeasurementSystem system = MeasurementSystem.imperial,
    DateTime? deletedAt,
  }) => CalculatorStoreRowDto(
    userId: userId,
    storeKind: kind,
    values: values,
    unitSystem: system,
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );

  final concrete = row(
    values: const {
      'seed': 'density_concrete',
      'name': 'concrete',
      'position': 0,
    },
  );

  setUp(() {
    database = FakeTradeStoresDatabase();
    // The subject under test; resolving it through Modular would test the
    // module binding instead.
    // ignore: no_direct_instantiation
    dataSource = PowerSyncLocalTradeStoresDataSource(database: database);
  });

  tearDown(() async {
    await dataSource.dispose();
    await database.closeChanges();
  });

  group('PowerSyncLocalTradeStoresDataSource', () {
    group('rows', () {
      test('an insert mints a fresh id and reads back equal', () async {
        final first = await dataSource.insertRow(row());
        final second = await dataSource.insertRow(row());
        expect(first.id, isNotNull);
        expect(first.id, isNot(second.id));
        expect(await dataSource.fetchRows(user, CalculatorStoreKind.density), [
          first,
          second,
        ]);
      });

      test(
        'reads the rows of one user and one store, soft-deleted ones too',
        () async {
          final mine = await dataSource.insertRow(row());
          final gone = await dataSource.insertRow(row(deletedAt: later));
          await dataSource.insertRow(row(userId: other));
          await dataSource.insertRow(row(kind: CalculatorStoreKind.waste));
          expect(
            await dataSource.fetchRows(user, CalculatorStoreKind.density),
            [mine, gone],
          );
          expect(
            await dataSource.fetchRows(other, CalculatorStoreKind.density),
            hasLength(1),
          );
        },
      );

      test('an update rewrites the row with the id and answers false for a '
          'stranger or an unstored row', () async {
        final stored = await dataSource.insertRow(row());
        final edited = stored.copyWith(
          values: const {'name': 'slag', 'position': 1},
          unitSystem: MeasurementSystem.metric,
          updatedAt: later,
        );
        expect(await dataSource.updateRow(edited), isTrue);
        expect(await dataSource.fetchRows(user, CalculatorStoreKind.density), [
          edited,
        ]);
        expect(
          await dataSource.updateRow(edited.copyWith(id: 'nope')),
          isFalse,
        );
        expect(await dataSource.updateRow(row()), isFalse);
        expect(database.tables['user_calculator_stores'], hasLength(1));
      });

      test(
        'a soft delete stamps the row and answers false for a stranger',
        () async {
          final stored = await dataSource.insertRow(row());
          expect(await dataSource.softDeleteRow('nope', later), isFalse);
          expect(await dataSource.softDeleteRow(stored.id!, later), isTrue);
          final rows = await dataSource.fetchRows(
            user,
            CalculatorStoreKind.density,
          );
          expect(rows.single.deletedAt, later);
          expect(rows.single.updatedAt, later);
          expect(rows.single.values, stored.values);
        },
      );
    });

    group('seed rows', () {
      test('the first write of a default inserts its row', () async {
        final stored = await dataSource.writeSeedRow(concrete);
        expect(stored.id, isNotNull);
        expect(await dataSource.fetchRows(user, CalculatorStoreKind.density), [
          stored,
        ]);
      });

      test('a second write of the same default rewrites that row', () async {
        final stored = await dataSource.writeSeedRow(concrete);
        final heavier = await dataSource.writeSeedRow(
          concrete.copyWith(
            values: {...concrete.values, 'pounds_per_cubic_yard': 4100},
            updatedAt: later,
          ),
        );
        expect(heavier.id, stored.id);
        final rows = await dataSource.fetchRows(
          user,
          CalculatorStoreKind.density,
        );
        expect(rows, hasLength(1));
        expect(rows.single.values['pounds_per_cubic_yard'], 4100);
        expect(rows.single.updatedAt, later);
      });

      test('a deleted default is brought back by writing it again', () async {
        final gone = await dataSource.writeSeedRow(
          concrete.copyWith(deletedAt: later),
        );
        final back = await dataSource.writeSeedRow(concrete);
        expect(back.id, gone.id);
        final rows = await dataSource.fetchRows(
          user,
          CalculatorStoreKind.density,
        );
        expect(rows.single.deletedAt, isNull);
      });

      test(
        'two writes of one default at once leave one row, not two',
        () async {
          await Future.wait([
            dataSource.writeSeedRow(concrete),
            dataSource.writeSeedRow(
              concrete.copyWith(values: {...concrete.values, 'position': 1}),
            ),
          ]);
          final rows = await dataSource.fetchRows(
            user,
            CalculatorStoreKind.density,
          );
          expect(rows, hasLength(1));
          expect(rows.single.values['position'], 1);
        },
      );

      test('another user\'s row of the same default, and another default, are '
          'left alone', () async {
        final theirs = await dataSource.writeSeedRow(
          concrete.copyWith(values: {...concrete.values, 'position': 9}),
        );
        final others = await dataSource.insertRow(
          row(userId: other, values: concrete.values),
        );
        final gravel = await dataSource.writeSeedRow(
          row(values: const {'seed': 'density_gravel', 'name': 'gravel'}),
        );
        expect(gravel.id, isNot(theirs.id));
        expect(await dataSource.fetchRows(user, CalculatorStoreKind.density), [
          theirs,
          gravel,
        ]);
        expect(await dataSource.fetchRows(other, CalculatorStoreKind.density), [
          others,
        ]);
      });

      test('a row without a seed cannot be written as a default', () async {
        await expectLater(dataSource.writeSeedRow(row()), throwsArgumentError);
        expect(
          await dataSource.fetchRows(user, CalculatorStoreKind.density),
          isEmpty,
        );
      });
    });

    group('watches', () {
      test('a watch emits now and after every change to the table', () async {
        final expectation = expectLater(
          dataSource
              .watchRows(user, CalculatorStoreKind.density)
              .map((rows) => rows.map((r) => r.deletedAt).toList()),
          emitsInOrder([
            isEmpty,
            [null],
            [later],
          ]),
        );
        final stored = await dataSource.insertRow(row());
        await dataSource.insertRow(row(kind: CalculatorStoreKind.waste));
        await dataSource.softDeleteRow(stored.id!, later);
        await expectation;
      });

      test('a watch sees a transaction land whole', () async {
        final expectation = expectLater(
          dataSource
              .watchRows(user, CalculatorStoreKind.density)
              .map((rows) => rows.map((r) => r.values['position']).toList()),
          emitsInOrder([
            isEmpty,
            [0],
            [1],
          ]),
        );
        await dataSource.writeSeedRow(concrete);
        await dataSource.writeSeedRow(
          concrete.copyWith(values: {...concrete.values, 'position': 1}),
        );
        await expectation;
      });
    });

    group('errors and lifecycle', () {
      test('a failing read throws through fetch and watch', () async {
        database.readError = StateError('locked');
        await expectLater(
          dataSource.fetchRows(user, CalculatorStoreKind.density),
          throwsStateError,
        );
        await expectLater(
          dataSource.watchRows(user, CalculatorStoreKind.density).first,
          throwsStateError,
        );
      });

      test('a failing write throws and stores nothing', () async {
        database.writeError = StateError('locked');
        await expectLater(dataSource.insertRow(row()), throwsStateError);
        await expectLater(dataSource.writeSeedRow(concrete), throwsStateError);
        database.writeError = null;
        expect(
          await dataSource.fetchRows(user, CalculatorStoreKind.density),
          isEmpty,
        );
      });

      test(
        'dispose ends the watches handed out and leaves the database usable',
        () async {
          final rows = dataSource.watchRows(user, CalculatorStoreKind.density);
          final ended = expectLater(rows, emitsInOrder([isEmpty, emitsDone]));
          await expectLater(rows, emits(isEmpty));
          await dataSource.dispose();
          await ended;
          expect(
            await dataSource.fetchRows(user, CalculatorStoreKind.density),
            isEmpty,
          );
        },
      );

      test('a watch taken after dispose answers once and ends', () async {
        await dataSource.dispose();
        expect(
          await dataSource.watchRows(user, CalculatorStoreKind.waste).toList(),
          [<CalculatorStoreRowDto>[]],
        );
      });
    });
  });
}

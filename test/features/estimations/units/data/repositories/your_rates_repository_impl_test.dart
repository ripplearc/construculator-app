import 'package:construculator/features/estimation/data/repositories/your_rates_repository_impl.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../../utils/fake_your_rates_database.dart';

void main() {
  group('YourRatesRepositoryImpl', () {
    late YourRatesRepositoryImpl repository;
    late FakeYourRatesDatabase database;

    const testCompanyId = 'company-1';

    Map<String, dynamic> row({
      required String id,
      String companyId = testCompanyId,
      String category = 'equipment',
      String itemName = 'Excavator',
      double rateAmount = 250.0,
      String rateCurrency = 'USD',
      String? unit = 'days',
      String? equipmentMethod = 'day',
      String? entryLabel,
      String savedAt = '2026-01-01T00:00:00.000Z',
    }) {
      return {
        'id': id,
        'company_id': companyId,
        'category': category,
        'item_name': itemName,
        'rate_amount': rateAmount,
        'rate_currency': rateCurrency,
        'unit': unit,
        'equipment_method': equipmentMethod,
        'entry_label': entryLabel,
        'saved_at': savedAt,
        'created_at': savedAt,
        'updated_at': savedAt,
      };
    }

    YourRateEntry buildEntry({
      String id = '',
      String itemName = 'Excavator',
      CostItemType category = CostItemType.equipment,
      double amount = 250.0,
      String? entryLabel,
      EquipmentPricingMethod method = EquipmentPricingMethod.day,
      DateTime? savedAt,
    }) {
      return YourRateEntry(
        id: id,
        companyId: testCompanyId,
        itemName: itemName,
        category: category,
        rate: Money(amount: amount),
        savedAt: savedAt ?? DateTime.parse('2026-01-05T00:00:00.000Z'),
        equipmentMethod: category == CostItemType.equipment ? method : null,
        entryLabel: entryLabel,
      );
    }

    setUpAll(() {
      database = FakeYourRatesDatabase();
      Modular.init(
        EstimationModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
          ),
        ),
      );
      Modular.replaceInstance<PowerSyncDatabaseWrapper>(database);
      repository =
          Modular.get<YourRatesRepository>() as YourRatesRepositoryImpl;
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      database.reset();
    });

    void seed(List<Map<String, dynamic>> rows) {
      rows.forEach(database.seedRow);
    }

    group('search', () {
      test(
        'empty query returns all rows for category, most recent first',
        () async {
          seed([
            row(id: 'r1', savedAt: '2026-01-01T00:00:00.000Z'),
            row(id: 'r2', savedAt: '2026-01-03T00:00:00.000Z'),
            row(id: 'r3', savedAt: '2026-01-02T00:00:00.000Z'),
          ]);

          final result = await repository.search(
            '',
            category: CostItemType.equipment,
            companyId: testCompanyId,
          );

          expect(result.isRight(), true);
          final entries = result.getRightOrNull()!;
          expect(entries.map((e) => e.id).toList(), ['r2', 'r3', 'r1']);
        },
      );

      test(
        'empty query with no category returns rows across categories',
        () async {
          seed([
            row(
              id: 'r1',
              category: 'equipment',
              savedAt: '2026-01-01T00:00:00.000Z',
            ),
            row(
              id: 'r2',
              category: 'material',
              savedAt: '2026-01-02T00:00:00.000Z',
            ),
          ]);

          final result = await repository.search('', companyId: testCompanyId);

          expect(result.isRight(), true);
          expect(result.getRightOrNull()!.length, 2);
        },
      );

      test(
        'non-empty query filters by case-insensitive item name substring',
        () async {
          seed([
            row(id: 'r1', itemName: 'Excavator'),
            row(id: 'r2', itemName: 'Bulldozer'),
            row(id: 'r3', itemName: 'Mini excavator'),
          ]);

          final result = await repository.search(
            'exc',
            category: CostItemType.equipment,
            companyId: testCompanyId,
          );

          expect(result.isRight(), true);
          expect(result.getRightOrNull()!.map((e) => e.itemName).toSet(), {
            'Excavator',
            'Mini excavator',
          });
        },
      );

      test(
        'matches a row when any typed word is in its name, ignoring case',
        () async {
          seed([
            row(id: 'r1', itemName: 'Mini excavator - 1.5 ton'),
            row(id: 'r2', itemName: 'Bulldozer'),
          ]);

          final result = await repository.search(
            'MINI Excavator 1.5t',
            category: CostItemType.equipment,
            companyId: testCompanyId,
          );

          expect(result.getRightOrNull()!.map((e) => e.id).toList(), ['r1']);
        },
      );

      test('treats a query of only spaces like an empty query', () async {
        seed([row(id: 'r1'), row(id: 'r2', itemName: 'Bulldozer')]);

        final result = await repository.search(
          '   ',
          category: CostItemType.equipment,
          companyId: testCompanyId,
        );

        expect(result.getRightOrNull(), hasLength(2));
      });

      test('caps an empty query at the limit, newest first', () async {
        seed([
          row(id: 'r1', savedAt: '2026-01-01T00:00:00.000Z'),
          row(id: 'r2', savedAt: '2026-01-03T00:00:00.000Z'),
          row(id: 'r3', savedAt: '2026-01-02T00:00:00.000Z'),
        ]);

        final result = await repository.search(
          '',
          category: CostItemType.equipment,
          limit: 2,
          companyId: testCompanyId,
        );

        expect(result.getRightOrNull()!.map((e) => e.id).toList(), [
          'r2',
          'r3',
        ]);
      });

      test(
        'ignores the limit once a query is given, so every match is returned',
        () async {
          seed([
            row(id: 'r1', itemName: 'Excavator 1'),
            row(id: 'r2', itemName: 'Excavator 2'),
            row(id: 'r3', itemName: 'Bulldozer'),
          ]);

          final result = await repository.search(
            'excavator',
            category: CostItemType.equipment,
            limit: 1,
            companyId: testCompanyId,
          );

          expect(result.getRightOrNull(), hasLength(2));
        },
      );

      test("keeps a second company's rows out of the result", () async {
        seed([
          row(id: 'mine', companyId: testCompanyId, itemName: 'Excavator'),
          row(id: 'theirs', companyId: 'company-2', itemName: 'Excavator'),
        ]);

        final result = await repository.search(
          '',
          category: CostItemType.equipment,
          companyId: testCompanyId,
        );

        expect(result.isRight(), true);
        expect(result.getRightOrNull()!.map((e) => e.id).toList(), ['mine']);
      });

      test(
        'reports a read the phone cannot do as a database failure',
        () async {
          database.getAllError = StateError('database locked');

          final result = await repository.search(
            '',
            category: CostItemType.equipment,
            companyId: testCompanyId,
          );

          expect(result.isLeft(), true);
          expect(
            result.getLeftOrNull(),
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.unexpectedDatabaseError,
            ),
          );
        },
      );
    });

    test('reports a stored row it cannot read as a parsing failure', () async {
      seed([
        row(id: 'broken').map(
          (key, value) => MapEntry(key, key == 'rate_amount' ? 'abc' : value),
        ),
      ]);

      final result = await repository.search(
        '',
        category: CostItemType.equipment,
        companyId: testCompanyId,
      );

      expect(
        result.getLeftOrNull(),
        isA<EstimationFailure>().having(
          (f) => f.errorType,
          'errorType',
          EstimationErrorType.parsingError,
        ),
      );
    });

    group('getByItemName', () {
      test(
        'returns the entry when exactly one row matches the grouping',
        () async {
          seed([row(id: 'r1', itemName: 'Excavator')]);

          final result = await repository.getByItemName(
            'Excavator',
            CostItemType.equipment,
            companyId: testCompanyId,
          );

          expect(result.isRight(), true);
          expect(result.getRightOrNull()?.id, 'r1');
        },
      );

      test(
        'matches the name without regard to capital letters or extra spaces',
        () async {
          seed([row(id: 'r1', itemName: 'Mini excavator')]);

          final result = await repository.getByItemName(
            '  MINI   Excavator ',
            CostItemType.equipment,
            companyId: testCompanyId,
          );

          expect(result.getRightOrNull()?.id, 'r1');
        },
      );

      test('companyId actually keeps a same-name row in a second company from '
          'being returned', () async {
        seed([
          row(id: 'theirs', companyId: 'company-2', itemName: 'Excavator'),
        ]);

        final result = await repository.getByItemName(
          'Excavator',
          CostItemType.equipment,
          companyId: testCompanyId,
        );

        expect(result.isRight(), true);
        expect(result.getRightOrNull(), isNull);
      });

      test('returns Right(null) when no row matches', () async {
        final result = await repository.getByItemName(
          'Excavator',
          CostItemType.equipment,
          companyId: testCompanyId,
        );

        expect(result.isRight(), true);
        expect(result.getRightOrNull(), isNull);
      });

      test(
        'returns Right(null) when multiple rows match the grouping',
        () async {
          seed([
            row(id: 'r1', itemName: 'Excavator', entryLabel: 'Supplier A'),
            row(id: 'r2', itemName: 'Excavator', entryLabel: 'Supplier B'),
          ]);

          final result = await repository.getByItemName(
            'Excavator',
            CostItemType.equipment,
            companyId: testCompanyId,
          );

          expect(result.isRight(), true);
          expect(result.getRightOrNull(), isNull);
        },
      );
    });

    group('a blank company id', () {
      test('search returns a failure and reads nothing', () async {
        final result = await repository.search('', companyId: '  ');

        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.permissionDenied,
          ),
        );
        expect(database.getAllCalls, isEmpty);
      });

      test('getByItemName returns a failure and reads nothing', () async {
        final result = await repository.getByItemName(
          'Excavator',
          CostItemType.equipment,
          companyId: '',
        );

        expect(result.isLeft(), true);
        expect(database.getAllCalls, isEmpty);
      });

      test('save returns a failure and reads and writes nothing', () async {
        final result = await repository.save(
          buildEntry().copyWith(companyId: ''),
        );

        expect(result.isLeft(), true);
        expect(database.getAllCalls, isEmpty);
        expect(database.insertedRows, isEmpty);
        expect(database.updatedRowIds, isEmpty);
      });
    });

    group('save', () {
      test(
        'a saved rate is found by the next search, with no signal',
        () async {
          await repository.save(buildEntry(itemName: 'Skid steer'));

          final result = await repository.search(
            'skid',
            category: CostItemType.equipment,
            companyId: testCompanyId,
          );

          expect(result.getRightOrNull()!.map((e) => e.itemName), [
            'Skid steer',
          ]);
        },
      );

      test('inserts a new row when the grouping is empty', () async {
        final entry = buildEntry();

        final result = await repository.save(entry);

        expect(result.isRight(), true);
        expect(database.insertedRows, hasLength(1));
        expect(database.updatedRowIds, isEmpty);
      });

      test(
        'overwrites the existing row when an unlabeled entry collides with an unlabeled row',
        () async {
          seed([row(id: 'existing', rateAmount: 100.0)]);
          final entry = buildEntry(amount: 300.0);

          final result = await repository.save(entry);

          expect(result.isRight(), true);
          final updatedIds = database.updatedRowIds;
          expect(updatedIds.length, 1);
          expect(updatedIds.first, 'existing');
          expect(database.insertedRows, isEmpty);
        },
      );

      test(
        'overwrites the matching row when a labeled entry collides with the same label',
        () async {
          seed([
            row(id: 'other-label', entryLabel: 'Supplier A', rateAmount: 100.0),
            row(id: 'same-label', entryLabel: 'Supplier B', rateAmount: 200.0),
          ]);
          final entry = buildEntry(entryLabel: 'Supplier B', amount: 999.0);

          final result = await repository.save(entry);

          expect(result.isRight(), true);
          final updatedIds = database.updatedRowIds;
          expect(updatedIds.length, 1);
          expect(updatedIds.first, 'same-label');
        },
      );

      test(
        'inserts a new distinct row when a labeled entry has no matching label',
        () async {
          seed([row(id: 'existing', entryLabel: 'Supplier A')]);
          final entry = buildEntry(entryLabel: 'Supplier B');

          final result = await repository.save(entry);

          expect(result.isRight(), true);
          expect(database.insertedRows, hasLength(1));
          expect(database.updatedRowIds, isEmpty);
        },
      );

      test(
        'rejects an unlabeled save when the grouping has one labeled row',
        () async {
          seed([row(id: 'existing', entryLabel: 'Supplier A')]);
          final entry = buildEntry();

          final result = await repository.save(entry);

          expect(result.isLeft(), true);
          expect(
            result.getLeftOrNull(),
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.duplicateEntry,
            ),
          );
          expect(database.insertedRows, isEmpty);
          expect(database.updatedRowIds, isEmpty);
        },
      );

      test(
        'rejects an unlabeled save when the grouping has multiple labeled rows',
        () async {
          seed([
            row(id: 'r1', entryLabel: 'Supplier A'),
            row(id: 'r2', entryLabel: 'Supplier B'),
          ]);
          final entry = buildEntry();

          final result = await repository.save(entry);

          expect(result.isLeft(), true);
          expect(
            result.getLeftOrNull(),
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.duplicateEntry,
            ),
          );
        },
      );

      test('rejects an empty-string label the same as null when the grouping '
          'has a labeled row', () async {
        seed([row(id: 'existing', entryLabel: 'Supplier A')]);
        final entry = buildEntry(entryLabel: '');

        final result = await repository.save(entry);

        expect(result.isLeft(), true);
        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.duplicateEntry,
          ),
        );
        expect(database.insertedRows, isEmpty);
      });

      test('treats a whitespace-only label as null when matching an existing '
          'unlabeled row', () async {
        seed([row(id: 'existing', entryLabel: null, rateAmount: 100.0)]);
        final entry = buildEntry(entryLabel: '   ', amount: 999.0);

        final result = await repository.save(entry);

        expect(result.isRight(), true);
        final updatedIds = database.updatedRowIds;
        expect(updatedIds.length, 1);
        expect(updatedIds.first, 'existing');
        // The normalized (null) label is what gets persisted, not the
        // literal whitespace.
        final stored = await repository.search(
          '',
          category: CostItemType.equipment,
          companyId: testCompanyId,
        );
        expect(stored.getRightOrNull()!.single.entryLabel, isNull);
      });

      test(
        'saves a Job price next to a Day price of the same name, leaving the '
        'Day row alone',
        () async {
          seed([
            row(id: 'day-row', itemName: 'Mini excavator', rateAmount: 145),
          ]);
          final entry = buildEntry(
            itemName: 'Mini excavator',
            amount: 520,
            method: EquipmentPricingMethod.job,
          );

          final result = await repository.save(entry);

          expect(result.isRight(), true);
          expect(database.insertedRows, hasLength(1));
          expect(database.updatedRowIds, isEmpty);
        },
      );

      test(
        'saves a Day price next to a Job price of the same name, leaving the '
        'Job row alone',
        () async {
          seed([
            row(
              id: 'job-row',
              itemName: 'Mini excavator',
              rateAmount: 520,
              equipmentMethod: 'job',
            ),
          ]);

          final result = await repository.save(
            buildEntry(itemName: 'Mini excavator', amount: 145),
          );

          expect(result.isRight(), true);
          expect(database.insertedRows, hasLength(1));
          expect(database.updatedRowIds, isEmpty);
        },
      );

      test(
        'overwrites only the row of the same pricing method when both exist',
        () async {
          seed([
            row(id: 'day-row', itemName: 'Mini excavator', rateAmount: 145),
            row(
              id: 'job-row',
              itemName: 'Mini excavator',
              rateAmount: 520,
              equipmentMethod: 'job',
            ),
          ]);

          final result = await repository.save(
            buildEntry(
              itemName: 'Mini excavator',
              amount: 150,
              method: EquipmentPricingMethod.job,
            ),
          );

          expect(result.isRight(), true);
          final updatedIds = database.updatedRowIds;
          expect(updatedIds, hasLength(1));
          expect(updatedIds.first, 'job-row');
          expect(database.insertedRows, isEmpty);
        },
      );

      test(
        'replaces the saved row when the name differs only by capital letters '
        'or extra spaces',
        () async {
          seed([
            row(id: 'existing', itemName: 'Mini excavator', rateAmount: 145),
          ]);

          final result = await repository.save(
            buildEntry(itemName: '  mini   EXCAVATOR ', amount: 160),
          );

          expect(result.isRight(), true);
          final updatedIds = database.updatedRowIds;
          expect(updatedIds, hasLength(1));
          expect(updatedIds.first, 'existing');
          expect(database.insertedRows, isEmpty);
        },
      );

      test('saves the name trimmed', () async {
        final result = await repository.save(
          buildEntry(itemName: '  Backhoe  '),
        );

        expect(result.isRight(), true);
        expect(database.insertedRows.single['item_name'], 'Backhoe');
      });

      test(
        'scopes the collision check to category, name and pricing method',
        () async {
          seed([
            row(id: 'other-category', category: 'material', entryLabel: null),
            row(id: 'other-item', itemName: 'Bulldozer', entryLabel: null),
            row(id: 'other-method', equipmentMethod: 'job', entryLabel: null),
          ]);
          final entry = buildEntry();

          final result = await repository.save(entry);

          expect(result.isRight(), true);
          expect(database.insertedRows, hasLength(1));
        },
      );

      test('an unlabeled row in a second company does not collide with this '
          "entry's own save, so it inserts rather than overwriting", () async {
        seed([
          row(
            id: 'theirs',
            companyId: 'company-2',
            entryLabel: null,
            rateAmount: 100.0,
          ),
        ]);
        final entry = buildEntry(amount: 300.0);

        final result = await repository.save(entry);

        expect(result.isRight(), true);
        expect(database.insertedRows, hasLength(1));
        expect(database.updatedRowIds, isEmpty);
      });

      test(
        'reports a write the phone cannot do as a database failure',
        () async {
          database.executeError = StateError('disk full');

          final result = await repository.save(buildEntry());

          expect(result.isLeft(), true);
          expect(
            result.getLeftOrNull(),
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.unexpectedDatabaseError,
            ),
          );
        },
      );
    });
  });
}

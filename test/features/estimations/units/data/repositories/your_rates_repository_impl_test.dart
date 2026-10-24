import 'package:construculator/features/estimation/data/repositories/your_rates_repository_impl.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/refused_your_rate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/powersync/models/your_rate_refusal_key.dart';
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
      String? lastUsedAt,
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
        'last_used_at': lastUsedAt,
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
      var entrySavedAt = DateTime.parse('2026-01-05T00:00:00.000Z');
      if (savedAt != null) {
        entrySavedAt = savedAt;
      }
      return YourRateEntry(
        id: id,
        companyId: testCompanyId,
        itemName: itemName,
        category: category,
        rate: Money(amount: amount),
        savedAt: entrySavedAt,
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
          companyId: testCompanyId,
          limit: 2,
        );

        expect(result.getRightOrNull()!.map((e) => e.id).toList(), [
          'r2',
          'r3',
        ]);
      });

      test('orders rows with the same last use by their save date', () async {
        seed([
          row(
            id: 'saved-earlier',
            savedAt: '2026-01-01T00:00:00.000Z',
            lastUsedAt: '2026-01-09T00:00:00.000Z',
          ),
          row(
            id: 'saved-later',
            savedAt: '2026-01-02T00:00:00.000Z',
            lastUsedAt: '2026-01-09T00:00:00.000Z',
          ),
        ]);

        final result = await repository.search(
          '',
          category: CostItemType.equipment,
          companyId: testCompanyId,
        );

        expect(result.getRightOrNull()!.map((e) => e.id).toList(), [
          'saved-later',
          'saved-earlier',
        ]);
      });

      test('puts a rate used after a newer save above that save', () async {
        seed([
          row(id: 'saved-later', savedAt: '2026-01-05T00:00:00.000Z'),
          row(
            id: 'used-later',
            savedAt: '2026-01-01T00:00:00.000Z',
            lastUsedAt: '2026-01-06T00:00:00.000Z',
          ),
        ]);

        final result = await repository.search(
          '',
          category: CostItemType.equipment,
          companyId: testCompanyId,
        );

        expect(result.getRightOrNull()!.map((e) => e.id).toList(), [
          'used-later',
          'saved-later',
        ]);
      });

      test('sorts a never-used rate by its save date', () async {
        seed([
          row(
            id: 'used-earlier',
            savedAt: '2026-01-01T00:00:00.000Z',
            lastUsedAt: '2026-01-02T00:00:00.000Z',
          ),
          row(id: 'saved-later', savedAt: '2026-01-03T00:00:00.000Z'),
        ]);

        final result = await repository.search(
          '',
          category: CostItemType.equipment,
          companyId: testCompanyId,
        );

        expect(result.getRightOrNull()!.map((e) => e.id).toList(), [
          'saved-later',
          'used-earlier',
        ]);
      });

      test('applies the limit after ordering by last use', () async {
        seed([
          row(id: 'r1', savedAt: '2026-01-03T00:00:00.000Z'),
          row(id: 'r2', savedAt: '2026-01-02T00:00:00.000Z'),
          row(
            id: 'r3',
            savedAt: '2026-01-01T00:00:00.000Z',
            lastUsedAt: '2026-01-09T00:00:00.000Z',
          ),
        ]);

        final result = await repository.search(
          '',
          category: CostItemType.equipment,
          companyId: testCompanyId,
          limit: 1,
        );

        expect(result.getRightOrNull()!.map((e) => e.id).toList(), ['r3']);
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
          expect(result.getRightOrNull()!.id, 'r1');
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

          expect(result.getRightOrNull()!.id, 'r1');
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

      test('rejects an unlabeled save when the grouping has an unlabeled row, '
          'leaving the saved price alone', () async {
        seed([row(id: 'existing', rateAmount: 100.0)]);

        final result = await repository.save(buildEntry(amount: 300.0));

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
      });

      test(
        'leaves last_used_at out of the saved body, so a new save records no use',
        () async {
          await repository.save(buildEntry(amount: 300.0));

          final body = database.insertedRows.single;
          expect(body.containsKey('last_used_at'), isFalse);
          expect(body['rate_amount'], 300.0);
        },
      );

      test(
        'rejects a labeled save whose label the grouping already has, leaving '
        'the saved price alone',
        () async {
          seed([
            row(id: 'other-label', entryLabel: 'Supplier A', rateAmount: 100.0),
            row(id: 'same-label', entryLabel: 'Supplier B', rateAmount: 200.0),
          ]);

          final result = await repository.save(
            buildEntry(entryLabel: 'Supplier B', amount: 999.0),
          );

          expect(result.isLeft(), true);
          expect(
            result.getLeftOrNull(),
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.duplicateLabel,
            ),
          );
          expect(database.insertedRows, isEmpty);
          expect(database.updatedRowIds, isEmpty);
        },
      );

      test(
        'treats a label that differs only by capital letters or extra spaces '
        'as the same label',
        () async {
          seed([
            row(id: 'existing', entryLabel: 'Supplier A', rateAmount: 100),
          ]);

          final result = await repository.save(
            buildEntry(entryLabel: '  supplier   a ', amount: 150),
          );

          expect(result.isLeft(), true);
          expect(
            result.getLeftOrNull(),
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.duplicateLabel,
            ),
          );
          expect(database.insertedRows, isEmpty);
          expect(database.updatedRowIds, isEmpty);
        },
      );

      test('saves a label that another pricing method of the same name already '
          'has', () async {
        seed([row(id: 'day-row', entryLabel: 'Supplier A', rateAmount: 145)]);

        final result = await repository.save(
          buildEntry(
            entryLabel: 'Supplier A',
            amount: 520,
            method: EquipmentPricingMethod.job,
          ),
        );

        expect(result.isRight(), true);
        expect(database.insertedRows, hasLength(1));
        expect(database.updatedRowIds, isEmpty);
      });

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

      test('treats a whitespace-only label as no label and rejects it when the '
          'grouping has an unlabeled row', () async {
        seed([row(id: 'existing', entryLabel: null, rateAmount: 100.0)]);

        final result = await repository.save(
          buildEntry(entryLabel: '   ', amount: 999.0),
        );

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

      test('rejects an unlabeled save when the name differs only by capital '
          'letters or extra spaces from a saved unlabeled row', () async {
        seed([
          row(id: 'existing', itemName: 'Mini excavator', rateAmount: 145),
        ]);

        final result = await repository.save(
          buildEntry(itemName: '  mini   EXCAVATOR ', amount: 160),
        );

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
      });

      test('rejects a second unlabeled save after a labeled save added a row, '
          'leaving the unlabeled price alone', () async {
        seed([
          row(id: 'unlabeled', rateAmount: 145),
          row(id: 'labeled', entryLabel: 'Supplier A', rateAmount: 160),
        ]);

        final result = await repository.save(buildEntry(amount: 170));

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
      });

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

    group('recordRateUse', () {
      test('puts the used rate above a newer save', () async {
        seed([
          row(id: 'older', savedAt: '2026-01-01T00:00:00.000Z'),
          row(id: 'newer', savedAt: '2026-01-10T00:00:00.000Z'),
        ]);

        final recorded = await repository.recordRateUse('older');
        final result = await repository.search(
          '',
          category: CostItemType.equipment,
          companyId: testCompanyId,
        );

        expect(recorded.isRight(), true);
        expect(result.getRightOrNull()!.map((e) => e.id).toList(), [
          'older',
          'newer',
        ]);
      });

      test('keeps the saved price and label of the used rate', () async {
        seed([row(id: 'used', rateAmount: 250.0, entryLabel: 'Supplier A')]);

        await repository.recordRateUse('used');
        final result = await repository.search(
          '',
          category: CostItemType.equipment,
          companyId: testCompanyId,
        );

        final entry = result.getRightOrNull()!.single;
        expect(entry.rate.amount, 250.0);
        expect(entry.entryLabel, 'Supplier A');
      });

      test(
        'reports a write the phone cannot do as a database failure',
        () async {
          seed([row(id: 'used')]);
          database.executeError = StateError('disk full');

          final result = await repository.recordRateUse('used');

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

    group('after the server refused a default', () {
      final excavatorKey = YourRateRefusalKey.of('Excavator', 'day');

      void refuse({double refused = 450.0, double? accepted = 400.0}) {
        database.seedRefusal({
          'id': excavatorKey,
          'item_name': 'Excavator',
          'equipment_method': 'day',
          'refused_amount': refused,
          'accepted_amount': accepted,
          'shown_at': null,
        });
      }

      Future<List<YourRateEntry>> lookUp({int? limit}) async =>
          (await repository.search(
            '',
            category: CostItemType.equipment,
            companyId: testCompanyId,
            limit: limit,
          )).getRightOrNull()!;

      test('the lookup shows the last accepted price', () async {
        seed([row(id: 'r1', rateAmount: 450.0)]);
        refuse();

        final entries = await lookUp();

        expect(entries.single.rate.amount, 400.0);
      });

      test('a saved item lookup shows the last accepted price', () async {
        seed([row(id: 'r1', rateAmount: 450.0)]);
        refuse();

        final result = await repository.getByItemName(
          'Excavator',
          CostItemType.equipment,
          companyId: testCompanyId,
        );

        expect(result.getRightOrNull()!.rate.amount, 400.0);
      });

      test('the lookup leaves out an item the server never accepted', () async {
        seed([row(id: 'r1', rateAmount: 450.0)]);
        refuse(accepted: null);

        expect(await lookUp(), isEmpty);
      });

      test(
        'the lookup shows the phone price once sync has put the server price back',
        () async {
          seed([row(id: 'r1', rateAmount: 400.0)]);
          refuse();

          final entries = await lookUp();

          expect(entries.single.rate.amount, 400.0);
        },
      );

      test(
        'the lookup shows a price changed on another phone after the refusal',
        () async {
          seed([row(id: 'r1', rateAmount: 520.0)]);
          refuse();

          final entries = await lookUp();

          expect(entries.single.rate.amount, 520.0);
        },
      );

      test('another item keeps its own price', () async {
        seed([
          row(id: 'r1', rateAmount: 450.0),
          row(id: 'r2', itemName: 'Dozer', rateAmount: 900.0),
        ]);
        refuse();

        final entries = await lookUp();

        expect(
          {for (final entry in entries) entry.itemName: entry.rate.amount},
          {'Excavator': 400.0, 'Dozer': 900.0},
        );
      });

      test('a limit counts only the items still shown', () async {
        seed([
          row(id: 'r1', rateAmount: 450.0, savedAt: '2026-01-03T00:00:00.000Z'),
          row(id: 'r2', itemName: 'Dozer', savedAt: '2026-01-02T00:00:00.000Z'),
        ]);
        refuse(accepted: null);

        final entries = await lookUp(limit: 1);

        expect(entries.map((entry) => entry.itemName), ['Dozer']);
      });

      test('a save the repository rejects keeps the refusal', () async {
        seed([row(id: 'r1', rateAmount: 450.0)]);
        refuse();

        final result = await repository.save(buildEntry(amount: 500.0));

        expect(result.isLeft(), isTrue);
        expect(database.refusalRow(excavatorKey), isNotNull);
        final entries = await lookUp();
        expect(entries.single.rate.amount, 400.0);
      });

      test(
        'saving a first default for an item the server never accepted forgets '
        'the refusal',
        () async {
          refuse(accepted: null);

          await repository.save(buildEntry(amount: 500.0));

          expect(database.refusalRow(excavatorKey), isNull);
        },
      );

      test(
        'saving a new labelled default for the item forgets the refusal',
        () async {
          seed([row(id: 'r1', rateAmount: 300.0, entryLabel: 'Supplier A')]);
          refuse(refused: 999.0);

          await repository.save(
            buildEntry(amount: 500.0, entryLabel: 'Supplier B'),
          );

          expect(database.refusalRow(excavatorKey), isNull);
        },
      );

      test('saving a default for another item keeps the refusal', () async {
        refuse();

        await repository.save(buildEntry(itemName: 'Dozer', amount: 900.0));

        expect(database.refusalRow(excavatorKey), isNotNull);
      });
      group('watchUnshownRefusal', () {
        Stream<RefusedYourRate?> refusalOfExcavator() => repository
            .watchUnshownRefusal('Excavator', EquipmentPricingMethod.day)
            .map((result) => result.getRightOrNull());

        test('emits nothing to show while the server refused nothing', () {
          expect(refusalOfExcavator(), emits(isNull));
        });

        test('emits the refused and the accepted amounts', () {
          refuse();

          expect(
            refusalOfExcavator(),
            emits(
              const RefusedYourRate(
                itemName: 'Excavator',
                equipmentMethod: EquipmentPricingMethod.day,
                refusedAmount: 450.0,
                acceptedAmount: 400.0,
              ),
            ),
          );
        });

        test('emits no accepted amount when the server never kept one', () {
          refuse(accepted: null);

          expect(
            refusalOfExcavator(),
            emits(
              isA<RefusedYourRate>().having(
                (refusal) => refusal.acceptedAmount,
                'acceptedAmount',
                isNull,
              ),
            ),
          );
        });

        test('emits the refusal as soon as the upload step records it', () {
          final emissions = expectLater(
            refusalOfExcavator(),
            emitsInOrder([isNull, isA<RefusedYourRate>()]),
          );

          refuse();

          return emissions;
        });

        test('stops emitting the refusal once it was marked shown', () async {
          refuse();

          final emissions = expectLater(
            refusalOfExcavator(),
            emitsInOrder([isA<RefusedYourRate>(), isNull]),
          );

          await repository.markRefusalShown(
            'Excavator',
            EquipmentPricingMethod.day,
          );

          await emissions;
        });

        test('does not emit a refusal that was shown before a restart', () {
          database.seedRefusal({
            'id': excavatorKey,
            'item_name': 'Excavator',
            'equipment_method': 'day',
            'refused_amount': 450.0,
            'accepted_amount': 400.0,
            'shown_at': '2026-10-07T09:00:00.000Z',
          });

          expect(refusalOfExcavator(), emits(isNull));
        });

        test('keeps the other pricing method of the item unaffected', () {
          refuse();

          expect(
            repository
                .watchUnshownRefusal('Excavator', EquipmentPricingMethod.job)
                .map((result) => result.getRightOrNull()),
            emits(isNull),
          );
        });

        test('reports a failed read of the phone and keeps watching', () async {
          final emissions = expectLater(
            repository
                .watchUnshownRefusal('Excavator', EquipmentPricingMethod.day)
                .map((result) => result.getLeftOrNull()),
            emitsInOrder([
              isNull,
              isA<EstimationFailure>().having(
                (f) => f.errorType,
                'errorType',
                EstimationErrorType.unexpectedDatabaseError,
              ),
              isNull,
            ]),
          );

          database.failRefusalWatches(StateError('disk full'));
          refuse();

          await emissions;
        });

        test(
          'stops emitting once a first default is saved for the item',
          () async {
            refuse(accepted: null);

            final emissions = expectLater(
              refusalOfExcavator(),
              emitsInOrder([isA<RefusedYourRate>(), isNull]),
            );

            await repository.save(buildEntry(amount: 500.0));

            await emissions;
          },
        );
      });

      test('marking an item without a refusal shown succeeds', () async {
        final result = await repository.markRefusalShown(
          'Dozer',
          EquipmentPricingMethod.day,
        );

        expect(result.isRight(), isTrue);
        expect(database.refusalRow(excavatorKey), isNull);
      });

      test('marking shown fails when the phone cannot write', () async {
        database.executeError = StateError('disk full');

        final result = await repository.markRefusalShown(
          'Excavator',
          EquipmentPricingMethod.day,
        );

        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.unexpectedDatabaseError,
          ),
        );
      });
    });
  });
}

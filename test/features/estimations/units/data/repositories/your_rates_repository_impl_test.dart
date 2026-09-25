import 'package:construculator/features/estimation/data/repositories/your_rates_repository_impl.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('YourRatesRepositoryImpl', () {
    late YourRatesRepositoryImpl repository;
    late FakeSupabaseWrapper fakeSupabaseWrapper;

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
      DateTime? savedAt,
    }) {
      return YourRateEntry(
        id: id,
        companyId: testCompanyId,
        itemName: itemName,
        category: category,
        rate: Money(amount: amount),
        savedAt: savedAt ?? DateTime.parse('2026-01-05T00:00:00.000Z'),
        equipmentMethod: category == CostItemType.equipment
            ? EquipmentPricingMethod.day
            : null,
        entryLabel: entryLabel,
      );
    }

    setUpAll(() {
      Modular.init(
        EstimationModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
          ),
        ),
      );
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      repository =
          Modular.get<YourRatesRepository>() as YourRatesRepositoryImpl;
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
    });

    void seed(List<Map<String, dynamic>> rows) {
      fakeSupabaseWrapper.addTableData(DatabaseConstants.yourRatesTable, rows);
    }

    group('search', () {
      test('empty query returns all rows for category, most recent first', () async {
        seed([
          row(id: 'r1', savedAt: '2026-01-01T00:00:00.000Z'),
          row(id: 'r2', savedAt: '2026-01-03T00:00:00.000Z'),
          row(id: 'r3', savedAt: '2026-01-02T00:00:00.000Z'),
        ]);

        final result = await repository.search('', category: CostItemType.equipment);

        expect(result.isRight(), true);
        final entries = result.getRightOrNull()!;
        expect(entries.map((e) => e.id).toList(), ['r2', 'r3', 'r1']);
      });

      test('empty query with no category returns rows across categories', () async {
        seed([
          row(id: 'r1', category: 'equipment', savedAt: '2026-01-01T00:00:00.000Z'),
          row(id: 'r2', category: 'material', savedAt: '2026-01-02T00:00:00.000Z'),
        ]);

        final result = await repository.search('');

        expect(result.isRight(), true);
        expect(result.getRightOrNull()!.length, 2);
      });

      test('non-empty query filters by case-insensitive item name substring', () async {
        seed([
          row(id: 'r1', itemName: 'Excavator'),
          row(id: 'r2', itemName: 'Bulldozer'),
          row(id: 'r3', itemName: 'Mini excavator'),
        ]);

        final result = await repository.search('exc', category: CostItemType.equipment);

        expect(result.isRight(), true);
        expect(
          result.getRightOrNull()!.map((e) => e.itemName).toSet(),
          {'Excavator', 'Mini excavator'},
        );
      });

      test('maps a generic exception to unexpectedError failure', () async {
        fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;

        final result = await repository.search('', category: CostItemType.equipment);

        expect(result.isLeft(), true);
        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.unexpectedError,
          ),
        );
      });
    });

    group('getByItemName', () {
      test('returns the entry when exactly one row matches the grouping', () async {
        seed([row(id: 'r1', itemName: 'Excavator')]);

        final result = await repository.getByItemName(
          'Excavator',
          CostItemType.equipment,
        );

        expect(result.isRight(), true);
        expect(result.getRightOrNull()?.id, 'r1');
      });

      test('returns Right(null) when no row matches', () async {
        final result = await repository.getByItemName(
          'Excavator',
          CostItemType.equipment,
        );

        expect(result.isRight(), true);
        expect(result.getRightOrNull(), isNull);
      });

      test('returns Right(null) when multiple rows match the grouping', () async {
        seed([
          row(id: 'r1', itemName: 'Excavator', entryLabel: 'Supplier A'),
          row(id: 'r2', itemName: 'Excavator', entryLabel: 'Supplier B'),
        ]);

        final result = await repository.getByItemName(
          'Excavator',
          CostItemType.equipment,
        );

        expect(result.isRight(), true);
        expect(result.getRightOrNull(), isNull);
      });
    });

    group('save', () {
      test('inserts a new row when the grouping is empty', () async {
        final entry = buildEntry();

        final result = await repository.save(entry);

        expect(result.isRight(), true);
        final calls = fakeSupabaseWrapper.getMethodCallsFor('insert');
        expect(calls.length, 1);
        expect(fakeSupabaseWrapper.getMethodCallsFor('update'), isEmpty);
      });

      test(
        'overwrites the existing row when an unlabeled entry collides with an unlabeled row',
        () async {
          seed([row(id: 'existing', rateAmount: 100.0)]);
          final entry = buildEntry(amount: 300.0);

          final result = await repository.save(entry);

          expect(result.isRight(), true);
          final updateCalls = fakeSupabaseWrapper.getMethodCallsFor('update');
          expect(updateCalls.length, 1);
          expect(updateCalls.first['filterValue'], 'existing');
          expect(fakeSupabaseWrapper.getMethodCallsFor('insert'), isEmpty);
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
          final updateCalls = fakeSupabaseWrapper.getMethodCallsFor('update');
          expect(updateCalls.length, 1);
          expect(updateCalls.first['filterValue'], 'same-label');
        },
      );

      test(
        'inserts a new distinct row when a labeled entry has no matching label',
        () async {
          seed([row(id: 'existing', entryLabel: 'Supplier A')]);
          final entry = buildEntry(entryLabel: 'Supplier B');

          final result = await repository.save(entry);

          expect(result.isRight(), true);
          expect(fakeSupabaseWrapper.getMethodCallsFor('insert'), hasLength(1));
          expect(fakeSupabaseWrapper.getMethodCallsFor('update'), isEmpty);
        },
      );

      test(
        'rejects an unlabeled save when the grouping has one labeled row '
        '(the case a naive 23505 catch would miss)',
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
          expect(fakeSupabaseWrapper.getMethodCallsFor('insert'), isEmpty);
          expect(fakeSupabaseWrapper.getMethodCallsFor('update'), isEmpty);
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

      test(
        'rejects an empty-string label the same as null when the grouping '
        'has a labeled row',
        () async {
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
          expect(fakeSupabaseWrapper.getMethodCallsFor('insert'), isEmpty);
        },
      );

      test(
        'treats a whitespace-only label as null when matching an existing '
        'unlabeled row',
        () async {
          seed([row(id: 'existing', entryLabel: null, rateAmount: 100.0)]);
          final entry = buildEntry(entryLabel: '   ', amount: 999.0);

          final result = await repository.save(entry);

          expect(result.isRight(), true);
          final updateCalls = fakeSupabaseWrapper.getMethodCallsFor('update');
          expect(updateCalls.length, 1);
          expect(updateCalls.first['filterValue'], 'existing');
          // The normalized (null) label is what gets persisted, not the
          // literal whitespace.
          expect(updateCalls.first['data']['entry_label'], isNull);
        },
      );

      test('scopes the collision check to category and item name only', () async {
        seed([
          row(id: 'other-category', category: 'material', entryLabel: null),
          row(id: 'other-item', itemName: 'Bulldozer', entryLabel: null),
        ]);
        final entry = buildEntry();

        final result = await repository.save(entry);

        // Neither seeded row shares this entry's (category, itemName)
        // grouping, so this is a fresh insert, not a collision.
        expect(result.isRight(), true);
        expect(fakeSupabaseWrapper.getMethodCallsFor('insert'), hasLength(1));
      });

      test('maps an RLS violation (42501) to permissionDenied', () async {
        fakeSupabaseWrapper.shouldThrowOnInsert = true;
        fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.postgrest;
        fakeSupabaseWrapper.postgrestErrorCode = PostgresErrorCode.rlsViolation;

        final result = await repository.save(buildEntry());

        expect(result.isLeft(), true);
        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.permissionDenied,
          ),
        );
      });

      test(
        'maps a unique-index violation (23505) on insert to duplicateEntry as a '
        'defense-in-depth fallback',
        () async {
          fakeSupabaseWrapper.shouldThrowOnInsert = true;
          fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode = PostgresErrorCode.uniqueViolation;

          final result = await repository.save(buildEntry());

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

      test('maps a generic exception to unexpectedError', () async {
        fakeSupabaseWrapper.shouldThrowOnInsert = true;

        final result = await repository.save(buildEntry());

        expect(result.isLeft(), true);
        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.unexpectedError,
          ),
        );
      });

      test('maps a connection error to connectionError', () async {
        fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        fakeSupabaseWrapper.selectMatchExceptionType = SupabaseExceptionType.socket;

        final result = await repository.save(buildEntry());

        expect(result.isLeft(), true);
        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.connectionError,
          ),
        );
      });

      test('maps a timeout to timeoutError', () async {
        fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        fakeSupabaseWrapper.selectMatchExceptionType = SupabaseExceptionType.timeout;

        final result = await repository.save(buildEntry());

        expect(result.isLeft(), true);
        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.timeoutError,
          ),
        );
      });
    });
  });
}

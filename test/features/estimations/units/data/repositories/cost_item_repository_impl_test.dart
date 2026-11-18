import 'package:construculator/features/estimation/data/repositories/cost_item_repository_impl.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
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
import '../../../helpers/cost_item_test_data_map_factory.dart';

void main() {
  group('CostItemRepositoryImpl', () {
    late CostItemRepositoryImpl repository;
    late FakeSupabaseWrapper fakeSupabaseWrapper;

    final testItem = MaterialCostItem(
      id: 'item-1',
      estimateId: 'estimate-1',
      itemName: 'Cement',
      calculation: {},
      itemTotalCost: 100.0,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      currency: 'USD',
      unitPrice: const Money(amount: 10.0),
      quantity: const Quantity(value: 10.0, unit: Unit.bags),
      rateStatus: RateStatus.ownRateConfirmed,
      quantityProvenance: QuantityProvenance.manual,
    );

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
      repository = Modular.get<CostItemRepository>() as CostItemRepositoryImpl;
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
    });

    group('createCostItem', () {
      test('returns Right with created entity on success', () async {
        final result = await repository.createCostItem(testItem);

        expect(result.isRight(), true);
        expect(result.getRightOrNull(), isA<MaterialCostItem>());
      });

      test('maps TimeoutException to timeoutError failure', () async {
        fakeSupabaseWrapper.shouldThrowOnInsert = true;
        fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.timeout;

        final result = await repository.createCostItem(testItem);

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

      test('maps SocketException to connectionError failure', () async {
        fakeSupabaseWrapper.shouldThrowOnInsert = true;
        fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.socket;

        final result = await repository.createCostItem(testItem);

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

      test('maps TypeError to parsingError failure', () async {
        fakeSupabaseWrapper.shouldThrowOnInsert = true;
        fakeSupabaseWrapper.insertExceptionType = SupabaseExceptionType.type;

        final result = await repository.createCostItem(testItem);

        expect(result.isLeft(), true);
        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.parsingError,
          ),
        );
      });

      test('maps unexpected exception to unexpectedError failure', () async {
        fakeSupabaseWrapper.shouldThrowOnInsert = true;

        final result = await repository.createCostItem(testItem);

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

    group('updateCostItem', () {
      void seedStoredItem() =>
          fakeSupabaseWrapper.addTableData(DatabaseConstants.costItemsTable, [
            CostItemTestDataMapFactory.createMaterialItemData(
              id: 'item-1',
              estimateId: 'estimate-1',
              itemName: 'Cement',
            ),
          ]);

      test(
        'returns Right with the entity as stored after the change',
        () async {
          seedStoredItem();

          final result = await repository.updateCostItem(
            testItem.copyWith(itemName: 'Cement mix'),
          );

          expect(result.getRightOrNull()?.itemName, 'Cement mix');
        },
      );

      test('keeps the changed name when the estimate is read again', () async {
        seedStoredItem();

        await repository.updateCostItem(
          testItem.copyWith(itemName: 'Cement mix'),
        );

        final items = await repository.getCostItemsForEstimate('estimate-1');
        expect(items.getRightOrNull()?.single.itemName, 'Cement mix');
      });

      test(
        'returns Left unexpectedError for an item that does not exist',
        () async {
          final result = await repository.updateCostItem(testItem);

          expect(
            result.getLeftOrNull(),
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.unexpectedError,
            ),
          );
        },
      );

      test('maps TimeoutException to timeoutError failure', () async {
        seedStoredItem();
        fakeSupabaseWrapper.shouldThrowOnUpdate = true;
        fakeSupabaseWrapper.updateExceptionType = SupabaseExceptionType.timeout;

        final result = await repository.updateCostItem(testItem);

        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.timeoutError,
          ),
        );
      });

      test('maps SocketException to connectionError failure', () async {
        seedStoredItem();
        fakeSupabaseWrapper.shouldThrowOnUpdate = true;
        fakeSupabaseWrapper.updateExceptionType = SupabaseExceptionType.socket;

        final result = await repository.updateCostItem(testItem);

        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.connectionError,
          ),
        );
      });
    });

    group('deleteCostItem', () {
      void seedStoredItem() =>
          fakeSupabaseWrapper.addTableData(DatabaseConstants.costItemsTable, [
            CostItemTestDataMapFactory.createMaterialItemData(
              id: 'item-1',
              estimateId: 'estimate-1',
            ),
          ]);

      test('returns Right and the estimate no longer holds the item', () async {
        seedStoredItem();

        final result = await repository.deleteCostItem('item-1');

        final items = await repository.getCostItemsForEstimate('estimate-1');
        expect(result.isRight(), true);
        expect(items.getRightOrNull(), isEmpty);
      });

      test('maps SocketException to connectionError failure', () async {
        seedStoredItem();
        fakeSupabaseWrapper.shouldThrowOnDelete = true;
        fakeSupabaseWrapper.deleteExceptionType = SupabaseExceptionType.socket;

        final result = await repository.deleteCostItem('item-1');

        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.connectionError,
          ),
        );
      });

      test('keeps the item when the delete fails', () async {
        seedStoredItem();
        fakeSupabaseWrapper.shouldThrowOnDelete = true;

        await repository.deleteCostItem('item-1');

        final items = await repository.getCostItemsForEstimate('estimate-1');
        expect(items.getRightOrNull(), hasLength(1));
      });
    });

    group('getEstimateItemsTotal', () {
      void seedTotals(List<num> totals) {
        fakeSupabaseWrapper.addTableData('cost_items', [
          for (final total in totals)
            {'estimate_id': 'estimate-1', 'item_total_cost': total},
        ]);
      }

      test('adds the item totals to the cent', () async {
        seedTotals([0.10, 0.20, 2993.62]);

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 2993.92);
      });

      test('keeps 0.10 + 0.20 at exactly 0.30', () async {
        seedTotals([0.10, 0.20]);

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 0.3);
      });

      test('keeps 1.15 at exactly 1.15', () async {
        seedTotals([1.15]);

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 1.15);
      });

      test('adds up 999 items, one fewer than the row limit', () async {
        seedTotals(List.filled(999, 1));

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 999);
      });

      test('fails when the items fill the 1000 row limit', () async {
        seedTotals(List.filled(1000, 1));

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.unexpectedDatabaseError,
          ),
        );
      });

      test('is zero for an estimate with no items', () async {
        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 0);
      });

      test('maps a connection failure to connectionError', () async {
        fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
        fakeSupabaseWrapper.selectMultipleExceptionType =
            SupabaseExceptionType.socket;

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.connectionError,
          ),
        );
      });

      test('maps a TypeError to parsingError', () async {
        fakeSupabaseWrapper.addTableData('cost_items', [
          {'estimate_id': 'estimate-1', 'item_total_cost': 'not a number'},
        ]);

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.parsingError,
          ),
        );
      });
    });

    group('getCostItemsForEstimate', () {
      void seedItems(List<Map<String, dynamic>> rows) {
        fakeSupabaseWrapper.addTableData('cost_items', rows);
      }

      List<Map<String, dynamic>> manyItems(int count) => [
        for (var i = 0; i < count; i++)
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-$i',
            estimateId: 'estimate-1',
          ),
      ];

      test('returns 999 items, one fewer than the row limit', () async {
        seedItems(manyItems(999));

        final result = await repository.getCostItemsForEstimate('estimate-1');

        expect(result.getRightOrNull(), hasLength(999));
      });

      test('fails when the items fill the 1000 row limit', () async {
        seedItems(manyItems(1000));

        final result = await repository.getCostItemsForEstimate('estimate-1');

        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.unexpectedDatabaseError,
          ),
        );
      });

      test('returns the items of the estimate, oldest first', () async {
        seedItems([
          CostItemTestDataMapFactory.createEquipmentItemData(
            id: 'newest',
            estimateId: 'estimate-1',
            createdAt: DateTime.utc(2024, 3).toIso8601String(),
          ),
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'oldest',
            estimateId: 'estimate-1',
            createdAt: DateTime.utc(2024, 1).toIso8601String(),
          ),
          CostItemTestDataMapFactory.createLaborItemData(
            id: 'middle',
            estimateId: 'estimate-1',
            createdAt: DateTime.utc(2024, 2).toIso8601String(),
          ),
        ]);

        final result = await repository.getCostItemsForEstimate('estimate-1');

        final items = result.getRightOrNull()!;
        expect(items.map((item) => item.id), ['oldest', 'middle', 'newest']);
        expect(items[0], isA<MaterialCostItem>());
        expect(items[1], isA<LaborCostItem>());
        expect(items[2], isA<EquipmentCostItem>());
      });

      test('leaves out the items of other estimates', () async {
        seedItems([
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'mine',
            estimateId: 'estimate-1',
          ),
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'theirs',
            estimateId: 'estimate-2',
          ),
        ]);

        final result = await repository.getCostItemsForEstimate('estimate-1');

        expect(result.getRightOrNull()!.map((item) => item.id), ['mine']);
      });

      test('returns an empty list for an estimate with no items', () async {
        final result = await repository.getCostItemsForEstimate('estimate-1');

        expect(result.getRightOrNull(), isEmpty);
      });

      test('maps a connection failure to connectionError', () async {
        fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        fakeSupabaseWrapper.selectMatchExceptionType =
            SupabaseExceptionType.socket;

        final result = await repository.getCostItemsForEstimate('estimate-1');

        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.connectionError,
          ),
        );
      });

      test('maps an unexpected error to unexpectedError', () async {
        fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        fakeSupabaseWrapper.selectMatchExceptionType =
            SupabaseExceptionType.unknown;

        final result = await repository.getCostItemsForEstimate('estimate-1');

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

    group('getEstimateNameKeepingEquipmentRate', () {
      void seedLine({String estimateName = 'Bedroom 2'}) {
        fakeSupabaseWrapper.addTableData('cost_items', [
          {
            ...CostItemTestDataMapFactory.createEquipmentItemData(
              itemName: 'Mini excavator',
              pricingMethod: 'job',
              jobAmount: 450.0,
            ),
            'cost_estimates': {
              'estimate_name': estimateName,
              'projects': {'owning_company_id': 'company-1'},
            },
          },
        ]);
      }

      test('returns the name of the estimate keeping the price', () async {
        seedLine();

        final result = await repository.getEstimateNameKeepingEquipmentRate(
          companyId: 'company-1',
          itemName: 'Mini excavator',
          pricingMethod: EquipmentPricingMethod.job,
          rateAmount: 450.0,
        );

        expect(result.getRightOrNull(), 'Bedroom 2');
      });

      test('returns Right with null when no line keeps the price', () async {
        seedLine();

        final result = await repository.getEstimateNameKeepingEquipmentRate(
          companyId: 'company-1',
          itemName: 'Mini excavator',
          pricingMethod: EquipmentPricingMethod.job,
          rateAmount: 400.0,
        );

        expect(result.isRight(), true);
        expect(result.getRightOrNull(), isNull);
      });

      test('maps a lost connection to a connection failure', () async {
        fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        fakeSupabaseWrapper.selectMatchExceptionType =
            SupabaseExceptionType.socket;

        final result = await repository.getEstimateNameKeepingEquipmentRate(
          companyId: 'company-1',
          itemName: 'Mini excavator',
          pricingMethod: EquipmentPricingMethod.job,
          rateAmount: 450.0,
        );

        expect(
          result.getLeftOrNull(),
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.connectionError,
          ),
        );
      });
    });
  });
}

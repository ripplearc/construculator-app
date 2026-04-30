import 'package:construculator/features/estimation/data/data_source/interfaces/cost_item_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../helpers/cost_item_test_data_map_factory.dart';

void main() {
  group('RemoteCostItemDataSource', () {
    late CostItemDataSource dataSource;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;

    const testEstimateId = 'estimate-123';

    setUpAll(() {
      fakeClock = FakeClockImpl();
      Modular.init(
        EstimationModule(
          FakeAppBootstrapFactory.create(
            supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
          ),
        ),
      );
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      dataSource = Modular.get<CostItemDataSource>();
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
    });

    void seedItemTable(List<Map<String, dynamic>> rows) {
      fakeSupabaseWrapper.addTableData(DatabaseConstants.costItemsTable, rows);
    }

    group('fetchCostItemsByEstimateId', () {
      test('successfully fetches all cost items without type filter', () async {
        final testItems = [
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-1',
            estimateId: testEstimateId,
            itemName: 'Concrete',
          ),
          CostItemTestDataMapFactory.createLaborItemData(
            id: 'item-2',
            estimateId: testEstimateId,
            itemName: 'Installation',
          ),
          CostItemTestDataMapFactory.createEquipmentItemData(
            id: 'item-3',
            estimateId: testEstimateId,
            itemName: 'Excavator',
          ),
        ];
        seedItemTable(testItems);

        final expectedDtos = testItems
            .map((data) => CostItemDto.fromJson(data))
            .toList();

        final result = await dataSource.fetchCostItemsByEstimateId(
          estimateId: testEstimateId,
        );

        expect(result.length, 3);
        expect(result, expectedDtos);
      });

      test('successfully fetches cost items filtered by type', () async {
        final testItems = [
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-1',
            estimateId: testEstimateId,
            itemName: 'Concrete',
          ),
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-2',
            estimateId: testEstimateId,
            itemName: 'Steel',
          ),
          CostItemTestDataMapFactory.createLaborItemData(
            id: 'item-3',
            estimateId: testEstimateId,
            itemName: 'Installation',
          ),
        ];
        seedItemTable(testItems);

        final result = await dataSource.fetchCostItemsByEstimateId(
          estimateId: testEstimateId,
          itemType: 'material',
        );

        expect(result.length, 2);
        expect(result.every((item) => item.itemType == 'material'), isTrue);
        expect(result[0].itemName, 'Concrete');
        expect(result[1].itemName, 'Steel');
      });

      test('uses correct table and filter parameters without itemType', () async {
        seedItemTable([
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-1',
            estimateId: testEstimateId,
          ),
        ]);

        await dataSource.fetchCostItemsByEstimateId(
          estimateId: testEstimateId,
        );

        final calls = fakeSupabaseWrapper.getMethodCallsFor('selectMatch');
        expect(calls.length, 1);
        final call = calls.first;
        expect(call, {
          'method': 'selectMatch',
          'table': DatabaseConstants.costItemsTable,
          'columns': '*',
          'filters': {
            DatabaseConstants.estimateIdColumn: testEstimateId,
          },
          'orderBy': DatabaseConstants.createdAtColumn,
          'ascending': true,
        });
      });

      test('uses correct table and filter parameters with itemType', () async {
        seedItemTable([
          CostItemTestDataMapFactory.createLaborItemData(
            id: 'item-1',
            estimateId: testEstimateId,
          ),
        ]);

        await dataSource.fetchCostItemsByEstimateId(
          estimateId: testEstimateId,
          itemType: 'labor',
        );

        final calls = fakeSupabaseWrapper.getMethodCallsFor('selectMatch');
        expect(calls.length, 1);
        final call = calls.first;
        expect(call, {
          'method': 'selectMatch',
          'table': DatabaseConstants.costItemsTable,
          'columns': '*',
          'filters': {
            DatabaseConstants.estimateIdColumn: testEstimateId,
            DatabaseConstants.itemTypeColumn: 'labor',
          },
          'orderBy': DatabaseConstants.createdAtColumn,
          'ascending': true,
        });
      });

      test('returns empty list when no items exist', () async {
        final result = await dataSource.fetchCostItemsByEstimateId(
          estimateId: testEstimateId,
        );

        expect(result, isEmpty);
      });

      test('returns empty list when no items match the type filter', () async {
        seedItemTable([
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-1',
            estimateId: testEstimateId,
          ),
        ]);

        final result = await dataSource.fetchCostItemsByEstimateId(
          estimateId: testEstimateId,
          itemType: 'equipment',
        );

        expect(result, isEmpty);
      });

      test('converts JSON to CostItemDto correctly', () async {
        final testItem = CostItemTestDataMapFactory.createMaterialItemData(
          id: 'item-1',
          estimateId: testEstimateId,
          itemName: 'Concrete Mix',
          unitPrice: 100.0,
          quantity: 50.0,
        );
        seedItemTable([testItem]);

        final expectedDto = CostItemDto.fromJson(testItem);

        final result = await dataSource.fetchCostItemsByEstimateId(
          estimateId: testEstimateId,
        );

        expect(result.length, 1);
        final dto = result.first;
        expect(dto, isA<CostItemDto>());
        expect(dto, expectedDto);
      });

      test('propagates exceptions from supabase wrapper', () async {
        fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        fakeSupabaseWrapper.selectMatchErrorMessage = 'Network error';

        await expectLater(
          dataSource.fetchCostItemsByEstimateId(
            estimateId: testEstimateId,
          ),
          throwsException,
        );
      });

      test('orders results by creation date ascending', () async {
        final testItems = [
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-2',
            estimateId: testEstimateId,
            itemName: 'Second',
          ),
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-1',
            estimateId: testEstimateId,
            itemName: 'First',
          ),
        ];
        seedItemTable(testItems);

        await dataSource.fetchCostItemsByEstimateId(
          estimateId: testEstimateId,
        );

        final calls = fakeSupabaseWrapper.getMethodCallsFor('selectMatch');
        expect(calls.first['orderBy'], DatabaseConstants.createdAtColumn);
        expect(calls.first['ascending'], isTrue);
      });

      test('fetches items for different estimate IDs correctly', () async {
        final testItems = [
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-1',
            estimateId: 'estimate-123',
            itemName: 'Concrete',
          ),
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-2',
            estimateId: 'estimate-456',
            itemName: 'Steel',
          ),
        ];
        seedItemTable(testItems);

        final result = await dataSource.fetchCostItemsByEstimateId(
          estimateId: 'estimate-123',
        );

        expect(result.length, 1);
        expect(result[0].estimateId, 'estimate-123');
        expect(result[0].itemName, 'Concrete');
      });
    });

    group('createCostItem', () {
      test('successfully creates a cost item', () async {
        final testItem = CostItemTestDataMapFactory.createMaterialItemData(
          id: '1',
          estimateId: testEstimateId,
          itemName: 'Steel Beams',
        );
        final itemDto = CostItemDto.fromJson(testItem);

        seedItemTable([testItem]);

        final result = await dataSource.createCostItem(itemDto);

        expect(result, isA<CostItemDto>());
        expect(result.id, '1');
        expect(result.itemName, 'Steel Beams');
      });

      test('uses correct table for insert', () async {
        final testItem = CostItemTestDataMapFactory.createLaborItemData(
          id: '1',
          estimateId: testEstimateId,
        );
        final itemDto = CostItemDto.fromJson(testItem);
        seedItemTable([testItem]);

        await dataSource.createCostItem(itemDto);

        final calls = fakeSupabaseWrapper.getMethodCallsFor('insert');
        expect(calls.length, 1);
        expect(calls.first['table'], DatabaseConstants.costItemsTable);
      });

      test('inserts correct data', () async {
        final testItem = CostItemTestDataMapFactory.createEquipmentItemData(
          id: 'item-1',
          estimateId: testEstimateId,
          itemName: 'Bulldozer',
          unitPrice: 500.0,
          quantity: 2.0,
        );
        final itemDto = CostItemDto.fromJson(testItem);
        seedItemTable([testItem]);

        await dataSource.createCostItem(itemDto);

        final calls = fakeSupabaseWrapper.getMethodCallsFor('insert');
        expect(calls.length, 1);
        expect(calls.first['data'], itemDto.toJson());
      });

      test('returns created cost item with correct data', () async {
        final testItem = CostItemTestDataMapFactory.createMaterialItemData(
          id: '1',
          estimateId: testEstimateId,
          itemName: 'Cement',
          unitPrice: 75.0,
          quantity: 100.0,
        );
        final itemDto = CostItemDto.fromJson(testItem);
        seedItemTable([testItem]);

        final result = await dataSource.createCostItem(itemDto);

        expect(result, isA<CostItemDto>());
        expect(result.itemName, 'Cement');
        expect(result.unitPrice, 75.0);
        expect(result.quantity, 100.0);
        expect(result.estimateId, testEstimateId);
      });

      test('propagates exceptions from supabase wrapper', () async {
        fakeSupabaseWrapper.shouldThrowOnInsert = true;
        fakeSupabaseWrapper.insertErrorMessage = 'Insert failed';

        final testItem = CostItemTestDataMapFactory.createMaterialItemData(
          id: 'item-1',
          estimateId: testEstimateId,
        );
        final itemDto = CostItemDto.fromJson(testItem);

        await expectLater(
          dataSource.createCostItem(itemDto),
          throwsException,
        );
      });
    });
  });
}

import 'package:construculator/features/estimation/data/data_source/interfaces/cost_item_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/remote_cost_item_data_source.dart';
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

    group('getCostItems', () {
      test('successfully fetches paginated cost items', () async {
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

        final result = await dataSource.getCostItems(
          estimateId: testEstimateId,
          offset: 0,
          limit: 10,
        );

        expect(result.length, 3);
        expect(result, expectedDtos);
      });

      test('uses correct table and filter parameters', () async {
        seedItemTable([
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-1',
            estimateId: testEstimateId,
          ),
        ]);

        await dataSource.getCostItems(
          estimateId: testEstimateId,
          offset: 0,
          limit: 10,
        );

        final calls = fakeSupabaseWrapper.getMethodCallsFor('selectPaginated');
        expect(calls.length, 1);
        final call = calls.first;
        expect(call, {
          'method': 'selectPaginated',
          'table': DatabaseConstants.costItemsTable,
          'columns': '*',
          'filterColumn': DatabaseConstants.estimateIdColumn,
          'filterValue': testEstimateId,
          'orderColumn': DatabaseConstants.createdAtColumn,
          'ascending': true,
          'rangeFrom': 0,
          'rangeTo': 9,
        });
      });

      test('returns empty list when no items exist', () async {
        final result = await dataSource.getCostItems(
          estimateId: testEstimateId,
          offset: 0,
          limit: 10,
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

        final result = await dataSource.getCostItems(
          estimateId: testEstimateId,
          offset: 0,
          limit: 10,
        );

        expect(result.length, 1);
        final dto = result.first;
        expect(dto, isA<CostItemDto>());
        expect(dto, expectedDto);
      });

      test('propagates exceptions from supabase wrapper', () async {
        fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
        fakeSupabaseWrapper.selectPaginatedErrorMessage = 'Network error';

        await expectLater(
          dataSource.getCostItems(
            estimateId: testEstimateId,
            offset: 0,
            limit: 10,
          ),
          throwsException,
        );
      });

      test('handles pagination with offset correctly', () async {
        seedItemTable(
          List.generate(
            20,
            (i) => CostItemTestDataMapFactory.createMaterialItemData(
              id: 'item-$i',
              estimateId: testEstimateId,
            ),
          ),
        );

        await dataSource.getCostItems(
          estimateId: testEstimateId,
          offset: 10,
          limit: 5,
        );

        final calls = fakeSupabaseWrapper.getMethodCallsFor('selectPaginated');
        expect(calls.length, 1);
        final call = calls.first;
        expect(call['rangeFrom'], 10);
        expect(call['rangeTo'], 14);
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
    });

    group('getCostItemsByType', () {
      test('successfully fetches items filtered by type', () async {
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

        final remoteDataSource = dataSource as RemoteCostItemDataSource;
        final result = await remoteDataSource.getCostItemsByType(
          estimateId: testEstimateId,
          itemType: 'material',
        );

        expect(result.length, 2);
        expect(result.every((item) => item.itemType == 'material'), isTrue);
        expect(result[0].itemName, 'Concrete');
        expect(result[1].itemName, 'Steel');
      });

      test('uses correct table and filter parameters', () async {
        seedItemTable([
          CostItemTestDataMapFactory.createLaborItemData(
            id: 'item-1',
            estimateId: testEstimateId,
          ),
        ]);

        final remoteDataSource = dataSource as RemoteCostItemDataSource;
        await remoteDataSource.getCostItemsByType(
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
            'item_type': 'labor',
          },
          'orderBy': DatabaseConstants.createdAtColumn,
          'ascending': true,
        });
      });

      test('returns empty list when no items match the type', () async {
        seedItemTable([
          CostItemTestDataMapFactory.createMaterialItemData(
            id: 'item-1',
            estimateId: testEstimateId,
          ),
        ]);

        final remoteDataSource = dataSource as RemoteCostItemDataSource;
        final result = await remoteDataSource.getCostItemsByType(
          estimateId: testEstimateId,
          itemType: 'equipment',
        );

        expect(result, isEmpty);
      });

      test('returns empty list when no items exist', () async {
        final remoteDataSource = dataSource as RemoteCostItemDataSource;
        final result = await remoteDataSource.getCostItemsByType(
          estimateId: testEstimateId,
          itemType: 'material',
        );

        expect(result, isEmpty);
      });

      test('converts JSON to CostItemDto correctly', () async {
        final testItem = CostItemTestDataMapFactory.createEquipmentItemData(
          id: 'item-1',
          estimateId: testEstimateId,
          itemName: 'Excavator',
        );
        seedItemTable([testItem]);

        final expectedDto = CostItemDto.fromJson(testItem);

        final remoteDataSource = dataSource as RemoteCostItemDataSource;
        final result = await remoteDataSource.getCostItemsByType(
          estimateId: testEstimateId,
          itemType: 'equipment',
        );

        expect(result.length, 1);
        final dto = result.first;
        expect(dto, isA<CostItemDto>());
        expect(dto, expectedDto);
      });

      test('propagates exceptions from supabase wrapper', () async {
        fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        fakeSupabaseWrapper.selectMatchErrorMessage = 'Network error';

        final remoteDataSource = dataSource as RemoteCostItemDataSource;
        await expectLater(
          remoteDataSource.getCostItemsByType(
            estimateId: testEstimateId,
            itemType: 'material',
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

        final remoteDataSource = dataSource as RemoteCostItemDataSource;
        await remoteDataSource.getCostItemsByType(
          estimateId: testEstimateId,
          itemType: 'material',
        );

        final calls = fakeSupabaseWrapper.getMethodCallsFor('selectMatch');
        expect(calls.first['orderBy'], DatabaseConstants.createdAtColumn);
        expect(calls.first['ascending'], isTrue);
      });
    });
  });
}

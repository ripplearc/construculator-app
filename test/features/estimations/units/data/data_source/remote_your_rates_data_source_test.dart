import 'package:construculator/features/estimation/data/data_source/interfaces/your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('RemoteYourRatesDataSource', () {
    late YourRatesDataSource dataSource;
    late FakeSupabaseWrapper fakeSupabaseWrapper;

    Map<String, dynamic> row({
      required String id,
      String companyId = 'company-1',
      String category = 'equipment',
      String itemName = 'Excavator',
      double rateAmount = 250.0,
      String rateCurrency = 'USD',
      String? unit = 'days',
      String? equipmentMethod = 'day',
      String? entryLabel,
      required String savedAt,
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
      dataSource = Modular.get<YourRatesDataSource>();
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

    group('fetchRates', () {
      test('returns every row when no category is given', () async {
        seed([
          row(id: 'r1', savedAt: '2026-01-01T00:00:00.000Z'),
          row(id: 'r2', category: 'material', savedAt: '2026-01-02T00:00:00.000Z'),
        ]);

        final result = await dataSource.fetchRates();

        expect(result.length, 2);
      });

      test('filters by category when given', () async {
        seed([
          row(id: 'r1', category: 'equipment', savedAt: '2026-01-01T00:00:00.000Z'),
          row(id: 'r2', category: 'material', savedAt: '2026-01-02T00:00:00.000Z'),
        ]);

        final result = await dataSource.fetchRates(category: 'equipment');

        expect(result.length, 1);
        expect(result.single.id, 'r1');
      });

      test('orders by saved_at descending', () async {
        seed([
          row(id: 'oldest', savedAt: '2026-01-01T00:00:00.000Z'),
          row(id: 'newest', savedAt: '2026-01-03T00:00:00.000Z'),
          row(id: 'middle', savedAt: '2026-01-02T00:00:00.000Z'),
        ]);

        final result = await dataSource.fetchRates();

        expect(
          result.map((dto) => dto.id).toList(),
          ['newest', 'middle', 'oldest'],
        );
      });

      test('uses correct table and filter parameters', () async {
        await dataSource.fetchRates(category: 'labor');

        final calls = fakeSupabaseWrapper.getMethodCallsFor('selectMatch');
        expect(calls.length, 1);
        expect(calls.first['table'], DatabaseConstants.yourRatesTable);
        expect(calls.first['filters'], {
          DatabaseConstants.categoryColumn: 'labor',
        });
        expect(calls.first['orderBy'], DatabaseConstants.savedAtColumn);
        expect(calls.first['ascending'], isFalse);
      });

      test('propagates exceptions from supabase wrapper', () async {
        fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;

        await expectLater(dataSource.fetchRates(), throwsException);
      });
    });

    group('fetchGrouping', () {
      test('returns only rows matching category and item name', () async {
        seed([
          row(id: 'r1', itemName: 'Excavator', savedAt: '2026-01-01T00:00:00.000Z'),
          row(id: 'r2', itemName: 'Bulldozer', savedAt: '2026-01-01T00:00:00.000Z'),
          row(
            id: 'r3',
            category: 'material',
            itemName: 'Excavator',
            savedAt: '2026-01-01T00:00:00.000Z',
          ),
        ]);

        final result = await dataSource.fetchGrouping(
          category: 'equipment',
          itemName: 'Excavator',
        );

        expect(result.map((dto) => dto.id).toList(), ['r1']);
      });

      test('uses correct table and filter parameters', () async {
        await dataSource.fetchGrouping(
          category: 'equipment',
          itemName: 'Excavator',
        );

        final calls = fakeSupabaseWrapper.getMethodCallsFor('selectMatch');
        expect(calls.length, 1);
        expect(calls.first['table'], DatabaseConstants.yourRatesTable);
        expect(calls.first['filters'], {
          DatabaseConstants.categoryColumn: 'equipment',
          DatabaseConstants.itemNameColumn: 'Excavator',
        });
      });
    });

    group('insertRate', () {
      test('inserts into the your_rates table and returns the created row', () async {
        final dto = YourRateEntryDto(
          id: '',
          companyId: 'company-1',
          category: 'equipment',
          itemName: 'Excavator',
          rateAmount: 250.0,
          rateCurrency: 'USD',
          savedAt: '2026-01-01T00:00:00.000Z',
        );

        final result = await dataSource.insertRate(dto);

        final calls = fakeSupabaseWrapper.getMethodCallsFor('insert');
        expect(calls.length, 1);
        expect(calls.first['table'], DatabaseConstants.yourRatesTable);
        expect(calls.first['data'], dto.toJson());
        expect(result.itemName, 'Excavator');
        expect(result.id, isNotEmpty);
      });

      test('propagates exceptions from supabase wrapper', () async {
        fakeSupabaseWrapper.shouldThrowOnInsert = true;

        await expectLater(
          dataSource.insertRate(
            const YourRateEntryDto(
              id: '',
              companyId: 'company-1',
              category: 'equipment',
              itemName: 'Excavator',
              rateAmount: 250.0,
              rateCurrency: 'USD',
              savedAt: '2026-01-01T00:00:00.000Z',
            ),
          ),
          throwsException,
        );
      });
    });

    group('updateRate', () {
      test('updates the row identified by id', () async {
        seed([row(id: 'r1', rateAmount: 250.0, savedAt: '2026-01-01T00:00:00.000Z')]);
        final dto = YourRateEntryDto(
          id: 'r1',
          companyId: 'company-1',
          category: 'equipment',
          itemName: 'Excavator',
          rateAmount: 300.0,
          rateCurrency: 'USD',
          savedAt: '2026-01-02T00:00:00.000Z',
        );

        final result = await dataSource.updateRate('r1', dto);

        final calls = fakeSupabaseWrapper.getMethodCallsFor('update');
        expect(calls.length, 1);
        expect(calls.first['table'], DatabaseConstants.yourRatesTable);
        expect(calls.first['filterColumn'], DatabaseConstants.idColumn);
        expect(calls.first['filterValue'], 'r1');
        expect(result.rateAmount, 300.0);
      });
    });
  });
}

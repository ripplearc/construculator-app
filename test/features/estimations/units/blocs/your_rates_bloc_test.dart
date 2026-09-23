import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('YourRatesBloc', () {
    late YourRatesBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;

    Map<String, dynamic> row({
      required String id,
      String category = 'equipment',
      String itemName = 'Excavator',
      String savedAt = '2026-01-01T00:00:00.000Z',
    }) {
      return {
        'id': id,
        'company_id': 'company-1',
        'category': category,
        'item_name': itemName,
        'rate_amount': 250.0,
        'rate_currency': 'USD',
        'unit': 'days',
        'equipment_method': 'day',
        'entry_label': null,
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
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
      bloc = Modular.get<YourRatesBloc>();
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is YourRatesLoading', () {
      expect(bloc.state, isA<YourRatesLoading>());
    });

    group('YourRatesRefreshRecents', () {
      blocTest<YourRatesBloc, YourRatesState>(
        'emits Loading then Loaded with at most 4 recents, most recent first',
        setUp: () {
          fakeSupabaseWrapper.addTableData(DatabaseConstants.yourRatesTable, [
            row(id: 'r1', savedAt: '2026-01-01T00:00:00.000Z'),
            row(id: 'r2', savedAt: '2026-01-05T00:00:00.000Z'),
            row(id: 'r3', savedAt: '2026-01-03T00:00:00.000Z'),
            row(id: 'r4', savedAt: '2026-01-02T00:00:00.000Z'),
            row(id: 'r5', savedAt: '2026-01-04T00:00:00.000Z'),
          ]);
        },
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const YourRatesRefreshRecents(CostItemType.equipment)),
        expect: () => [
          isA<YourRatesLoading>(),
          isA<YourRatesLoaded>().having(
            (s) => s.recents.map((e) => e.id).toList(),
            'recents',
            ['r2', 'r5', 'r3', 'r4'],
          ),
        ],
      );

      blocTest<YourRatesBloc, YourRatesState>(
        'emits Loading then Error on failure',
        setUp: () {
          fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        },
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const YourRatesRefreshRecents(CostItemType.equipment)),
        expect: () => [
          isA<YourRatesLoading>(),
          isA<YourRatesError>().having(
            (s) => (s.failure as EstimationFailure).errorType,
            'errorType',
            EstimationErrorType.unexpectedError,
          ),
        ],
      );
    });

    group('YourRatesSearched', () {
      blocTest<YourRatesBloc, YourRatesState>(
        'emits Loading then SearchResults matching the query',
        setUp: () {
          fakeSupabaseWrapper.addTableData(DatabaseConstants.yourRatesTable, [
            row(id: 'r1', itemName: 'Excavator'),
            row(id: 'r2', itemName: 'Bulldozer'),
          ]);
        },
        build: () => bloc,
        act: (bloc) => bloc.add(
          const YourRatesSearched('exc', category: CostItemType.equipment),
        ),
        wait: const Duration(milliseconds: 310),
        expect: () => [
          isA<YourRatesLoading>(),
          isA<YourRatesSearchResults>().having(
            (s) => s.results.map((e) => e.itemName).toList(),
            'results',
            ['Excavator'],
          ),
        ],
      );

      blocTest<YourRatesBloc, YourRatesState>(
        'emits Loading then Error on failure',
        setUp: () {
          fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const YourRatesSearched('exc')),
        wait: const Duration(milliseconds: 310),
        expect: () => [isA<YourRatesLoading>(), isA<YourRatesError>()],
      );

      blocTest<YourRatesBloc, YourRatesState>(
        'debounces rapid successive searches into a single result for the '
        'latest query',
        setUp: () {
          fakeSupabaseWrapper.addTableData(DatabaseConstants.yourRatesTable, [
            row(id: 'r1', itemName: 'Excavator'),
            row(id: 'r2', itemName: 'Bulldozer'),
          ]);
        },
        build: () => bloc,
        act: (bloc) {
          bloc
            ..add(const YourRatesSearched('exc'))
            ..add(const YourRatesSearched('bull'));
        },
        wait: const Duration(milliseconds: 310),
        expect: () => [
          isA<YourRatesLoading>(),
          isA<YourRatesSearchResults>().having(
            (s) => s.results.map((e) => e.itemName).toList(),
            'results',
            ['Bulldozer'],
          ),
        ],
      );
    });
  });
}

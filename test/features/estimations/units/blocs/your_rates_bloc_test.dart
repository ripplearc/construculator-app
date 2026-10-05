import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
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
      // These tests build their own bloc (bypassing the shared Modular
      // instance from setUp) with queryDebounce: Duration.zero, so they don't
      // need to wait out the real 300ms debounce — a real-time wait is
      // flaky under CI load and this codebase's convention forbids it. Each
      // act() then awaits bloc.stream.firstWhere(...) for the terminal
      // state, the same pattern ProjectSearchBloc's tests use to gate on a
      // handler's completion instead of a wall-clock wait; this is a second,
      // independent stream subscription, so it doesn't affect the list of
      // states blocTest's own `expect` collects.
      // The Modular-registered YourRatesBloc always uses the production
      // debounce; these tests need the zero-debounce constructor parameter,
      // which DI can't override per-test.
      // ignore: no_direct_instantiation, reason: needs queryDebounce: Duration.zero, which Modular's registration can't supply per-test
      YourRatesBloc zeroDebounceBloc() => YourRatesBloc(
        repository: Modular.get<YourRatesRepository>(),
        queryDebounce: Duration.zero,
      );

      blocTest<YourRatesBloc, YourRatesState>(
        'emits Loading then SearchResults matching the query',
        setUp: () {
          fakeSupabaseWrapper.addTableData(DatabaseConstants.yourRatesTable, [
            row(id: 'r1', itemName: 'Excavator'),
            row(id: 'r2', itemName: 'Bulldozer'),
          ]);
        },
        build: zeroDebounceBloc,
        act: (bloc) async {
          bloc.add(
            const YourRatesSearched('exc', category: CostItemType.equipment),
          );
          await bloc.stream.firstWhere((s) => s is YourRatesSearchResults);
        },
        expect: () => [
          isA<YourRatesLoading>(),
          isA<YourRatesSearchResults>().having(
            (s) => s.results.map((e) => e.itemName).toList(),
            'results',
            ['Excavator'],
          ),
        ],
      );

      // ignore: no_direct_instantiation, reason: needs a debounce far longer than the test, which Modular's registration can't supply per-test
      YourRatesBloc longDebounceBloc() => YourRatesBloc(
        repository: Modular.get<YourRatesRepository>(),
        queryDebounce: const Duration(days: 1),
      );

      blocTest<YourRatesBloc, YourRatesState>(
        'an empty query lists every saved rate at once, without the debounce',
        setUp: () {
          fakeSupabaseWrapper.addTableData(DatabaseConstants.yourRatesTable, [
            for (var i = 0; i < 6; i++)
              row(id: 'r$i', savedAt: '2026-01-0${i + 1}T00:00:00.000Z'),
          ]);
        },
        build: longDebounceBloc,
        act: (bloc) async {
          bloc.add(
            const YourRatesSearched('', category: CostItemType.equipment),
          );
          await bloc.stream.firstWhere((s) => s is YourRatesSearchResults);
        },
        expect: () => [
          isA<YourRatesLoading>(),
          isA<YourRatesSearchResults>().having(
            (s) => s.results.length,
            'results',
            6,
          ),
        ],
      );

      blocTest<YourRatesBloc, YourRatesState>(
        'emits Loading then Error on failure',
        setUp: () {
          fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        },
        build: zeroDebounceBloc,
        act: (bloc) async {
          bloc.add(const YourRatesSearched('exc'));
          await bloc.stream.firstWhere((s) => s is YourRatesError);
        },
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
        build: zeroDebounceBloc,
        act: (bloc) async {
          bloc
            ..add(const YourRatesSearched('exc'))
            ..add(const YourRatesSearched('bull'));
          await bloc.stream.firstWhere((s) => s is YourRatesSearchResults);
        },
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

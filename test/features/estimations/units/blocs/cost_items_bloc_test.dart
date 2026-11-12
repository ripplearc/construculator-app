import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_items_bloc/cost_items_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../helpers/cost_item_test_data_map_factory.dart';
import '../../helpers/cost_line_test_items.dart';

void main() {
  group('CostItemsBloc', () {
    late FakeSupabaseWrapper fakeSupabaseWrapper;

    const estimateId = 'estimate-1';

    setUpAll(() {
      final bootstrap = FakeAppBootstrapFactory.create(
        supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
      );
      Modular.init(EstimationModule(bootstrap));
      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
    });

    void seedItems(List<Map<String, dynamic>> rows) {
      fakeSupabaseWrapper.addTableData(DatabaseConstants.costItemsTable, rows);
    }

    Map<String, dynamic> material(String id, double total) =>
        CostItemTestDataMapFactory.createMaterialItemData(
          id: id,
          estimateId: estimateId,
          itemTotalCost: total,
        );

    Map<String, dynamic> labor(String id, double total) =>
        CostItemTestDataMapFactory.createLaborItemData(
          id: id,
          estimateId: estimateId,
          itemTotalCost: total,
        );

    Map<String, dynamic> equipment(String id, double total) =>
        CostItemTestDataMapFactory.createEquipmentItemData(
          id: id,
          estimateId: estimateId,
          itemTotalCost: total,
        );

    blocTest<CostItemsBloc, CostItemsState>(
      'emits loading then loaded with a subtotal for each type',
      setUp: () => seedItems([
        material('m1', 100),
        labor('l1', 40.5),
        equipment('e1', 600),
        material('m2', 25.25),
        equipment('e2', 10),
        {...material('other', 999), 'estimate_id': 'other-estimate'},
      ]),
      build: () => Modular.get<CostItemsBloc>(),
      act: (bloc) => bloc.add(const CostItemsRequested(estimateId)),
      expect: () => [
        isA<CostItemsLoading>(),
        isA<CostItemsLoaded>()
            .having((s) => s.items.map((item) => item.id), 'ids', [
              'm1',
              'l1',
              'e1',
              'm2',
              'e2',
            ])
            .having((s) => s.materialsSubtotal, 'materials', 125.25)
            .having((s) => s.laborSubtotal, 'labor', 40.5)
            .having((s) => s.equipmentSubtotal, 'equipment', 610),
      ],
    );

    blocTest<CostItemsBloc, CostItemsState>(
      'adds up subtotals in whole cents',
      setUp: () => seedItems([material('m1', 0.10), material('m2', 0.20)]),
      build: () => Modular.get<CostItemsBloc>(),
      act: (bloc) => bloc.add(const CostItemsRequested(estimateId)),
      verify: (bloc) {
        final state = bloc.state as CostItemsLoaded;
        expect(state.materialsSubtotal, 0.3);
      },
    );

    blocTest<CostItemsBloc, CostItemsState>(
      'keeps a 1.15 line at exactly 1.15',
      setUp: () => seedItems([material('m1', 1.15)]),
      build: () => Modular.get<CostItemsBloc>(),
      act: (bloc) => bloc.add(const CostItemsRequested(estimateId)),
      verify: (bloc) {
        final state = bloc.state as CostItemsLoaded;
        expect(state.materialsSubtotal, 1.15);
      },
    );

    blocTest<CostItemsBloc, CostItemsState>(
      'has a zero subtotal for a type with no lines',
      setUp: () => seedItems([labor('l1', 40)]),
      build: () => Modular.get<CostItemsBloc>(),
      act: (bloc) => bloc.add(const CostItemsRequested(estimateId)),
      verify: (bloc) {
        final state = bloc.state as CostItemsLoaded;
        expect(state.materialsSubtotal, 0);
        expect(state.equipmentSubtotal, 0);
      },
    );

    blocTest<CostItemsBloc, CostItemsState>(
      'loads an estimate with no lines as empty with zero subtotals',
      build: () => Modular.get<CostItemsBloc>(),
      act: (bloc) => bloc.add(const CostItemsRequested(estimateId)),
      expect: () => [
        isA<CostItemsLoading>(),
        isA<CostItemsLoaded>()
            .having((s) => s.items, 'items', isEmpty)
            .having((s) => s.materialsSubtotal, 'materials', 0)
            .having((s) => s.laborSubtotal, 'labor', 0)
            .having((s) => s.equipmentSubtotal, 'equipment', 0),
      ],
    );

    blocTest<CostItemsBloc, CostItemsState>(
      'a refresh after a new line loads it without showing loading again',
      setUp: () => seedItems([material('m1', 100)]),
      build: () => Modular.get<CostItemsBloc>(),
      act: (bloc) async {
        bloc.add(const CostItemsRequested(estimateId));
        await bloc.stream.firstWhere((s) => s is CostItemsLoaded);
        seedItems([material('m1', 100), equipment('e1', 600)]);
        bloc.add(const CostItemsRefreshed());
      },
      expect: () => [
        isA<CostItemsLoading>(),
        isA<CostItemsLoaded>()
            .having((s) => s.items.length, 'items', 1)
            .having((s) => s.equipmentSubtotal, 'equipment', 0),
        isA<CostItemsLoaded>()
            .having((s) => s.items.length, 'items', 2)
            .having((s) => s.equipmentSubtotal, 'equipment', 600),
      ],
    );

    final heldRead = Completer<void>();

    blocTest<CostItemsBloc, CostItemsState>(
      'a newer request replaces one that is still loading',
      setUp: () {
        seedItems([
          material('m1', 100),
          {...material('m2', 7), 'estimate_id': 'estimate-2'},
        ]);
        fakeSupabaseWrapper.shouldDelayOperations = true;
        fakeSupabaseWrapper.completer = heldRead;
      },
      build: () => Modular.get<CostItemsBloc>(),
      act: (bloc) async {
        bloc.add(const CostItemsRequested(estimateId));
        bloc.add(const CostItemsRequested('estimate-2'));
        await bloc.stream.firstWhere((s) => s is CostItemsLoading);
        heldRead.complete();
        await bloc.stream.firstWhere((s) => s is CostItemsLoaded);
      },
      expect: () => [
        isA<CostItemsLoading>(),
        isA<CostItemsLoaded>().having(
          (s) => s.items.map((item) => item.id),
          'ids',
          ['m2'],
        ),
      ],
    );

    blocTest<CostItemsBloc, CostItemsState>(
      'ignores a refresh before any estimate was requested',
      build: () => Modular.get<CostItemsBloc>(),
      act: (bloc) => bloc.add(const CostItemsRefreshed()),
      expect: () => <CostItemsState>[],
    );

    blocTest<CostItemsBloc, CostItemsState>(
      'emits failure when the lines cannot be read',
      setUp: () {
        fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        fakeSupabaseWrapper.selectMatchExceptionType =
            SupabaseExceptionType.socket;
      },
      build: () => Modular.get<CostItemsBloc>(),
      act: (bloc) => bloc.add(const CostItemsRequested(estimateId)),
      expect: () => [
        isA<CostItemsLoading>(),
        isA<CostItemsFailure>().having(
          (s) => s.failure,
          'failure',
          isA<EstimationFailure>().having(
            (f) => f.errorType,
            'errorType',
            EstimationErrorType.connectionError,
          ),
        ),
      ],
    );

    blocTest<CostItemsBloc, CostItemsState>(
      'a refresh that fails emits failure',
      setUp: () => seedItems([material('m1', 100)]),
      build: () => Modular.get<CostItemsBloc>(),
      act: (bloc) async {
        bloc.add(const CostItemsRequested(estimateId));
        await bloc.stream.firstWhere((s) => s is CostItemsLoaded);
        fakeSupabaseWrapper.shouldThrowOnSelectMatch = true;
        fakeSupabaseWrapper.selectMatchExceptionType =
            SupabaseExceptionType.socket;
        bloc.add(const CostItemsRefreshed());
      },
      expect: () => [
        isA<CostItemsLoading>(),
        isA<CostItemsLoaded>(),
        isA<CostItemsFailure>(),
      ],
    );
  });

  group('CostItems events and states', () {
    test('loaded state splits its lines by section, oldest first', () {
      final state = CostItemsLoaded(
        items: [
          equipmentLine(id: 'q1'),
          materialLine(id: 'm1'),
          materialLine(id: 'm2'),
        ],
        materialsSubtotal: 0,
        laborSubtotal: 0,
        equipmentSubtotal: 0,
      );

      expect(state.materialLines.map((line) => line.id), ['m1', 'm2']);
      expect(state.laborLines, isEmpty);
      expect(state.equipmentLines.map((line) => line.id), ['q1']);
    });

    test('requests for the same estimate are equal', () {
      expect(
        const CostItemsRequested('estimate-1'),
        const CostItemsRequested('estimate-1'),
      );
    });

    test('requests for different estimates are not equal', () {
      expect(
        const CostItemsRequested('estimate-1'),
        isNot(const CostItemsRequested('estimate-2')),
      );
    });

    test('refreshes are equal', () {
      final first = CostItemsRefreshed();
      final second = CostItemsRefreshed();

      expect(first, second);
    });

    test('initial and loading states are each equal to themselves', () {
      final initial = CostItemsInitial();
      final loading = CostItemsLoading();

      expect(initial, CostItemsInitial());
      expect(loading, CostItemsLoading());
      expect(initial, isNot(loading));
    });

    test('loaded states with the same subtotals are equal', () {
      const loaded = CostItemsLoaded(
        items: [],
        materialsSubtotal: 1,
        laborSubtotal: 2,
        equipmentSubtotal: 3,
      );

      expect(
        loaded,
        const CostItemsLoaded(
          items: [],
          materialsSubtotal: 1,
          laborSubtotal: 2,
          equipmentSubtotal: 3,
        ),
      );
      expect(
        loaded,
        isNot(
          const CostItemsLoaded(
            items: [],
            materialsSubtotal: 1,
            laborSubtotal: 2,
            equipmentSubtotal: 4,
          ),
        ),
      );
    });

    test('failure states are equal when they hold the same failure', () {
      const failure = EstimationFailure(
        errorType: EstimationErrorType.timeoutError,
      );

      expect(const CostItemsFailure(failure), const CostItemsFailure(failure));
      expect(
        const CostItemsFailure(failure),
        isNot(
          const CostItemsFailure(
            EstimationFailure(errorType: EstimationErrorType.connectionError),
          ),
        ),
      );
    });
  });
}

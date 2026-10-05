import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/estimate_summary_bloc/estimate_summary_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('EstimateSummaryBloc', () {
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

    void seedEstimate() {
      fakeSupabaseWrapper.addTableData(DatabaseConstants.costEstimatesTable, [
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: estimateId,
          estimateName: 'Bedroom 2',
          totalCost: 1,
        ),
      ]);
      fakeSupabaseWrapper.addTableData(DatabaseConstants.costItemsTable, [
        {'estimate_id': estimateId, 'item_total_cost': 2000},
        {'estimate_id': estimateId, 'item_total_cost': 993.62},
        {'estimate_id': 'other-estimate', 'item_total_cost': 500},
      ]);
    }

    blocTest<EstimateSummaryBloc, EstimateSummaryState>(
      'emits loading then loaded with the estimate name and total',
      setUp: seedEstimate,
      build: () => Modular.get<EstimateSummaryBloc>(),
      act: (bloc) => bloc.add(const EstimateSummaryRequested(estimateId)),
      expect: () => [
        isA<EstimateSummaryLoading>(),
        isA<EstimateSummaryLoaded>()
            .having((s) => s.estimate.id, 'id', estimateId)
            .having((s) => s.estimate.estimateName, 'name', 'Bedroom 2')
            .having((s) => s.estimate.totalCost, 'total', 2993.62),
      ],
    );

    blocTest<EstimateSummaryBloc, EstimateSummaryState>(
      'sums the items of the estimate instead of the estimate\'s stored total',
      setUp: seedEstimate,
      build: () => Modular.get<EstimateSummaryBloc>(),
      act: (bloc) => bloc.add(const EstimateSummaryRequested(estimateId)),
      verify: (bloc) {
        final state = bloc.state as EstimateSummaryLoaded;
        expect(state.estimate.totalCost, 2993.62);
      },
    );

    blocTest<EstimateSummaryBloc, EstimateSummaryState>(
      'is zero for an estimate with no items',
      setUp: () {
        fakeSupabaseWrapper.addTableData(DatabaseConstants.costEstimatesTable, [
          EstimationTestDataMapFactory.createFakeEstimationData(
            id: estimateId,
            estimateName: 'Bedroom 2',
            totalCost: 1,
          ),
        ]);
      },
      build: () => Modular.get<EstimateSummaryBloc>(),
      act: (bloc) => bloc.add(const EstimateSummaryRequested(estimateId)),
      verify: (bloc) {
        expect((bloc.state as EstimateSummaryLoaded).estimate.totalCost, 0);
      },
    );

    blocTest<EstimateSummaryBloc, EstimateSummaryState>(
      'emits a failure when the items cannot be summed',
      setUp: () {
        seedEstimate();
        fakeSupabaseWrapper.shouldThrowOnSelectMultiple = true;
        fakeSupabaseWrapper.selectMultipleExceptionType =
            SupabaseExceptionType.socket;
      },
      build: () => Modular.get<EstimateSummaryBloc>(),
      act: (bloc) => bloc.add(const EstimateSummaryRequested(estimateId)),
      expect: () => [
        isA<EstimateSummaryLoading>(),
        isA<EstimateSummaryFailure>().having(
          (s) => s.failure,
          'failure',
          EstimationFailure(errorType: EstimationErrorType.connectionError),
        ),
      ],
    );

    blocTest<EstimateSummaryBloc, EstimateSummaryState>(
      'emits a not-found failure when the estimate does not exist',
      build: () => Modular.get<EstimateSummaryBloc>(),
      act: (bloc) => bloc.add(const EstimateSummaryRequested(estimateId)),
      expect: () => [
        isA<EstimateSummaryLoading>(),
        isA<EstimateSummaryFailure>().having(
          (s) => s.failure,
          'failure',
          EstimationFailure(errorType: EstimationErrorType.notFoundError),
        ),
      ],
    );

    blocTest<EstimateSummaryBloc, EstimateSummaryState>(
      'emits a connection failure when the lookup cannot reach the server',
      setUp: () {
        fakeSupabaseWrapper.shouldThrowOnSelect = true;
        fakeSupabaseWrapper.selectExceptionType = SupabaseExceptionType.socket;
        fakeSupabaseWrapper.selectErrorMessage = 'Connection failed';
      },
      build: () => Modular.get<EstimateSummaryBloc>(),
      act: (bloc) => bloc.add(const EstimateSummaryRequested(estimateId)),
      expect: () => [
        isA<EstimateSummaryLoading>(),
        isA<EstimateSummaryFailure>().having(
          (s) => s.failure,
          'failure',
          EstimationFailure(errorType: EstimationErrorType.connectionError),
        ),
      ],
    );

    blocTest<EstimateSummaryBloc, EstimateSummaryState>(
      'loads again after a failure',
      setUp: seedEstimate,
      build: () => Modular.get<EstimateSummaryBloc>(),
      seed: () => EstimateSummaryFailure(UnexpectedFailure()),
      act: (bloc) => bloc.add(const EstimateSummaryRequested(estimateId)),
      expect: () => [
        isA<EstimateSummaryLoading>(),
        isA<EstimateSummaryLoaded>(),
      ],
    );

    blocTest<EstimateSummaryBloc, EstimateSummaryState>(
      'emits only the newest request when a second one starts while loading',
      setUp: seedEstimate,
      build: () {
        fakeSupabaseWrapper.shouldDelayOperations = true;
        fakeSupabaseWrapper.completer = Completer();
        return Modular.get<EstimateSummaryBloc>();
      },
      act: (bloc) async {
        bloc.add(const EstimateSummaryRequested(estimateId));
        bloc.add(const EstimateSummaryRequested(estimateId));
        await bloc.stream.firstWhere((s) => s is EstimateSummaryLoading);
        fakeSupabaseWrapper.completer!.complete();
      },
      wait: Duration.zero,
      expect: () => [
        isA<EstimateSummaryLoading>(),
        isA<EstimateSummaryLoaded>(),
      ],
      verify: (_) {
        expect(
          fakeSupabaseWrapper.getMethodCallsFor('selectSingle'),
          hasLength(2),
        );
      },
    );
  });
}

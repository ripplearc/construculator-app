import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/delete_cost_estimation_bloc/delete_cost_estimation_bloc.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/estimation_test_data_map_factory.dart';

void main() {
  group('DeleteCostEstimationBloc', () {
    late DeleteCostEstimationBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;

    const testProjectId = 'test-project-123';
    const testEstimationId = 'test-estimation-123';
    const testEstimationName = 'Test Estimation';

    setUpAll(() {
      fakeClock = FakeClockImpl();
      final bootstrap = AppBootstrap(
        supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
        config: FakeAppConfig(),
        envLoader: FakeEnvLoader(),
      );
      Modular.init(EstimationModule(bootstrap));

      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
      bloc = Modular.get<DeleteCostEstimationBloc>();
    });

    tearDown(() {
      bloc.close();
    });

    Map<String, dynamic> buildEstimationMap({
      String? id,
      String? projectId,
      String? estimateName,
      String? createdAt,
      String? updatedAt,
    }) {
      return EstimationTestDataMapFactory.createFakeEstimationData(
        id: id,
        projectId: projectId,
        estimateName: estimateName,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    void seedEstimationTable(List<Map<String, dynamic>> rows) {
      fakeSupabaseWrapper.addTableData(
        DatabaseConstants.costEstimatesTable,
        rows,
      );
    }

    group('Initialization', () {
      test('should start in initial state', () {
        expect(bloc.state, isA<DeleteCostEstimationInitial>());
      });
    });

    group('DeleteCostEstimationRequested', () {
      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit in progress then success when estimation is deleted successfully',
        build: () {
          final estimationMap = buildEstimationMap(
            id: testEstimationId,
            projectId: testProjectId,
            estimateName: testEstimationName,
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(
            estimationId: testEstimationId,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>().having(
            (s) => s.estimationId,
            'estimationId',
            testEstimationId,
          ),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit in progress then failure when repository returns failure',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType =
              SupabaseExceptionType.socket;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(
            estimationId: testEstimationId,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>().having(
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

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit failure with timeout error when repository returns timeout error',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType =
              SupabaseExceptionType.timeout;
          return bloc;
        },
        act: (bloc) => bloc.add(
          DeleteCostEstimationRequested(
            estimationId: testEstimationId,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>().having(
            (s) => s.failure,
            'failure',
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.timeoutError,
            ),
          ),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit failure with parsing error when repository returns parsing error',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnDelete = true;
          fakeSupabaseWrapper.deleteExceptionType = SupabaseExceptionType.type;
          return bloc;
        },
        act: (bloc) => bloc.add(
          DeleteCostEstimationRequested(
            estimationId: testEstimationId,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>().having(
            (s) => s.failure,
            'failure',
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.parsingError,
            ),
          ),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should successfully delete even if estimation does not exist',
        build: () => bloc,
        act: (bloc) => bloc.add(
          DeleteCostEstimationRequested(
            estimationId: 'non-existent-id',
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>().having(
            (s) => s.failure,
            'failure',
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.notFoundError,
            ),
          ),
        ],
      );
    });

    group('Multiple events handling', () {
      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should handle multiple deletion events correctly',
        build: () {
          final estimationMap1 = buildEstimationMap(
            id: 'estimation-1',
            projectId: testProjectId,
            estimateName: 'Estimation 1',
          );
          final estimationMap2 = buildEstimationMap(
            id: 'estimation-2',
            projectId: testProjectId,
            estimateName: 'Estimation 2',
          );
          seedEstimationTable([estimationMap1, estimationMap2]);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(
            DeleteCostEstimationRequested(
              estimationId: 'estimation-1',
              projectId: testProjectId,
            ),
          );
          bloc.add(
            DeleteCostEstimationRequested(
              estimationId: 'estimation-2',
              projectId: testProjectId,
            ),
          );
        },
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>().having(
            (s) => s.estimationId,
            'estimationId',
            'estimation-1',
          ),
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>().having(
            (s) => s.estimationId,
            'estimationId',
            'estimation-2',
          ),
        ],
      );
    });

    group('Repository integration', () {
      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should call deleteEstimation with correct ids and succeed',
        build: () {
          final estimationMap = buildEstimationMap(
            id: testEstimationId,
            projectId: testProjectId,
            estimateName: testEstimationName,
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) => bloc.add(
          DeleteCostEstimationRequested(
            estimationId: testEstimationId,
            projectId: testProjectId,
          ),
        ),
        verify: (bloc) {
          final calls = fakeSupabaseWrapper.getMethodCallsFor('delete');
          expect(calls, hasLength(1));
          expect(
            calls.first['table'],
            equals(DatabaseConstants.costEstimatesTable),
          );
          expect(calls.first['filterColumn'], equals('id'));
          expect(calls.first['filterValue'], testEstimationId);
        },
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>(),
        ],
      );
    });
  });
}

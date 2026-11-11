import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/delete_cost_estimation_bloc/delete_cost_estimation_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimates_database.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('DeleteCostEstimationBloc', () {
    late DeleteCostEstimationBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    final fakePhoneDatabase = FakeCostEstimatesDatabase();
    late FakeClockImpl fakeClock;
    late FakeCurrentProjectNotifier fakeCurrentProjectNotifier;

    const testProjectId = 'test-project-123';
    const testEstimationId = 'test-estimation-123';
    const testEstimationName = 'Test Estimation';

    setUpAll(() {
      fakeClock = FakeClockImpl();
      final bootstrap = FakeAppBootstrapFactory.create(
        supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
      );
      Modular.init(EstimationModule(bootstrap));
      Modular.replaceInstance<PowerSyncDatabaseWrapper>(fakePhoneDatabase);

      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;

      fakeCurrentProjectNotifier = FakeCurrentProjectNotifier(
        initialProjectId: testProjectId,
      );
      Modular.replaceInstance<CurrentProjectNotifier>(
        fakeCurrentProjectNotifier,
      );
    });

    tearDownAll(() {
      Modular.dispose();
      fakePhoneDatabase.dispose();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
      fakePhoneDatabase.reset();
      fakeCurrentProjectNotifier.reset(projectId: testProjectId);
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
      fakePhoneDatabase.seedRows(rows);
    }

    group('Initialization', () {
      test('should start in initial state', () {
        expect(bloc.state, isA<DeleteCostEstimationInitial>());
      });
    });

    group('DeleteCostEstimationRequested', () {
      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should emit failure when current project is unavailable',
        build: () {
          fakeCurrentProjectNotifier.reset(projectId: null);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(estimationId: testEstimationId),
        ),
        expect: () => [
          isA<DeleteCostEstimationFailure>().having(
            (s) => s.failure,
            'failure',
            isA<EstimationFailure>().having(
              (f) => f.errorType,
              'errorType',
              EstimationErrorType.unexpectedError,
            ),
          ),
        ],
      );

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
          const DeleteCostEstimationRequested(estimationId: testEstimationId),
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
        'should emit in progress then failure when the phone cannot save the delete',
        build: () {
          seedEstimationTable([
            buildEstimationMap(
              id: testEstimationId,
              projectId: testProjectId,
              estimateName: testEstimationName,
            ),
          ]);
          fakePhoneDatabase.executeError = Exception('disk full');
          return bloc;
        },
        act: (bloc) => bloc.add(
          const DeleteCostEstimationRequested(estimationId: testEstimationId),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationFailure>().having(
            (s) => s.failure,
            'failure',
            isA<UnexpectedFailure>(),
          ),
        ],
      );

      blocTest<DeleteCostEstimationBloc, DeleteCostEstimationState>(
        'should successfully delete even if estimation does not exist',
        build: () => bloc,
        act: (bloc) => bloc.add(
          DeleteCostEstimationRequested(estimationId: 'non-existent-id'),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>(),
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
          bloc.add(DeleteCostEstimationRequested(estimationId: 'estimation-1'));
          bloc.add(DeleteCostEstimationRequested(estimationId: 'estimation-2'));
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
          DeleteCostEstimationRequested(estimationId: testEstimationId),
        ),
        expect: () => [
          isA<DeleteCostEstimationInProgress>(),
          isA<DeleteCostEstimationSuccess>(),
        ],
      );
    });
  });
}

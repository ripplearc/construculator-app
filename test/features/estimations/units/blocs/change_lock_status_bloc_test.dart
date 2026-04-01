import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/change_lock_status_bloc/change_lock_status_bloc.dart';
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

import '../../helpers/estimation_test_data_map_factory.dart';

void main() {
  group('ChangeLockStatusBloc', () {
    late ChangeLockStatusBloc bloc;
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
      bloc = Modular.get<ChangeLockStatusBloc>();
    });

    tearDown(() {
      bloc.close();
    });

    Map<String, dynamic> buildEstimationMap({
      String? id,
      String? projectId,
      String? estimateName,
      bool? isLocked,
      String? lockedByUserId,
      String? lockedAt,
      String? createdAt,
      String? updatedAt,
    }) {
      return EstimationTestDataMapFactory.createFakeEstimationData(
        id: id,
        projectId: projectId,
        estimateName: estimateName,
        isLocked: isLocked,
        lockedByUserId: lockedByUserId,
        lockedAt: lockedAt,
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
        expect(bloc.state, isA<ChangeLockStatusInitial>());
      });
    });

    group('ChangeLockStatusRequested', () {
      blocTest<ChangeLockStatusBloc, ChangeLockStatusState>(
        'should emit in progress then success with locked status when locking succeeds',
        build: () {
          final estimationMap = buildEstimationMap(
            id: testEstimationId,
            projectId: testProjectId,
            estimateName: testEstimationName,
            isLocked: false,
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ChangeLockStatusRequested(
            estimationId: testEstimationId,
            isLocked: true,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<ChangeLockStatusInProgress>(),
          isA<ChangeLockStatusSuccess>().having(
            (s) => s.isLocked,
            'isLocked',
            isTrue,
          ),
        ],
      );

      blocTest<ChangeLockStatusBloc, ChangeLockStatusState>(
        'should emit in progress then success with unlocked status when unlocking succeeds',
        build: () {
          final estimationMap = buildEstimationMap(
            id: testEstimationId,
            projectId: testProjectId,
            estimateName: testEstimationName,
            isLocked: true,
            lockedByUserId: 'user-1',
            lockedAt: DateTime.now().toIso8601String(),
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ChangeLockStatusRequested(
            estimationId: testEstimationId,
            isLocked: false,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<ChangeLockStatusInProgress>(),
          isA<ChangeLockStatusSuccess>().having(
            (s) => s.isLocked,
            'isLocked',
            isFalse,
          ),
        ],
      );

      blocTest<ChangeLockStatusBloc, ChangeLockStatusState>(
        'should emit failure when repository returns connection error',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.socket;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ChangeLockStatusRequested(
            estimationId: testEstimationId,
            isLocked: true,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<ChangeLockStatusInProgress>(),
          isA<ChangeLockStatusFailure>().having(
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

      blocTest<ChangeLockStatusBloc, ChangeLockStatusState>(
        'should emit failure when repository returns timeout error',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.timeout;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ChangeLockStatusRequested(
            estimationId: testEstimationId,
            isLocked: true,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<ChangeLockStatusInProgress>(),
          isA<ChangeLockStatusFailure>().having(
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

      blocTest<ChangeLockStatusBloc, ChangeLockStatusState>(
        'should emit failure when repository returns not found error',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.postgrest;
          fakeSupabaseWrapper.postgrestErrorCode =
              PostgresErrorCode.noDataFound;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ChangeLockStatusRequested(
            estimationId: testEstimationId,
            isLocked: true,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<ChangeLockStatusInProgress>(),
          isA<ChangeLockStatusFailure>().having(
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

    group('Repository integration', () {
      blocTest<ChangeLockStatusBloc, ChangeLockStatusState>(
        'should call data source with correct parameters',
        build: () {
          final estimationMap = buildEstimationMap(
            id: testEstimationId,
            projectId: testProjectId,
            estimateName: testEstimationName,
            isLocked: false,
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ChangeLockStatusRequested(
            estimationId: testEstimationId,
            isLocked: true,
            projectId: testProjectId,
          ),
        ),
        verify: (bloc) {
          final calls = fakeSupabaseWrapper.getMethodCallsFor('update');
          expect(calls, hasLength(1));
          expect(
            calls.first['table'],
            equals(DatabaseConstants.costEstimatesTable),
          );
          expect(calls.first['filterColumn'], equals('id'));
          expect(calls.first['filterValue'], testEstimationId);
          expect(calls.first['data'], containsPair('is_locked', true));
        },
      );
    });
  });
}

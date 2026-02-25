import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/rename_estimation_bloc/rename_estimation_bloc.dart';
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
  group('RenameEstimationBloc', () {
    late RenameEstimationBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeClockImpl fakeClock;

    const testProjectId = 'test-project-123';
    const testEstimationId = 'test-estimation-123';
    const testEstimationName = 'Test Estimation';
    const testNewName = 'Renamed Estimation';

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
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
      bloc = Modular.get<RenameEstimationBloc>();
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
      test('should start in initial state with save disabled', () {
        expect(bloc.state, isA<RenameEstimationInitial>());
        expect(bloc.state.isSaveEnabled, isFalse);
      });
    });

    group('RenameEstimationTextChanged', () {
      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should emit state with save enabled when text is not empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const RenameEstimationTextChanged('New Name')),
        expect: () => [
          isA<RenameEstimationEditing>().having(
            (s) => s.isSaveEnabled,
            'isSaveEnabled',
            isTrue,
          ),
        ],
      );

      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should emit state with save enabled when text has spaces but trims to non-empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const RenameEstimationTextChanged('  Name  ')),
        expect: () => [
          isA<RenameEstimationEditing>().having(
            (s) => s.isSaveEnabled,
            'isSaveEnabled',
            isTrue,
          ),
        ],
      );

      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should emit state with save disabled when text is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const RenameEstimationTextChanged('')),
        expect: () => [
          isA<RenameEstimationEditing>().having(
            (s) => s.isSaveEnabled,
            'isSaveEnabled',
            isFalse,
          ),
        ],
      );

      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should emit state with save disabled when text is only whitespace',
        build: () => bloc,
        act: (bloc) => bloc.add(const RenameEstimationTextChanged('   ')),
        expect: () => [
          isA<RenameEstimationEditing>().having(
            (s) => s.isSaveEnabled,
            'isSaveEnabled',
            isFalse,
          ),
        ],
      );
    });

    group('RenameEstimationRequested', () {
      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should emit in progress then success with new name when renaming succeeds',
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
          const RenameEstimationRequested(
            estimationId: testEstimationId,
            newName: testNewName,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<RenameEstimationInProgress>(),
          isA<RenameEstimationSuccess>().having(
            (s) => s.newName,
            'newName',
            equals(testNewName),
          ),
        ],
      );

      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should trim whitespace from new name',
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
          const RenameEstimationRequested(
            estimationId: testEstimationId,
            newName: '  $testNewName  ',
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<RenameEstimationInProgress>(),
          isA<RenameEstimationSuccess>().having(
            (s) => s.newName,
            'newName',
            equals(testNewName),
          ),
        ],
      );

      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should emit failure when repository returns connection error',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.socket;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const RenameEstimationRequested(
            estimationId: testEstimationId,
            newName: testNewName,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<RenameEstimationInProgress>(),
          isA<RenameEstimationFailure>()
              .having(
                (s) => s.failure,
                'failure',
                isA<EstimationFailure>().having(
                  (f) => f.errorType,
                  'errorType',
                  EstimationErrorType.connectionError,
                ),
              )
              .having((s) => s.isSaveEnabled, 'isSaveEnabled', isTrue),
        ],
      );

      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should emit failure when repository returns timeout error',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.timeout;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const RenameEstimationRequested(
            estimationId: testEstimationId,
            newName: testNewName,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<RenameEstimationInProgress>(),
          isA<RenameEstimationFailure>()
              .having(
                (s) => s.failure,
                'failure',
                isA<EstimationFailure>().having(
                  (f) => f.errorType,
                  'errorType',
                  EstimationErrorType.timeoutError,
                ),
              )
              .having((s) => s.isSaveEnabled, 'isSaveEnabled', isTrue),
        ],
      );

      blocTest<RenameEstimationBloc, RenameEstimationState>(
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
          const RenameEstimationRequested(
            estimationId: testEstimationId,
            newName: testNewName,
            projectId: testProjectId,
          ),
        ),
        expect: () => [
          isA<RenameEstimationInProgress>(),
          isA<RenameEstimationFailure>()
              .having(
                (s) => s.failure,
                'failure',
                isA<EstimationFailure>().having(
                  (f) => f.errorType,
                  'errorType',
                  EstimationErrorType.notFoundError,
                ),
              )
              .having((s) => s.isSaveEnabled, 'isSaveEnabled', isTrue),
        ],
      );

      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should allow retry rename after failure',
        build: () {
          fakeSupabaseWrapper.shouldThrowOnUpdate = true;
          fakeSupabaseWrapper.updateExceptionType =
              SupabaseExceptionType.socket;

          final estimationMap = buildEstimationMap(
            id: testEstimationId,
            projectId: testProjectId,
            estimateName: testEstimationName,
          );
          seedEstimationTable([estimationMap]);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(
            const RenameEstimationRequested(
              estimationId: testEstimationId,
              newName: testNewName,
              projectId: testProjectId,
            ),
          );
          await bloc.stream.firstWhere(
            (state) => state is RenameEstimationFailure,
          );
          fakeSupabaseWrapper.shouldThrowOnUpdate = false;
          bloc.add(
            const RenameEstimationRequested(
              estimationId: testEstimationId,
              newName: 'Retried Name',
              projectId: testProjectId,
            ),
          );
        },
        expect: () => [
          isA<RenameEstimationInProgress>(),
          isA<RenameEstimationFailure>(),
          isA<RenameEstimationInProgress>(),
          isA<RenameEstimationSuccess>().having(
            (s) => s.newName,
            'newName',
            equals('Retried Name'),
          ),
        ],
      );
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/rename_estimation_bloc/rename_estimation_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../helpers/estimation_test_data_map_factory.dart';

void main() {
  group('RenameEstimationBloc', () {
    late RenameEstimationBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    late FakeProjectRepository fakeProjectRepository;
    late FakeClockImpl fakeClock;

    const testProjectId = 'test-project-123';
    const testEstimationId = 'test-estimation-123';
    const testEstimationName = 'Test Estimation';
    const testNewName = 'Renamed Estimation';

    setUpAll(() {
      fakeClock = FakeClockImpl();
      final bootstrap = FakeAppBootstrapFactory.create(
        supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
      );
      Modular.init(EstimationModule(bootstrap));

      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;

      Modular.replaceInstance<ProjectRepository>(FakeProjectRepository());
      fakeProjectRepository =
          Modular.get<ProjectRepository>() as FakeProjectRepository;
    });

    tearDownAll(() {
      Modular.destroy();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
      fakeProjectRepository.setProjectPermissions(testProjectId, [
        PermissionConstants.editCostEstimation,
      ]);
      bloc = Modular.get<RenameEstimationBloc>();
    });

    tearDown(() {
      bloc.close();
    });

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

    group('RenameEstimationReset', () {
      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should reset to initial state from editing state',
        build: () => bloc,
        act: (bloc) => bloc
          ..add(const RenameEstimationTextChanged('Some text'))
          ..add(const RenameEstimationReset()),
        expect: () => [
          isA<RenameEstimationEditing>(),
          isA<RenameEstimationInitial>().having(
            (s) => s.isSaveEnabled,
            'isSaveEnabled',
            isFalse,
          ),
        ],
      );

      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should reset to initial state when reset event is dispatched',
        build: () => bloc,
        seed: () => const RenameEstimationFailure(
          EstimationFailure(errorType: EstimationErrorType.connectionError),
          isSaveEnabled: true,
        ),
        act: (bloc) => bloc.add(const RenameEstimationReset()),
        expect: () => [
          isA<RenameEstimationInitial>().having(
            (s) => s.isSaveEnabled,
            'isSaveEnabled',
            isFalse,
          ),
        ],
      );
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
          final estimationMap =
              EstimationTestDataMapFactory.createFakeEstimationData(
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
          final estimationMap =
              EstimationTestDataMapFactory.createFakeEstimationData(
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

          final estimationMap =
              EstimationTestDataMapFactory.createFakeEstimationData(
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

    group('Permission checks', () {
      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should emit permission denied failure when user lacks edit permission',
        build: () {
          fakeProjectRepository.setProjectPermissions(testProjectId, []);
          final estimationMap =
              EstimationTestDataMapFactory.createFakeEstimationData(
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
          isA<RenameEstimationFailure>()
              .having(
                (s) => s.failure,
                'failure',
                isA<EstimationFailure>().having(
                  (f) => f.errorType,
                  'errorType',
                  EstimationErrorType.permissionDenied,
                ),
              )
              .having((s) => s.isSaveEnabled, 'isSaveEnabled', isTrue),
        ],
      );

      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should succeed when user has edit permission',
        build: () {
          fakeProjectRepository.setProjectPermissions(testProjectId, [
            PermissionConstants.editCostEstimation,
          ]);
          final estimationMap =
              EstimationTestDataMapFactory.createFakeEstimationData(
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
        'should not proceed to rename when permission denied',
        build: () {
          fakeProjectRepository.setProjectPermissions(testProjectId, []);
          final estimationMap =
              EstimationTestDataMapFactory.createFakeEstimationData(
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
        verify: (_) {
          final updateCalls = fakeSupabaseWrapper.getMethodCallsFor('update');
          expect(updateCalls, isEmpty);
        },
      );
    });
  });
}

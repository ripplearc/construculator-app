import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/rename_estimation_bloc/rename_estimation_bloc.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimates_database.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  group('RenameEstimationBloc', () {
    late RenameEstimationBloc bloc;
    late FakeSupabaseWrapper fakeSupabaseWrapper;
    final fakePhoneDatabase = FakeCostEstimatesDatabase();
    late FakeProjectRepository fakeProjectRepository;
    late FakeClockImpl fakeClock;
    late FakeCurrentProjectNotifier fakeCurrentProjectNotifier;

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
      Modular.replaceInstance<PowerSyncDatabaseWrapper>(fakePhoneDatabase);

      fakeSupabaseWrapper =
          Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;

      Modular.replaceInstance<ProjectRepository>(FakeProjectRepository());
      fakeProjectRepository =
          Modular.get<ProjectRepository>() as FakeProjectRepository;

      fakeCurrentProjectNotifier = FakeCurrentProjectNotifier(
        initialProjectId: testProjectId,
      );
      Modular.replaceInstance<CurrentProjectNotifier>(
        fakeCurrentProjectNotifier,
      );
    });

    tearDownAll(() {
      Modular.destroy();
      fakePhoneDatabase.dispose();
    });

    setUp(() {
      fakeSupabaseWrapper.reset();
      fakePhoneDatabase.reset();
      fakeCurrentProjectNotifier.reset(projectId: testProjectId);
      fakeProjectRepository.setProjectPermissions(testProjectId, [
        PermissionConstants.editCostEstimation,
      ]);
      bloc = Modular.get<RenameEstimationBloc>();
    });

    tearDown(() {
      bloc.close();
    });

    void seedEstimationTable(List<Map<String, dynamic>> rows) {
      fakePhoneDatabase.seedRows(rows);
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
        'should emit unexpected failure when current project is unavailable',
        build: () {
          fakeCurrentProjectNotifier.reset(projectId: null);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const RenameEstimationRequested(
            estimationId: testEstimationId,
            newName: testNewName,
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
                  EstimationErrorType.unexpectedError,
                ),
              )
              .having((s) => s.isSaveEnabled, 'isSaveEnabled', isTrue),
        ],
        verify: (_) {
          final updateCalls = fakeSupabaseWrapper.getMethodCallsFor('update');
          expect(updateCalls, isEmpty);
        },
      );

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
        'should emit failure when the phone cannot save the rename',
        build: () {
          seedEstimationTable([
            EstimationTestDataMapFactory.createFakeEstimationData(
              id: testEstimationId,
              projectId: testProjectId,
              estimateName: testEstimationName,
            ),
          ]);
          fakePhoneDatabase.executeError = Exception('disk full');
          return bloc;
        },
        act: (bloc) => bloc.add(
          const RenameEstimationRequested(
            estimationId: testEstimationId,
            newName: testNewName,
          ),
        ),
        expect: () => [
          isA<RenameEstimationInProgress>(),
          isA<RenameEstimationFailure>()
              .having((s) => s.failure, 'failure', isA<UnexpectedFailure>())
              .having((s) => s.isSaveEnabled, 'isSaveEnabled', isTrue),
        ],
      );

      blocTest<RenameEstimationBloc, RenameEstimationState>(
        'should emit failure when repository returns not found error',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const RenameEstimationRequested(
            estimationId: testEstimationId,
            newName: testNewName,
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
          final estimationMap =
              EstimationTestDataMapFactory.createFakeEstimationData(
                id: testEstimationId,
                projectId: testProjectId,
                estimateName: testEstimationName,
              );
          seedEstimationTable([estimationMap]);
          fakePhoneDatabase.executeError = Exception('disk full');
          return bloc;
        },
        act: (bloc) async {
          bloc.add(
            const RenameEstimationRequested(
              estimationId: testEstimationId,
              newName: testNewName,
            ),
          );
          await bloc.stream.firstWhere(
            (state) => state is RenameEstimationFailure,
          );
          fakePhoneDatabase.executeError = null;
          bloc.add(
            const RenameEstimationRequested(
              estimationId: testEstimationId,
              newName: 'Retried Name',
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

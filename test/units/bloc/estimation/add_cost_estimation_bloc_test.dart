import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/features/estimation/data/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddCostEstimationBloc', () {
    late AddCostEstimationBloc bloc;
    late FakeCostEstimationRepository fakeRepository;
    late FakeClockImpl fakeClock;

    const testProjectId = 'test-project-123';
    const testCreatorUserId = 'test-user-123';
    const testEstimationName = 'Test Estimation';

    setUpAll(() {
      fakeClock = FakeClockImpl();
      final bootstrap = AppBootstrap(
        supabaseWrapper: FakeSupabaseWrapper(clock: fakeClock),
        config: FakeAppConfig(),
        envLoader: FakeEnvLoader(),
      );
      Modular.init(EstimationModule(bootstrap));
      Modular.replaceInstance<CostEstimationRepository>(
        FakeCostEstimationRepository(clock: fakeClock),
      );

      fakeRepository =
          Modular.get<CostEstimationRepository>()
              as FakeCostEstimationRepository;
    });

    tearDownAll(() {
      Modular.dispose();
    });

    setUp(() {
      fakeRepository.reset();
      bloc = Modular.get<AddCostEstimationBloc>();
    });

    test('initial state is AddCostEstimationInitial', () {
      expect(bloc.state, isA<AddCostEstimationInitial>());
    });

    group('AddCostEstimationSubmitted', () {
      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'emits [InProgress, Success] when estimation is created successfully',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const AddCostEstimationSubmitted(
            estimationName: testEstimationName,
            projectId: testProjectId,
            creatorUserId: testCreatorUserId,
          ),
        ),
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationSuccess>()
              .having(
                (s) => s.costEstimation.estimateName,
                'estimateName',
                testEstimationName,
              )
              .having(
                (s) => s.costEstimation.projectId,
                'projectId',
                testProjectId,
              )
              .having(
                (s) => s.costEstimation.creatorUserId,
                'creatorUserId',
                testCreatorUserId,
              ),
        ],
      );

      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'emits [InProgress, Failure] when repository returns failure',
        build: () {
          fakeRepository.shouldReturnFailureOnCreateEstimation = true;
          fakeRepository.createEstimationFailureType =
              EstimationErrorType.connectionError;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AddCostEstimationSubmitted(
            estimationName: testEstimationName,
            projectId: testProjectId,
            creatorUserId: testCreatorUserId,
          ),
        ),
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationFailure>(),
        ],
      );

      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'passes failure type: connectionError',
        build: () {
          fakeRepository.shouldReturnFailureOnCreateEstimation = true;
          fakeRepository.createEstimationFailureType =
              EstimationErrorType.connectionError;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AddCostEstimationSubmitted(
            estimationName: testEstimationName,
            projectId: testProjectId,
            creatorUserId: testCreatorUserId,
          ),
        ),
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationFailure>().having(
            (s) => (s.failure as EstimationFailure).errorType,
            'errorType',
            EstimationErrorType.connectionError,
          ),
        ],
      );

      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'passes failure type: parsingError',
        build: () {
          fakeRepository.shouldReturnFailureOnCreateEstimation = true;
          fakeRepository.createEstimationFailureType =
              EstimationErrorType.parsingError;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AddCostEstimationSubmitted(
            estimationName: testEstimationName,
            projectId: testProjectId,
            creatorUserId: testCreatorUserId,
          ),
        ),
        expect: () => [
          isA<AddCostEstimationInProgress>(),
          isA<AddCostEstimationFailure>().having(
            (s) => (s.failure as EstimationFailure).errorType,
            'errorType',
            EstimationErrorType.parsingError,
          ),
        ],
      );

      blocTest<AddCostEstimationBloc, AddCostEstimationState>(
        'created estimation has correct default values',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const AddCostEstimationSubmitted(
            estimationName: testEstimationName,
            projectId: testProjectId,
            creatorUserId: testCreatorUserId,
          ),
        ),
        verify: (bloc) {
          final state = bloc.state as AddCostEstimationSuccess;
          final estimation = state.costEstimation;

          expect(estimation.lockStatus, isA<UnlockedStatus>());
          expect(
            estimation.markupConfiguration.overallType,
            MarkupType.overall,
          );
          expect(
            estimation.markupConfiguration.overallValue.type,
            MarkupValueType.percentage,
          );
          expect(estimation.markupConfiguration.overallValue.value, 0.0);
        },
      );
    });
  });
}

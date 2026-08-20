import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/estimation/estimation_library_module.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimation_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';

class _TestModule extends Module {
  final AppBootstrap appBootstrap;
  _TestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    ProjectLibraryModule(appBootstrap),
    EstimationLibraryModule(appBootstrap),
  ];

  @override
  void binds(Injector i) {
    i.add<WatchRecentEstimationsUseCase>(
      () => WatchRecentEstimationsUseCase(i(), i()),
    );
    i.add<RecentEstimationsBloc>(
      () => RecentEstimationsBloc(
        watchRecentEstimationsUseCase: i(),
        currentProjectNotifier: i(),
      ),
    );
  }
}

void main() {
  late RecentEstimationsBloc bloc;
  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late CurrentProjectNotifier currentProjectNotifier;

  const testProjectId = 'test_project_id';

  setUpAll(() {
    final bootstrap = FakeAppBootstrapFactory.create();
    Modular.init(_TestModule(bootstrap));
    fakeSupabaseWrapper = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() {
    fakeSupabaseWrapper.reset();
    fakeSupabaseWrapper.shouldThrowOnSelectPaginated = false;
    fakeSupabaseWrapper.selectPaginatedExceptionType = null;

    currentProjectNotifier = Modular.get<CurrentProjectNotifier>();
    currentProjectNotifier.setCurrentProjectId(testProjectId);
    bloc = Modular.get<RecentEstimationsBloc>();
  });

  void seedEstimationTable(List<Map<String, dynamic>> rows) {
    fakeSupabaseWrapper.addTableData(
      DatabaseConstants.costEstimatesTable,
      rows,
    );
  }

  final tDate = DateTime(2025, 1, 1, 8, 0);
  final tEstimationMap = EstimationTestDataMapFactory.createFakeEstimationData(
    id: '1',
    projectId: testProjectId,
    estimateName: 'Test Estimate',
    totalCost: 100.0,
    createdAt: tDate.toIso8601String(),
    updatedAt: tDate.toIso8601String(),
  );
  final tEstimations = [CostEstimateDto.fromJson(tEstimationMap).toDomain()];

  test(
    'initial state should be RecentEstimationsLoading with null estimations',
    () {
      expect(bloc.state, const RecentEstimationsLoading());
    },
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'emits [RecentEstimationsLoading, RecentEstimationsLoaded] when data streams successfully',
    build: () {
      seedEstimationTable([tEstimationMap]);
      return bloc;
    },
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      RecentEstimationsLoaded(tEstimations),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'emits [RecentEstimationsLoading, RecentEstimationsError] when data stream fails',
    build: () {
      fakeSupabaseWrapper.shouldThrowOnSelectPaginated = true;
      fakeSupabaseWrapper.selectPaginatedExceptionType =
          SupabaseExceptionType.socket;
      return bloc;
    },
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      const RecentEstimationsError(
        'EstimationFailure(EstimationErrorType.connectionError)',
      ),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'preserves lastKnownEstimations when re-watching',
    build: () {
      seedEstimationTable([tEstimationMap]);
      return bloc;
    },
    seed: () => RecentEstimationsLoaded(tEstimations),
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
    expect: () => [
      RecentEstimationsLoading(lastKnownEstimations: tEstimations),
      RecentEstimationsLoaded(tEstimations),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'stays in RecentEstimationsLoading when there is no current project — '
    'right after login no failure banner may show before the project '
    'dropdown auto-selection lands (CA-900)',
    build: () {
      currentProjectNotifier.setCurrentProjectId(null);
      return bloc;
    },
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'emits RecentEstimationsError when the estimations stream errors '
    'instead of leaving the section stuck on loading',
    build: () {
      // Constructed directly over a repository fake whose stream errors:
      // the module-bound repository surfaces failures as Left values, so a
      // raw stream error is only reachable this way.
      final fakeRepository = FakeCostEstimationRepository()
        ..streamFactory = (() => Stream.error(Exception('stream broke')));
      final notifier = FakeCurrentProjectNotifier(
        initialProjectId: testProjectId,
      );
      return RecentEstimationsBloc(
        watchRecentEstimationsUseCase: WatchRecentEstimationsUseCase(
          fakeRepository,
          notifier,
        ),
        currentProjectNotifier: notifier,
      );
    },
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      isA<RecentEstimationsError>(),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'preserves the typed failure message when the stream errors with a '
    'Failure instead of collapsing it to UnexpectedFailure',
    build: () {
      final fakeRepository = FakeCostEstimationRepository()
        ..streamFactory = (() => Stream.error(
              const EstimationFailure(
                errorType: EstimationErrorType.timeoutError,
              ),
            ));
      final notifier = FakeCurrentProjectNotifier(
        initialProjectId: testProjectId,
      );
      return RecentEstimationsBloc(
        watchRecentEstimationsUseCase: WatchRecentEstimationsUseCase(
          fakeRepository,
          notifier,
        ),
        currentProjectNotifier: notifier,
      );
    },
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      const RecentEstimationsError(
        'EstimationFailure(EstimationErrorType.timeoutError)',
      ),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    'starts watching once a project selection arrives after a null start',
    build: () {
      seedEstimationTable([tEstimationMap]);
      currentProjectNotifier.setCurrentProjectId(null);
      return bloc;
    },
    act: (bloc) async {
      bloc.add(const RecentEstimationsWatchStarted());
      currentProjectNotifier.setCurrentProjectId(testProjectId);
      await bloc.stream.firstWhere(
        (state) => state is RecentEstimationsLoaded,
      );
    },
    expect: () => [
      // The re-dispatched watch start emits an equal Loading state, which
      // the bloc deduplicates, so only the initial Loading is observed.
      const RecentEstimationsLoading(lastKnownEstimations: null),
      RecentEstimationsLoaded(tEstimations),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    're-watches when the current project changes after start',
    build: () {
      seedEstimationTable([tEstimationMap]);
      return bloc;
    },
    act: (bloc) {
      bloc.add(const RecentEstimationsWatchStarted());
      return expectLater(
        bloc.stream,
        emitsThrough(RecentEstimationsLoaded(tEstimations)),
      ).then((_) {
        final anotherProjectEstimationMap =
            EstimationTestDataMapFactory.createFakeEstimationData(
              id: '2',
              projectId: 'another_project',
              estimateName: 'Test Estimate',
              totalCost: 100.0,
              createdAt: tDate.toIso8601String(),
              updatedAt: tDate.toIso8601String(),
            );
        seedEstimationTable([anotherProjectEstimationMap]);
        currentProjectNotifier.setCurrentProjectId('another_project');
      });
    },
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      RecentEstimationsLoaded(tEstimations),
      RecentEstimationsLoading(lastKnownEstimations: tEstimations),
      RecentEstimationsLoaded([
        CostEstimateDto.fromJson(
          EstimationTestDataMapFactory.createFakeEstimationData(
            id: '2',
            projectId: 'another_project',
            estimateName: 'Test Estimate',
            totalCost: 100.0,
            createdAt: tDate.toIso8601String(),
            updatedAt: tDate.toIso8601String(),
          ),
        ).toDomain(),
      ]),
    ],
  );
}

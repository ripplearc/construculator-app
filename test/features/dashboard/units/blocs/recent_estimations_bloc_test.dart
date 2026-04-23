import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  late RecentEstimationsBloc bloc;
  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late CurrentProjectNotifier currentProjectNotifier;

  const testProjectId = 'test_project_id';

  setUpAll(() {
    final bootstrap = FakeAppBootstrapFactory.create();
    Modular.init(DashboardModule(bootstrap));
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
    'emits [RecentEstimationsLoading, RecentEstimationsError] when there is no current project',
    build: () {
      currentProjectNotifier.setCurrentProjectId(null);
      return bloc;
    },
    act: (bloc) => bloc.add(const RecentEstimationsWatchStarted()),
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      const RecentEstimationsError(
        'EstimationFailure(EstimationErrorType.unexpectedError)',
      ),
    ],
  );

  blocTest<RecentEstimationsBloc, RecentEstimationsState>(
    're-watches when the current project changes after start',
    build: () {
      repository.streamFactory = () =>
          Stream<Either<Failure, List<CostEstimate>>>.value(
            Right<Failure, List<CostEstimate>>(tEstimations),
          );
      return bloc;
    },
    act: (bloc) async {
      bloc.add(const RecentEstimationsWatchStarted());
      await Future<void>.delayed(Duration.zero);
      currentProjectNotifier.setCurrentProjectId('another_project');
    },
    expect: () => [
      const RecentEstimationsLoading(lastKnownEstimations: null),
      RecentEstimationsLoaded(tEstimations),
      RecentEstimationsLoading(lastKnownEstimations: tEstimations),
      RecentEstimationsLoaded(tEstimations),
    ],
  );
}

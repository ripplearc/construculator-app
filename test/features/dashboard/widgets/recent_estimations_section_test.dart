import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/default_tab_providers.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';

import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/estimation_card.dart';
import 'package:construculator/features/dashboard/presentation/widgets/recent_estimations_section.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/estimation/testing/fake_cost_estimation_repository.dart';

import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/estimation_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart';
import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

class _DashboardWithShellTestModule extends Module {
  final AppBootstrap appBootstrap;

  _DashboardWithShellTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [DashboardModule(appBootstrap)];

  @override
  void binds(Injector i) {
    i.addLazySingleton<TabModuleManager>(
      () => TabModuleManager(
        appBootstrap,
        providers: {
          for (final tab in ShellTab.values) tab: const NoOpTabModuleProvider(),
        },
      ),
    );
    i.add<AppShellBloc>(() => AppShellBloc(moduleLoader: i.get()));
  }
}

void main() {
  late FakeClockImpl clock;
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  late CurrentProjectNotifier currentProjectNotifier;
  late FakeCostEstimationRepository fakeRepository;

  late RecentEstimationsBloc bloc;

  CostEstimate estimationFromMap(Map<String, dynamic> map) {
    return CostEstimateDto.fromJson(map).toDomain();
  }

  void configureRepositoryStream(List<CostEstimate> estimations) {
    fakeRepository.streamFactory = () =>
        Stream.value(Right<Failure, List<CostEstimate>>(estimations));
  }

  Widget buildTestApp() {
    return MaterialApp(
      theme: createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: RecentEstimationsSection()),
    );
  }

  Future<void> pumpSection(WidgetTester tester) async {
    final settled = bloc.stream.firstWhere(
      (state) =>
          state is RecentEstimationsLoaded || state is RecentEstimationsError,
    );
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.runAsync(() => settled);
    await tester.pump();
  }

  setUpAll(() async {
    await loadAppFontsAll();

    clock = FakeClockImpl();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    router = FakeAppRouter();
    fakeRepository = FakeCostEstimationRepository();
  });

  setUp(() {
    fakeSupabase.reset();
    router.reset();
    fakeRepository.streamFactory = null;
    fakeRepository.streamToReturn = const Stream.empty();

    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(_DashboardWithShellTestModule(bootstrap));

    Modular.replaceInstance<AppRouter>(router);
    Modular.replaceInstance<CostEstimationRepository>(fakeRepository);

    currentProjectNotifier = Modular.get<CurrentProjectNotifier>();
    currentProjectNotifier.setCurrentProjectId(testProjectId);
    bloc = Modular.get<RecentEstimationsBloc>();
    Modular.replaceInstance<RecentEstimationsBloc>(bloc);
  });

  tearDown(() {
    Modular.destroy();
  });

  testWidgets('renders section title and view all button', (tester) async {

    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    expect(find.text('Recent cost estimations'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);
  });

  testWidgets('shows loading placeholders while estimations are loading', (
    tester,
  ) async {

    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(EstimationCard), findsNothing);
  });

  testWidgets('shows empty state when there are no estimations', (
    tester,
  ) async {
    configureRepositoryStream([]);

    await pumpSection(tester);

    expect(find.text('No recent estimations found.'), findsOneWidget);
  });

  testWidgets('shows error message when estimations fail to load', (
    tester,
  ) async {
    currentProjectNotifier.setCurrentProjectId(null);

    await pumpSection(tester);

    expect(find.text('Failed to load recent estimations.'), findsOneWidget);
  });

  testWidgets('renders estimation cards when data is loaded', (tester) async {
    const estimateName = 'Office Build';
    configureRepositoryStream([
      estimationFromMap(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: 'estimation-1',
          projectId: testProjectId,
          estimateName: estimateName,
        ),
      ),
    ]);

    await pumpSection(tester);

    expect(find.byType(EstimationCard), findsOneWidget);
    expect(find.text(estimateName), findsOneWidget);
  });

  testWidgets('navigates to estimation details when a card is tapped', (
    tester,
  ) async {
    const estimationId = 'estimation-42';
    configureRepositoryStream([
      estimationFromMap(
        EstimationTestDataMapFactory.createFakeEstimationData(
          id: estimationId,
          projectId: testProjectId,
          estimateName: 'Tap Target Estimate',
        ),
      ),
    ]);

    await pumpSection(tester);

    await tester.tap(find.text('Tap Target Estimate'));
    await tester.pump();

    expect(router.navigationHistory.length, 1);
    expect(
      router.navigationHistory.first.route,
      '$fullEstimationDetailsRoute/$estimationId',
    );
  });

  testWidgets('shows view all when a project is selected', (tester) async {
    configureRepositoryStream([
      estimationFromMap(
        EstimationTestDataMapFactory.createFakeEstimationData(
          projectId: testProjectId,
        ),
      ),
    ]);

    await pumpSection(tester);

    expect(find.text('View all'), findsOneWidget);
  });

  testWidgets('does not navigate when view all is tapped without a project', (
    tester,
  ) async {
    currentProjectNotifier.setCurrentProjectId(null);

    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    final navigatorCount = tester.widgetList(find.byType(Navigator)).length;

    await tester.tap(find.text('View all'));
    await tester.pump();

    expect(tester.widgetList(find.byType(Navigator)).length, navigatorCount);
    expect(router.navigationHistory, isEmpty);
  });

  testWidgets('keeps showing estimations while reloading', (tester) async {
    const estimateName = 'Stale While Revalidate';
    final estimation = estimationFromMap(
      EstimationTestDataMapFactory.createFakeEstimationData(
        id: '1',
        projectId: testProjectId,
        estimateName: estimateName,
      ),
    );
    configureRepositoryStream([estimation]);

    await pumpSection(tester);

    expect(find.text(estimateName), findsOneWidget);

    bloc.add(const RecentEstimationsWatchStarted());
    await tester.pump();

    expect(find.text(estimateName), findsOneWidget);
  });
}

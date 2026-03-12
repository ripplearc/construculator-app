import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_log_repository_impl.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_log_bloc/cost_estimation_log_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_logs_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../helpers/log_test_data_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 844);
  const ratio = 1.0;
  const estimateId = 'estimate-123';

  late FakeSupabaseWrapper fakeSupabase;
  late FakeClockImpl fakeClock;
  late AppBootstrap bootstrap;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    CoreToast.disableTimers();

    fakeClock = FakeClockImpl();
    fakeSupabase = FakeSupabaseWrapper(clock: fakeClock);
    bootstrap = AppBootstrap(
      supabaseWrapper: fakeSupabase,
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
    );

    Modular.init(EstimationModule(bootstrap));
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() async {
    await loadAppFontsAll();
    fakeSupabase.reset();
    fakeSupabase.shouldDelayOperations = false;
    fakeSupabase.completer = null;
  });

  void seedLogs(List<Map<String, dynamic>> rows) {
    fakeSupabase.addTableData(DatabaseConstants.costEstimationLogsTable, rows);
  }

  Future<void> pumpLogsList(WidgetTester tester) async {
    final bloc = Modular.get<CostEstimationLogBloc>();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<CostEstimationLogBloc>.value(
            value: bloc,
            child: const CostEstimationLogsList(
              estimateId: estimateId,
              estimateName: 'Kitchen Remodel',
            ),
          ),
        ),
      ),
    );
  }

  group('CostEstimationLogsList Screenshot Tests', () {
    testWidgets('empty state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpLogsList(tester);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CostEstimationLogsList),
        matchesGoldenFile(
          'goldens/cost_estimation_logs_list/${size.width}x${size.height}/logs_list_empty.png',
        ),
      );
    });

    testWidgets('loaded state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      seedLogs([
        LogTestDataFactory.createLogData(
          id: 'log-1',
          estimateId: estimateId,
          activity: 'costEstimationCreated',
          firstName: 'Liam',
        ),
        LogTestDataFactory.createLogData(
          id: 'log-2',
          estimateId: estimateId,
          activity: 'costFileUploaded',
          activityDetails: {'fileName': 'materials.xlsx'},
          firstName: 'Ava',
          loggedAt: '2025-03-01T10:00:00.000Z',
        ),
      ]);

      await pumpLogsList(tester);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CostEstimationLogsList),
        matchesGoldenFile(
          'goldens/cost_estimation_logs_list/${size.width}x${size.height}/logs_list_loaded.png',
        ),
      );
    });

    testWidgets('load-more error with retry', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      final pageSize = CostEstimationLogRepositoryImpl.defaultPageSize;
      seedLogs(
        LogTestDataFactory.createLogDataList(
          count: pageSize + 1,
          estimateId: estimateId,
        ),
      );

      await pumpLogsList(tester);
      await tester.pumpAndSettle();

      fakeSupabase.shouldThrowOnSelectPaginated = true;
      fakeSupabase.selectPaginatedExceptionType = SupabaseExceptionType.timeout;

      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -1800),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Retry'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CostEstimationLogsList),
        matchesGoldenFile(
          'goldens/cost_estimation_logs_list/${size.width}x${size.height}/logs_list_load_more_error.png',
        ),
      );
    });
  });
}

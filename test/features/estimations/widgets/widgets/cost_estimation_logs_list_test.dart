import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_log_repository_impl.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_log_bloc/cost_estimation_log_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_log_tile.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_logs_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
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

import '../../helpers/log_test_data_factory.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeClockImpl fakeClock;
  late AppBootstrap bootstrap;
  BuildContext? buildContext;

  const estimateId = 'estimate-123';
  const estimateName = 'Kitchen Remodel';

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

  setUp(() {
    fakeSupabase.reset();
  });

  Widget buildTestApp(CostEstimationLogBloc bloc) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          buildContext = context;
          return Scaffold(
            body: BlocProvider<CostEstimationLogBloc>.value(
              value: bloc,
              child: const CostEstimationLogsList(
                estimateId: estimateId,
                estimateName: estimateName,
              ),
            ),
          );
        },
      ),
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> pumpLogsList(WidgetTester tester) async {
    final bloc = Modular.get<CostEstimationLogBloc>();
    addTearDown(bloc.close);
    await tester.pumpWidget(buildTestApp(bloc));
    await tester.pumpAndSettle();
  }

  void seedLogs(List<Map<String, dynamic>> rows) {
    fakeSupabase.addTableData(DatabaseConstants.costEstimationLogsTable, rows);
  }

  CostEstimationLog createExpectedLog({
    required String id,
    required CostEstimationActivityType activity,
    required String firstName,
    required DateTime loggedAt,
    Map<String, dynamic> activityDetails = const {},
  }) {
    return CostEstimationLog(
      id: id,
      estimateId: estimateId,
      activity: activity,
      user: UserProfile(
        id: 'user-default',
        credentialId: 'cred-default',
        firstName: firstName,
        lastName: 'Doe',
        professionalRole: 'Engineer',
        profilePhotoUrl: null,
      ),
      activityDetails: activityDetails,
      loggedAt: loggedAt,
    );
  }

  List<CostEstimationLog> renderedTileLogs(WidgetTester tester) {
    return tester
        .widgetList<CostEstimationLogTile>(find.byType(CostEstimationLogTile))
        .map((tile) => tile.log)
        .toList();
  }

  group('CostEstimationLogsList behavior', () {
    testWidgets('shows estimation name', (tester) async {
      await pumpLogsList(tester);

      expect(find.text(estimateName), findsOneWidget);
    });

    testWidgets('shows empty-state message when no logs exist', (tester) async {
      await pumpLogsList(tester);

      expect(find.text(l10n().noActivityLogs), findsOneWidget);
      expect(find.text(l10n().noActivityLogsDescription), findsOneWidget);
      expect(find.byType(CostEstimationLogTile), findsNothing);
    });

    testWidgets('renders activity logs fetched from repository', (
      tester,
    ) async {
      final olderLog = createExpectedLog(
        id: 'log-1',
        activity: CostEstimationActivityType.costEstimationCreated,
        firstName: 'Liam',
        loggedAt: DateTime.parse('2025-02-25T10:00:00.000Z'),
      );
      final newerLog = createExpectedLog(
        id: 'log-2',
        activity: CostEstimationActivityType.costEstimationRenamed,
        firstName: 'Ava',
        loggedAt: DateTime.parse('2025-03-01T10:00:00.000Z'),
        activityDetails: {'oldName': 'A', 'newName': 'B'},
      );

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
          activity: 'costEstimationRenamed',
          activityDetails: {'oldName': 'A', 'newName': 'B'},
          firstName: 'Ava',
          loggedAt: '2025-03-01T10:00:00.000Z',
        ),
      ]);

      await pumpLogsList(tester);

      expect(renderedTileLogs(tester), [newerLog, olderLog]);
    });

    testWidgets('supports pull-to-refresh and shows newly fetched logs', (
      tester,
    ) async {
      final initialLog = createExpectedLog(
        id: 'log-1',
        activity: CostEstimationActivityType.costEstimationCreated,
        firstName: 'First',
        loggedAt: DateTime.parse('2025-02-01T10:00:00.000Z'),
      );
      final refreshedLog = createExpectedLog(
        id: 'log-2',
        activity: CostEstimationActivityType.costEstimationCreated,
        firstName: 'Fresh',
        loggedAt: DateTime.parse('2025-03-10T10:00:00.000Z'),
      );

      seedLogs([
        LogTestDataFactory.createLogData(
          id: 'log-1',
          estimateId: estimateId,
          activity: 'costEstimationCreated',
          firstName: 'First',
          loggedAt: '2025-02-01T10:00:00.000Z',
        ),
      ]);

      await pumpLogsList(tester);
      expect(renderedTileLogs(tester), [initialLog]);

      fakeSupabase.clearMethodCalls();

      seedLogs([
        LogTestDataFactory.createLogData(
          id: 'log-2',
          estimateId: estimateId,
          activity: 'costEstimationCreated',
          firstName: 'Fresh',
          loggedAt: '2025-03-10T10:00:00.000Z',
        ),
      ]);

      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, 320),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(renderedTileLogs(tester), [refreshedLog]);

      final refreshQueries = fakeSupabase
          .getMethodCalls()
          .where(
            (call) =>
                call['method'] == 'selectPaginated' &&
                call['filterValue'] == estimateId &&
                call['rangeFrom'] == 0,
          )
          .length;

      expect(refreshQueries, 1);
    });

    testWidgets('loads more successfully when scrolled to bottom', (
      tester,
    ) async {
      final pageSize = CostEstimationLogRepositoryImpl.defaultPageSize;
      final totalSize = pageSize + 1;
      seedLogs(
        LogTestDataFactory.createLogDataList(
          count: totalSize,
          estimateId: estimateId,
        ),
      );

      await pumpLogsList(tester);

      fakeSupabase.clearMethodCalls();

      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -1800),
      );
      await tester.pumpAndSettle();

      final loadMoreQueries = fakeSupabase
          .getMethodCalls()
          .where(
            (call) =>
                call['method'] == 'selectPaginated' &&
                call['filterValue'] == estimateId &&
                call['rangeFrom'] == pageSize,
          )
          .length;

      expect(loadMoreQueries, 1);
      expect(find.text(l10n().retryButton), findsNothing);
    });

    testWidgets(
      'shows retry button on load-more failure and retries successfully',
      (tester) async {
        final pageSize = CostEstimationLogRepositoryImpl.defaultPageSize;
        seedLogs(
          LogTestDataFactory.createLogDataList(
            count: pageSize + 1,
            estimateId: estimateId,
          ),
        );

        await pumpLogsList(tester);
        expect(find.byType(CostEstimationLogTile), findsWidgets);

        fakeSupabase.shouldThrowOnSelectPaginated = true;
        fakeSupabase.selectPaginatedExceptionType =
            SupabaseExceptionType.timeout;

        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -1800),
        );
        await tester.pumpAndSettle();

        final retryButton = find.widgetWithText(CoreButton, l10n().retryButton);
        await tester.ensureVisible(retryButton);
        await tester.pumpAndSettle();

        expect(retryButton, findsOneWidget);

        fakeSupabase.shouldThrowOnSelectPaginated = false;
        fakeSupabase.clearMethodCalls();

        await tester.tap(retryButton);
        await tester.pumpAndSettle();

        expect(find.byType(CostEstimationLogTile), findsWidgets);
        expect(find.text(l10n().retryButton), findsNothing);

        final retryLoadMoreQueries = fakeSupabase
            .getMethodCalls()
            .where(
              (call) =>
                  call['method'] == 'selectPaginated' &&
                  call['filterValue'] == estimateId &&
                  call['rangeFrom'] == pageSize,
            )
            .length;

        expect(retryLoadMoreQueries, 1);
      },
    );

    testWidgets('does not auto-load-more again after load-more error', (
      tester,
    ) async {
      final pageSize = CostEstimationLogRepositoryImpl.defaultPageSize;
      seedLogs(
        LogTestDataFactory.createLogDataList(
          count: pageSize + 1,
          estimateId: estimateId,
        ),
      );

      await pumpLogsList(tester);

      fakeSupabase.clearMethodCalls();

      fakeSupabase.shouldThrowOnSelectPaginated = true;
      fakeSupabase.selectPaginatedExceptionType = SupabaseExceptionType.timeout;

      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -1800),
      );
      await tester.pumpAndSettle();

      final firstLoadMoreQueries = fakeSupabase
          .getMethodCalls()
          .where(
            (call) =>
                call['method'] == 'selectPaginated' &&
                call['filterValue'] == estimateId &&
                call['rangeFrom'] == pageSize,
          )
          .length;
      expect(firstLoadMoreQueries, 1);

      fakeSupabase.clearMethodCalls();

      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -1800),
      );
      await tester.pumpAndSettle();

      final secondLoadMoreQueries = fakeSupabase
          .getMethodCalls()
          .where(
            (call) =>
                call['method'] == 'selectPaginated' &&
                call['filterValue'] == estimateId &&
                call['rangeFrom'] == pageSize,
          )
          .length;
      expect(secondLoadMoreQueries, 0);
    });
  });

  group('CostEstimationLogsList error mapping', () {
    testWidgets('shows initial fetch timeout error message', (tester) async {
      fakeSupabase.shouldThrowOnSelectPaginated = true;
      fakeSupabase.selectPaginatedExceptionType = SupabaseExceptionType.timeout;

      await pumpLogsList(tester);

      final expectedMessage =
          '${l10n().errorLoadingLogs}: ${l10n().timeoutError}';
      expect(find.text(expectedMessage), findsOneWidget);
    });

    testWidgets('shows initial fetch connection error message', (tester) async {
      fakeSupabase.shouldThrowOnSelectPaginated = true;
      fakeSupabase.selectPaginatedExceptionType = SupabaseExceptionType.socket;

      await pumpLogsList(tester);

      final expectedMessage =
          '${l10n().errorLoadingLogs}: ${l10n().connectionError}';
      expect(find.text(expectedMessage), findsOneWidget);
    });

    testWidgets('shows initial fetch generic error message', (tester) async {
      fakeSupabase.shouldThrowOnSelectPaginated = true;
      fakeSupabase.selectPaginatedExceptionType = SupabaseExceptionType.unknown;

      await pumpLogsList(tester);

      final expectedMessage =
          '${l10n().errorLoadingLogs}: ${l10n().unexpectedErrorMessage}';
      expect(find.text(expectedMessage), findsOneWidget);
    });

    testWidgets('shows load more timeout error message in toast', (
      tester,
    ) async {
      final pageSize = CostEstimationLogRepositoryImpl.defaultPageSize;
      seedLogs(
        LogTestDataFactory.createLogDataList(
          count: pageSize + 1,
          estimateId: estimateId,
        ),
      );

      await pumpLogsList(tester);

      fakeSupabase.shouldThrowOnSelectPaginated = true;
      fakeSupabase.selectPaginatedExceptionType = SupabaseExceptionType.timeout;

      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -1800),
      );
      await tester.pumpAndSettle();

      final expectedMessage =
          '${l10n().loadMoreLogsError}: ${l10n().timeoutError}';
      expect(find.text(expectedMessage), findsOneWidget);
    });
  });
}

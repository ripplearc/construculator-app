import 'dart:async';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_log_repository_impl.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_log_bloc/cost_estimation_log_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_log_tile.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_logs_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';

import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
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
    bootstrap = FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase);

    Modular.init(EstimationModule(bootstrap));
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeSupabase.reset();
  });

  Widget buildTestApp(
    CostEstimationLogBloc bloc, {
    String name = estimateName,
  }) {
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
              child: CostEstimationLogsList(
                estimateId: estimateId,
                estimateName: name,
              ),
            ),
          );
        },
      ),
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<CostEstimationLogBloc> pumpLogsList(
    WidgetTester tester, {
    String name = estimateName,
  }) async {
    final bloc = Modular.get<CostEstimationLogBloc>();
    addTearDown(bloc.close);
    await tester.pumpWidget(buildTestApp(bloc, name: name));
    await tester.pumpAndSettle();
    return bloc;
  }

  void seedLogs(List<Map<String, dynamic>> rows) {
    fakeSupabase.addTableData(DatabaseConstants.costEstimationLogsTable, rows);
  }

  // One entry, so the list has an order to show under the title.
  void seedOneLog() {
    seedLogs([
      LogTestDataFactory.createLogData(
        id: 'log-1',
        estimateId: estimateId,
        activity: 'costEstimationCreated',
      ),
    ]);
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
    testWidgets('shows the Logs title, the estimate name and the order', (
      tester,
    ) async {
      seedOneLog();
      await pumpLogsList(tester);

      expect(find.text(l10n().logsAction), findsOneWidget);
      expect(find.text(estimateName), findsOneWidget);
      expect(find.text(l10n().logsNewestFirst), findsOneWidget);
    });

    testWidgets('cuts a long estimate name and keeps newest first whole', (
      tester,
    ) async {
      final longName = 'Kitchen Remodel ' * 20;
      seedOneLog();

      await pumpLogsList(tester, name: longName);

      final order = tester.getRect(find.text(l10n().logsNewestFirst));
      expect(
        order.right,
        lessThanOrEqualTo(
          tester.getSize(find.byType(CostEstimationLogsList)).width,
        ),
      );
      expect(
        tester.getSize(find.text(longName)).height,
        order.height,
        reason: 'the name is cut to one line, not wrapped',
      );
    });

    testWidgets('leaves out newest first when there are no entries', (
      tester,
    ) async {
      await pumpLogsList(tester);

      expect(find.text(l10n().logsAction), findsOneWidget);
      expect(find.text(estimateName), findsOneWidget);
      expect(
        find.text(l10n().logsNewestFirst),
        findsNothing,
        reason: 'an empty list has no order to state (CUJ 11 screen 14)',
      );
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
      expect(find.text(l10n().retryLoadLogsButton), findsNothing);
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

        final retryButton = find.widgetWithText(
          CoreButton,
          l10n().retryLoadLogsButton,
        );
        await tester.ensureVisible(retryButton);
        await tester.pumpAndSettle();

        expect(retryButton, findsOneWidget);

        fakeSupabase.shouldThrowOnSelectPaginated = false;
        fakeSupabase.clearMethodCalls();

        await tester.tap(retryButton);
        await tester.pumpAndSettle();

        expect(find.byType(CostEstimationLogTile), findsWidgets);
        expect(find.text(l10n().retryLoadLogsButton), findsNothing);

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

      final bloc = await pumpLogsList(tester);

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
        const Offset(0, 800),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -1800),
      );
      await tester.pumpAndSettle();

      final state = bloc.state;
      expect(state, isA<CostEstimationLogLoadMoreError>());
      expect((state as CostEstimationLogLoadMoreError).isLoadingMore, false);

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

  group('CostEstimationLogsList failure messages', () {
    for (final exceptionType in [
      SupabaseExceptionType.timeout,
      SupabaseExceptionType.socket,
      SupabaseExceptionType.unknown,
    ]) {
      testWidgets(
        'says the first load failed and the estimate is safe on $exceptionType',
        (tester) async {
          fakeSupabase.shouldThrowOnSelectPaginated = true;
          fakeSupabase.selectPaginatedExceptionType = exceptionType;

          await pumpLogsList(tester);

          expect(find.text(l10n().errorLoadingLogs), findsOneWidget);
          expect(find.text(l10n().logsLoadErrorReassurance), findsOneWidget);
        },
      );
    }

    testWidgets('tells the contractor when the retried first load also fails', (
      tester,
    ) async {
      fakeSupabase.shouldThrowOnSelectPaginated = true;
      fakeSupabase.selectPaginatedExceptionType = SupabaseExceptionType.timeout;

      await pumpLogsList(tester);
      expect(find.text(l10n().errorLoadingLogsRepeat), findsNothing);

      await tester.tap(find.byKey(CostEstimationLogsList.errorRetryButtonKey));
      await tester.pumpAndSettle();

      expect(find.text(l10n().errorLoadingLogsRepeat), findsOneWidget);
      expect(find.text(l10n().errorLoadingLogs), findsNothing);
      expect(
        find.byKey(CostEstimationLogsList.errorRetryButtonKey),
        findsOneWidget,
      );
    });

    testWidgets('shows a load-more failure under the list, not in a toast', (
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
        find.byKey(CostEstimationLogsList.logsScrollViewKey),
        const Offset(0, -1800),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(CostEstimationLogsList.loadMoreErrorViewKey),
        300,
        scrollable: find.descendant(
          of: find.byKey(CostEstimationLogsList.logsScrollViewKey),
          matching: find.byType(Scrollable),
        ),
      );

      expect(find.text(l10n().loadMoreLogsError), findsOneWidget);
      expect(find.text(l10n().logsLoadErrorReassurance), findsOneWidget);
      expect(
        find.text(l10n().closeLabel),
        findsNothing,
        reason: 'the failure is shown in the list, not in a dismissible toast',
      );
    });

    testWidgets('tells the contractor when the retried load also fails', (
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
        find.byKey(CostEstimationLogsList.logsScrollViewKey),
        const Offset(0, -1800),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(CostEstimationLogsList.loadMoreRetryButtonKey),
        300,
        scrollable: find.descendant(
          of: find.byKey(CostEstimationLogsList.logsScrollViewKey),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(
        find.byKey(CostEstimationLogsList.loadMoreRetryButtonKey),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(CostEstimationLogsList.loadMoreRetryButtonKey),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n().loadMoreLogsErrorRepeat), findsOneWidget);
      expect(find.text(l10n().loadMoreLogsError), findsNothing);
    });
  });

  group('CostEstimationLogsList first-load failure', () {
    testWidgets('shows a try-again view in the body instead of only a toast', (
      tester,
    ) async {
      fakeSupabase.shouldThrowOnSelectPaginated = true;
      fakeSupabase.selectPaginatedExceptionType = SupabaseExceptionType.timeout;

      await pumpLogsList(tester);

      expect(find.byKey(CostEstimationLogsList.errorViewKey), findsOneWidget);
      expect(
        find.byKey(CostEstimationLogsList.errorRetryButtonKey),
        findsOneWidget,
      );
      expect(find.text(l10n().errorLoadingLogs), findsOneWidget);
      expect(
        find.text(l10n().closeLabel),
        findsNothing,
        reason: 'the failure is shown in the body, not in a dismissible toast',
      );
    });

    testWidgets('try again re-fetches and renders the logs on success', (
      tester,
    ) async {
      fakeSupabase.shouldThrowOnSelectPaginated = true;
      fakeSupabase.selectPaginatedExceptionType = SupabaseExceptionType.timeout;

      await pumpLogsList(tester);

      seedLogs([
        LogTestDataFactory.createLogData(
          id: 'log-1',
          estimateId: estimateId,
          activity: 'costEstimationCreated',
          firstName: 'Liam',
        ),
      ]);
      fakeSupabase.shouldThrowOnSelectPaginated = false;

      await tester.tap(find.byKey(CostEstimationLogsList.errorRetryButtonKey));
      await tester.pumpAndSettle();

      expect(find.byKey(CostEstimationLogsList.errorViewKey), findsNothing);
      expect(find.byType(CostEstimationLogTile), findsOneWidget);
    });
  });

  group('CostEstimationLogsList in its bottom sheet', () {
    // Opens the list the way the app does, in a CoreQuickSheet, on a phone-
    // sized screen, and returns that screen's height.
    Future<double> pumpLogsListInSheet(
      WidgetTester tester, {
      bool settle = true,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final bloc = Modular.get<CostEstimationLogBloc>();
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: CoreTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              buildContext = context;
              return const Scaffold();
            },
          ),
        ),
      );
      unawaited(
        CoreQuickSheet.show<void>(
          context: buildContext!,
          child: BlocProvider<CostEstimationLogBloc>.value(
            value: bloc,
            child: const CostEstimationLogsList(
              estimateId: estimateId,
              estimateName: estimateName,
            ),
          ),
        ),
      );
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        // The spinner animates forever, so wait out the sheet's slide-in.
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }
      return tester.view.physicalSize.height / tester.view.devicePixelRatio;
    }

    testWidgets('grows to fit a first-load failure instead of its cap', (
      tester,
    ) async {
      fakeSupabase.shouldThrowOnSelectPaginated = true;
      fakeSupabase.selectPaginatedExceptionType = SupabaseExceptionType.timeout;

      final screenHeight = await pumpLogsListInSheet(tester);

      expect(find.byKey(CostEstimationLogsList.errorViewKey), findsOneWidget);
      expect(
        tester.getSize(find.byType(CostEstimationLogsList)).height,
        lessThan(screenHeight / 2),
        reason: 'the sheet sizes to the message, as in CUJ 11 screen 3',
      );
    });

    testWidgets('grows to fit the empty state instead of its cap', (
      tester,
    ) async {
      final screenHeight = await pumpLogsListInSheet(tester);

      expect(find.text(l10n().noActivityLogs), findsOneWidget);
      expect(
        tester.getSize(find.byType(CostEstimationLogsList)).height,
        lessThan(screenHeight / 2),
        reason: 'the sheet sizes to the message, as in CUJ 11 screen 14',
      );
    });

    testWidgets('grows to fit the first-load spinner instead of its cap', (
      tester,
    ) async {
      final pending = Completer<void>();
      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = pending;
      addTearDown(() => fakeSupabase.shouldDelayOperations = false);

      final screenHeight = await pumpLogsListInSheet(tester, settle: false);
      final loadingLabels = find.text(l10n().loadingLogs).evaluate().length;
      final sheetHeight = tester
          .getSize(find.byType(CostEstimationLogsList))
          .height;

      // Land the held load before asserting, so its 15s timeout timer is
      // cancelled whether or not the expectations below pass.
      pending.complete();
      await tester.pumpAndSettle();

      expect(loadingLabels, 1, reason: 'measured while the first page loads');
      expect(
        sheetHeight,
        lessThan(screenHeight / 2),
        reason: 'the sheet sizes to the spinner, as in CUJ 11 screen 2',
      );
    });
  });

  group('CostEstimationLogsList loading labels', () {
    testWidgets('says Logs are loading while the first page is on its way', (
      tester,
    ) async {
      final pending = Completer<void>();
      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = pending;
      addTearDown(() => fakeSupabase.shouldDelayOperations = false);

      final bloc = Modular.get<CostEstimationLogBloc>();
      addTearDown(bloc.close);
      // Tear-downs run last-first: release the held load before the bloc
      // closes, or a failed expectation leaves close() waiting on it forever.
      addTearDown(() => pending.isCompleted ? null : pending.complete());
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(buildTestApp(bloc));
      await tester.pump();

      expect(find.text(l10n().loadingLogs), findsOneWidget);
      expect(
        find.bySemanticsLabel('Loading'),
        findsNothing,
        reason: 'the spinner must not be announced on top of its label',
      );
      semantics.dispose();

      pending.complete();
      await tester.pumpAndSettle();

      expect(find.text(l10n().loadingLogs), findsNothing);
    });

    testWidgets('says older events are loading while the next page loads', (
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

      final pending = Completer<void>();
      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = pending;
      addTearDown(() => fakeSupabase.shouldDelayOperations = false);
      addTearDown(() => pending.isCompleted ? null : pending.complete());

      await tester.drag(
        find.byKey(CostEstimationLogsList.logsScrollViewKey),
        const Offset(0, -1800),
      );
      final semantics = tester.ensureSemantics();
      await tester.pump();

      expect(find.text(l10n().loadingOlderLogEvents), findsOneWidget);
      expect(
        find.bySemanticsLabel('Loading'),
        findsNothing,
        reason: 'the spinner must not be announced on top of its label',
      );
      semantics.dispose();

      pending.complete();
      await tester.pumpAndSettle();

      expect(find.text(l10n().loadingOlderLogEvents), findsNothing);
    });
  });

  group('CostEstimationLogsList end-of-list marker', () {
    testWidgets('shows no-older-events once the whole list is loaded', (
      tester,
    ) async {
      seedLogs([
        LogTestDataFactory.createLogData(
          id: 'log-1',
          estimateId: estimateId,
          activity: 'costEstimationCreated',
          firstName: 'Liam',
        ),
      ]);

      await pumpLogsList(tester);

      expect(
        find.byKey(CostEstimationLogsList.endOfListMarkerKey),
        findsOneWidget,
      );
      expect(find.text(l10n().noOlderLogEvents), findsOneWidget);
    });

    testWidgets('hides the marker while older pages remain', (tester) async {
      final pageSize = CostEstimationLogRepositoryImpl.defaultPageSize;
      seedLogs(
        LogTestDataFactory.createLogDataList(
          count: pageSize + 1,
          estimateId: estimateId,
        ),
      );

      await pumpLogsList(tester);

      expect(
        find.byKey(CostEstimationLogsList.endOfListMarkerKey),
        findsNothing,
      );
    });

    testWidgets('shows the marker after the final page is paginated in', (
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

      await tester.drag(
        find.byKey(CostEstimationLogsList.logsScrollViewKey),
        const Offset(0, -1800),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(CostEstimationLogsList.endOfListMarkerKey),
        300,
        scrollable: find.descendant(
          of: find.byKey(CostEstimationLogsList.logsScrollViewKey),
          matching: find.byType(Scrollable),
        ),
      );

      expect(
        find.byKey(CostEstimationLogsList.endOfListMarkerKey),
        findsOneWidget,
      );
    });
  });
}

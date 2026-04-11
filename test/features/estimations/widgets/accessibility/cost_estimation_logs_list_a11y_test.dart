import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/repositories/cost_estimation_log_repository_impl.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_log_bloc/cost_estimation_log_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_logs_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';

import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';
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

  void seedLogs(List<Map<String, dynamic>> rows) {
    fakeSupabase.addTableData(DatabaseConstants.costEstimationLogsTable, rows);
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> pumpWidget(
    WidgetTester tester, {
    ThemeData? theme,
    bool shouldTriggerError = false,
  }) async {
    final bloc = Modular.get<CostEstimationLogBloc>();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
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
      ),
    );
    await tester.pumpAndSettle();

    if (shouldTriggerError) {
      fakeSupabase.shouldThrowOnSelectPaginated = true;
      fakeSupabase.selectPaginatedExceptionType = SupabaseExceptionType.timeout;

      bloc.add(const CostEstimationLogLoadMore(estimateId: estimateId));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -2200),
      );
      await tester.pumpAndSettle();
    }
  }

  group('CostEstimationLogsList accessibility', () {
    testWidgets('a11y: empty state text remains readable in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      for (final theme in [createTestTheme(), createTestThemeDark()]) {
        await pumpWidget(tester, theme: theme);

        await expectMeetsTapTargetAndLabelGuidelines(
          tester,
          find.text(l10n().noActivityLogs),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      }
    });

    testWidgets(
      'a11y: retry button meets tap and label guidelines in light theme',
      (tester) async {
        final pageSize = CostEstimationLogRepositoryImpl.defaultPageSize;
        seedLogs(
          LogTestDataFactory.createLogDataList(
            count: pageSize + 1,
            estimateId: estimateId,
          ),
        );

        await setupA11yTest(tester);
        await pumpWidget(
          tester,
          theme: createTestTheme(),
          shouldTriggerError: true,
        );

        await expectMeetsTapTargetAndLabelGuidelines(
          tester,
          find.text(l10n().retryLoadLogsButton),
        );
      },
    );

    testWidgets(
      'a11y: retry button meets tap and label guidelines in dark theme',
      (tester) async {
        final pageSize = CostEstimationLogRepositoryImpl.defaultPageSize;
        seedLogs(
          LogTestDataFactory.createLogDataList(
            count: pageSize + 1,
            estimateId: estimateId,
          ),
        );

        await setupA11yTest(tester);
        await pumpWidget(
          tester,
          theme: createTestThemeDark(),
          shouldTriggerError: true,
        );

        await expectMeetsTapTargetAndLabelGuidelines(
          tester,
          find.text(l10n().retryLoadLogsButton),
        );
      },
    );
  });
}

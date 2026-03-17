import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/rename_estimation_bloc/rename_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/estimation_rename_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../helpers/estimation_test_data_map_factory.dart';
import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

class _EstimationRenameSheetTestModule extends Module {
  final AppBootstrap appBootstrap;

  _EstimationRenameSheetTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    ClockTestModule(),
    EstimationModule(appBootstrap),
  ];
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late Clock clock;
  late AppBootstrap appBootstrap;
  late FakeAppRouter fakeAppRouter;

  const testEstimationId = 'estimation-123';
  const testProjectId = 'project-123';
  const testCurrentName = 'Kitchen Remodel';

  BuildContext? buildContext;

  setUpAll(() {
    clock = FakeClockImpl();
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    CoreToast.disableTimers();

    appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(_EstimationRenameSheetTestModule(appBootstrap));
    fakeAppRouter = Modular.get<AppRouter>() as FakeAppRouter;
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeSupabase.reset();
    fakeAppRouter.reset();

    fakeSupabase.addTableData('cost_estimates', [
      EstimationTestDataMapFactory.createFakeEstimationData(
        id: testEstimationId,
        projectId: testProjectId,
        estimateName: testCurrentName,
      ),
    ]);
  });

  Widget createWidget({
    String estimationId = testEstimationId,
    String projectId = testProjectId,
    String initialName = testCurrentName,
    ThemeData? theme,
  }) {
    theme ??= createTestTheme();
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          buildContext = context;
          return Scaffold(
            body: BlocProvider<RenameEstimationBloc>(
              create: (_) => Modular.get<RenameEstimationBloc>(),
              child: EstimationRenameSheet(
                estimationId: estimationId,
                projectId: projectId,
                currentName: initialName,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> renderSheet(WidgetTester tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  group('EstimationRenameSheet accessibility', () {
    testWidgets('meets a11y guidelines for save button in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await renderSheet(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(theme: theme),
        find.text(l10n().saveCostNameButton),
      );
    });

    testWidgets('meets a11y guidelines for text field label in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await renderSheet(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(theme: theme),
        find.text(l10n().estimationNameLabel),
      );
    });

    testWidgets('meets a11y guidelines for title in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await renderSheet(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(theme: theme),
        find.text(l10n().addCostName),
      );
    });

    testWidgets('meets a11y guidelines when save button is disabled', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await renderSheet(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(theme: theme),
        find.text(l10n().saveCostNameButton),
      );
    });
  });
}

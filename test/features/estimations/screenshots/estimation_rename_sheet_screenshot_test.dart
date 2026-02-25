import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/rename_estimation_bloc/rename_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/estimation_rename_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/screenshot/font_loader.dart';

class FakeAppRouter extends Fake implements AppRouter {
  @override
  void pop() {}
}

void main() {
  final size = const Size(390, 300);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFonts();
    Modular.init(
      EstimationModule(
        AppBootstrap(
          config: FakeAppConfig(),
          envLoader: FakeEnvLoader(),
          supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
        ),
      ),
    );
  });

  tearDownAll(() {
    Modular.destroy();
  });

  group('EstimationRenameSheet Screenshot Tests', () {
    Future<void> pumpRenameSheet({
      required WidgetTester tester,
      required String estimationId,
      required String projectId,
      RenameEstimationState? state,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<RenameEstimationBloc>.value(
              value: Modular.get<RenameEstimationBloc>(),
              child: EstimationRenameSheet(
                estimationId: estimationId,
                projectId: projectId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'displays rename sheet with empty text field and disabled save button',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;

        await pumpRenameSheet(
          tester: tester,
          estimationId: 'test-estimation-123',
          projectId: 'test-project-123',
        );

        await expectLater(
          find.byType(EstimationRenameSheet),
          matchesGoldenFile(
            'goldens/estimation_rename_sheet/${size.width}x${size.height}/estimation_rename_sheet_default.png',
          ),
        );
      },
    );

    testWidgets(
      'displays rename sheet with estimation name text filled in and enabled save button',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;

        await pumpRenameSheet(
          tester: tester,
          estimationId: 'test-estimation-123',
          projectId: 'test-project-123',
        );

        await tester.enterText(
          find.byType(CoreTextField),
          'New Estimation Name',
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(EstimationRenameSheet),
          matchesGoldenFile(
            'goldens/estimation_rename_sheet/${size.width}x${size.height}/estimation_rename_sheet_name_filled.png',
          ),
        );
      },
    );
  });
}

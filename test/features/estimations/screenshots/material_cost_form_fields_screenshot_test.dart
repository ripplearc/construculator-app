import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_cost_form_fields.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390.0, 600.0);
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() async {
    fakeSupabase.reset();
    await loadAppFontsAll();
  });

  Future<void> pumpWidget({
    required WidgetTester tester,
    required ThemeData theme,
    bool fromCostFile = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<MaterialCostFormBloc>(
            create: (_) => Modular.get<MaterialCostFormBloc>(),
            child: MaterialCostFormFields(fromCostFile: fromCostFile),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('MaterialCostFormFields Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders manually mode with item type error', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await tester.enterText(
        find.byKey(const Key('material_type_field')),
        'x',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('material_type_field')),
        '',
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialCostFormFields),
        matchesGoldenFile(
          'goldens/material_cost_form_fields/${size.width}x${size.height}/manually_error$suffix.png',
        ),
      );
    });
  });

  // These two scenarios only ever had a light golden; screenshotThemeGroups
  // always produces both light and dark, so they stay outside it rather than
  // gaining new dark goldens as a side effect of this migration.
  group('MaterialCostFormFields Screenshot Tests - Light Only', () {
    testWidgets('renders manually mode in light theme', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: createTestTheme());
      await expectLater(
        find.byType(MaterialCostFormFields),
        matchesGoldenFile(
          'goldens/material_cost_form_fields/${size.width}x${size.height}/manually_light.png',
        ),
      );
    });

    testWidgets('renders from cost file mode in light theme', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, fromCostFile: true, theme: createTestTheme());
      await expectLater(
        find.byType(MaterialCostFormFields),
        matchesGoldenFile(
          'goldens/material_cost_form_fields/${size.width}x${size.height}/from_cost_file_light.png',
        ),
      );
    });
  });
}

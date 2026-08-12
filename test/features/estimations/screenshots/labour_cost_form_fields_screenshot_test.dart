import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/labour_cost_form_bloc/labour_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/labour_cost_form_fields.dart';
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
          body: BlocProvider<LabourCostFormBloc>(
            create: (_) => Modular.get<LabourCostFormBloc>(),
            child: LabourCostFormFields(fromCostFile: fromCostFile),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('LabourCostFormFields Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders manually mode', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await expectLater(
        find.byType(LabourCostFormFields),
        matchesGoldenFile(
          'goldens/labour_cost_form_fields/${size.width}x${size.height}/manually$suffix.png',
        ),
      );
    });

    testWidgets('renders from cost file mode', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, fromCostFile: true, theme: theme);
      await expectLater(
        find.byType(LabourCostFormFields),
        matchesGoldenFile(
          'goldens/labour_cost_form_fields/${size.width}x${size.height}/from_cost_file$suffix.png',
        ),
      );
    });

    testWidgets('renders manually mode with item type error', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await tester.enterText(find.byKey(const Key('labour_type_field')), 'x');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('labour_type_field')), '');
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(LabourCostFormFields),
        matchesGoldenFile(
          'goldens/labour_cost_form_fields/${size.width}x${size.height}/manually_error$suffix.png',
        ),
      );
    });
  });
}

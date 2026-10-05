import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(412, 917);
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

  Future<void> openSheet(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_sheet'),
                onPressed: () => CoreQuickSheet.show(
                  context: context,
                  child: BlocProvider<EquipmentCostFormBloc>(
                    create: (_) => Modular.get<EquipmentCostFormBloc>(),
                    child: CostItemFormScreen(
                      type: CostItemType.equipment,
                      estimationId: 'test-estimation-id',
                      router: FakeAppRouter(),
                      yourRatesBlocFactory: () => Modular.get<YourRatesBloc>(),
                      clock: FakeClockImpl(),
                      presentAsSheet: true,
                      estimate: CostEstimate.defaultEstimate(
                        estimateName: 'Bedroom 2',
                        totalCost: 2993.62,
                      ),
                    ),
                  ),
                ),
                child: const Text('Add equipment cost'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pumpAndSettle();
  }

  Future<void> expectSheetGolden(
    WidgetTester tester,
    String name,
    String suffix,
  ) async {
    // A focused field draws a blinking caret that changes between runs.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        'goldens/equipment_add_to_estimate_sheet/$name$suffix.png',
      ),
    );
  }

  screenshotThemeGroups('Equipment sheet Add to estimate Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('name missing', (tester) async {
      await openSheet(tester, theme);
      await expectSheetGolden(tester, 'name_missing', suffix);
    });

    testWidgets('duration missing', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'equipment_name_field', 'Scissor lift');
      await expectSheetGolden(tester, 'duration_missing', suffix);
    });

    testWidgets('duration is zero', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'equipment_name_field', 'Scissor lift');
      await enter(tester, 'duration_field', '0');
      await expectSheetGolden(tester, 'duration_zero', suffix);
    });

    testWidgets('rate missing', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'equipment_name_field', 'Scissor lift');
      await enter(tester, 'duration_field', '4');
      await expectSheetGolden(tester, 'rate_missing', suffix);
    });

    testWidgets('day ready', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'equipment_name_field', 'Scissor lift');
      await enter(tester, 'duration_field', '4');
      await enter(tester, 'rate_field', '145');
      await expectSheetGolden(tester, 'day_ready', suffix);
    });

    testWidgets('day ready with delivery fee', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'equipment_name_field', 'Scissor lift');
      await enter(tester, 'duration_field', '4');
      await enter(tester, 'rate_field', '145');
      await tester.tap(find.byKey(const Key('delivery_fee_row')));
      await tester.pumpAndSettle();
      await enter(tester, 'delivery_fee_field', '85');
      await expectSheetGolden(tester, 'day_ready_delivery', suffix);
    });

    testWidgets('job amount missing', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'equipment_name_field', 'Mini excavator');
      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pumpAndSettle();
      await expectSheetGolden(tester, 'job_amount_missing', suffix);
    });

    testWidgets('job ready', (tester) async {
      await openSheet(tester, theme);
      await enter(tester, 'equipment_name_field', 'Mini excavator');
      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pumpAndSettle();
      await enter(tester, 'amount_field', '520');
      await expectSheetGolden(tester, 'job_ready', suffix);
    });
  });
}

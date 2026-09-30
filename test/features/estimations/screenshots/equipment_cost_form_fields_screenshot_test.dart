import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/equipment_cost_form_fields.dart';
import 'package:construculator/features/estimation/presentation/widgets/rate_status_badge.dart';
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
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<EquipmentCostFormBloc>(
            create: (_) => Modular.get<EquipmentCostFormBloc>(),
            child: EquipmentCostFormFields(
              fromCostFile: fromCostFile,
              yourRatesBlocFactory: () => Modular.get<YourRatesBloc>(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('EquipmentCostFormFields Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders manually mode with Day selected by default', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await expectLater(
        find.byType(EquipmentCostFormFields),
        matchesGoldenFile(
          'goldens/equipment_cost_form_fields/${size.width}x${size.height}/manually_day$suffix.png',
        ),
      );
    });

    testWidgets('renders manually mode with Job selected', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await tester.tap(find.byKey(const Key('job_method_chip')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(EquipmentCostFormFields),
        matchesGoldenFile(
          'goldens/equipment_cost_form_fields/${size.width}x${size.height}/manually_job$suffix.png',
        ),
      );
    });

    testWidgets('renders the days suffix right next to a typed duration', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await tester.enterText(find.byKey(const Key('duration_field')), '4');
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(EquipmentCostFormFields),
        matchesGoldenFile(
          'goldens/equipment_cost_form_fields/${size.width}x${size.height}/manually_duration_typed$suffix.png',
        ),
      );
    });

    testWidgets('renders a very long duration without overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await tester.enterText(
        find.byKey(const Key('duration_field')),
        '1234567890' * 3,
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(EquipmentCostFormFields),
        matchesGoldenFile(
          'goldens/equipment_cost_form_fields/${size.width}x${size.height}/manually_duration_long$suffix.png',
        ),
      );
    });

    Future<void> expectFieldsGolden(
      WidgetTester tester,
      String name,
      suffix,
    ) => expectLater(
      find.byType(EquipmentCostFormFields),
      matchesGoldenFile(
        'goldens/equipment_cost_form_fields/${size.width}x${size.height}/$name$suffix.png',
      ),
    );

    testWidgets('renders the Delivery panel open with a fee typed', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await tester.tap(find.byKey(const Key('delivery_fee_row')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('delivery_fee_field')), '85');
      await tester.pumpAndSettle();
      await expectFieldsGolden(tester, 'delivery_open_fee', suffix);
    });

    testWidgets('renders the Delivery panel with the Note field filled', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await tester.tap(find.byKey(const Key('delivery_fee_row')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('delivery_fee_field')), '85');
      await tester.enterText(
        find.byKey(const Key('delivery_note_field')),
        'Crane truck, call on arrival',
      );
      await tester.pumpAndSettle();
      await expectFieldsGolden(tester, 'delivery_open_note', suffix);
    });

    testWidgets('renders the Delivery row folded with a fee', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await tester.tap(find.byKey(const Key('delivery_fee_row')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('delivery_fee_field')), '85');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('equipment_name_field')));
      await tester.pumpAndSettle();
      await expectFieldsGolden(tester, 'delivery_folded_fee', suffix);
    });

    testWidgets('renders the big-fee question for an outsized delivery fee', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await tester.enterText(
        find.byKey(const Key('equipment_name_field')),
        'Mini excavator',
      );
      await tester.enterText(find.byKey(const Key('duration_field')), '4');
      await tester.enterText(find.byKey(const Key('rate_field')), '145');
      await tester.tap(find.byKey(const Key('delivery_fee_row')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('delivery_fee_field')),
        '8500',
      );
      await tester.pumpAndSettle();
      BlocProvider.of<EquipmentCostFormBloc>(
        tester.element(find.byType(EquipmentCostFormFields)),
      ).add(const EquipmentCostSubmittedEvent(estimateId: 'estimate-1'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/equipment_cost_form_fields/390.0x800.0/outsized_fee_dialog$suffix.png',
        ),
      );
    });

    testWidgets('renders both rate status badge colours', (tester) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      tester.view.physicalSize = const Size(390, 120);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  RateStatusBadge(
                    label: l10n.equipmentRateStatusSampleRateBadge,
                    variant: RateStatusBadgeVariant.orange,
                  ),
                  const SizedBox(width: 12),
                  RateStatusBadge(
                    label: l10n.equipmentRateStatusYourRateBadge,
                    variant: RateStatusBadgeVariant.green,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Row).first,
        matchesGoldenFile(
          'goldens/rate_status_badge/rate_status_badges$suffix.png',
        ),
      );
    });

    testWidgets('renders manually mode with duration error', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await tester.enterText(find.byKey(const Key('duration_field')), '0');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(EquipmentCostFormFields),
        matchesGoldenFile(
          'goldens/equipment_cost_form_fields/${size.width}x${size.height}/manually_duration_error$suffix.png',
        ),
      );
    });

    testWidgets('renders from cost file mode', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, fromCostFile: true, theme: theme);
      await expectLater(
        find.byType(EquipmentCostFormFields),
        matchesGoldenFile(
          'goldens/equipment_cost_form_fields/${size.width}x${size.height}/from_cost_file$suffix.png',
        ),
      );
    });

    testWidgets(
      'renders the Save as my default link and helper text once a rate is '
      'typed (Figma node 66342:178091, cuj6-equip-5-verify)',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await pumpWidget(tester: tester, theme: theme);
        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          'Mini excavator',
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('rate_field')), '145');
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(EquipmentCostFormFields),
          matchesGoldenFile(
            'goldens/equipment_cost_form_fields/${size.width}x${size.height}/manually_save_as_my_rate$suffix.png',
          ),
        );
      },
    );

    testWidgets(
      'renders manually mode with no red error after clearing item type '
      '(empty fields never show a red error, per product decision)',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await pumpWidget(tester: tester, theme: theme);
        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          'x',
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('equipment_name_field')),
          '',
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(EquipmentCostFormFields),
          matchesGoldenFile(
            'goldens/equipment_cost_form_fields/${size.width}x${size.height}/manually_name_cleared$suffix.png',
          ),
        );
      },
    );
  });
}

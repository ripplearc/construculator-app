import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_lookup_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
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
  const size = Size(390, 500);
  const ratio = 1.0;
  const table = 'your_rates';
  late FakeSupabaseWrapper fakeSupabase;
  late List<Map<String, dynamic>> seededRows;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFontsAll();
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
  });

  tearDownAll(() {
    Modular.destroy();
  });

  setUp(() {
    fakeSupabase.reset();
    seededRows = [];
  });

  void seedRate({
    required String itemName,
    required double amount,
    String method = 'job',
  }) {
    seededRows = [
      ...seededRows,
      {
        'id': 'rate-${seededRows.length + 1}',
        'company_id': 'company-1',
        'category': 'equipment',
        'item_name': itemName,
        'rate_amount': amount,
        'rate_currency': 'USD',
        'equipment_method': method,
        'saved_at': DateTime(2026, 1, 1).toIso8601String(),
      },
    ];
    fakeSupabase.addTableData(table, seededRows);
  }

  Future<void> pumpSheet({
    required WidgetTester tester,
    required ThemeData theme,
    EquipmentPricingMethod method = EquipmentPricingMethod.job,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<YourRatesBloc>(
            create: (_) => Modular.get<YourRatesBloc>(),
            child: YourRatesLookupSheet(
              method: method,
              onSwitchMethod: (_) {},
              clock: FakeClockImpl(DateTime(2026, 1, 15)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> searchFor(WidgetTester tester, String query) async {
    await tester.enterText(find.byKey(CoreSearchBox.textFieldKey), query);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('YourRatesLookupSheet Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('displays the empty state when nothing is saved yet', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpSheet(tester: tester, theme: theme);

      await expectLater(
        find.byType(YourRatesLookupSheet),
        matchesGoldenFile(
          'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/empty$suffix.png',
        ),
      );
    });

    testWidgets('displays result rows', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      seedRate(itemName: 'Mini excavator — 1.5 ton', amount: 520);
      seedRate(itemName: 'Excavator + operator — half day', amount: 340);

      await pumpSheet(tester: tester, theme: theme);

      await expectLater(
        find.byType(YourRatesLookupSheet),
        matchesGoldenFile(
          'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/results$suffix.png',
        ),
      );
    });

    testWidgets('shows the no-match line and no Use button', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      seedRate(itemName: 'Mini excavator — 1.5 ton', amount: 520);

      await pumpSheet(tester: tester, theme: theme);
      await tester.tap(find.text('Mini excavator — 1.5 ton'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(CoreSearchBox.textFieldKey),
        'stump grinder',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(YourRatesLookupSheet),
        matchesGoldenFile(
          'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/no_match$suffix.png',
        ),
      );
    });

    testWidgets('shows the error row when the saved prices cannot be read', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      fakeSupabase.shouldThrowOnSelectMatch = true;

      await pumpSheet(tester: tester, theme: theme);

      await expectLater(
        find.byType(YourRatesLookupSheet),
        matchesGoldenFile(
          'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/error$suffix.png',
        ),
      );
    });

    testWidgets('shows the loading indicator while the rates are read', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      fakeSupabase.completer = Completer<void>();
      addTearDown(() => fakeSupabase.completer?.complete());

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<YourRatesBloc>(
              create: (_) => Modular.get<YourRatesBloc>(),
              child: YourRatesLookupSheet(
                method: EquipmentPricingMethod.job,
                onSwitchMethod: (_) {},
                clock: FakeClockImpl(DateTime(2026, 1, 15)),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(YourRatesLookupSheet),
        matchesGoldenFile(
          'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/loading$suffix.png',
        ),
      );
    });

    testWidgets(
      'shows the check, highlight, and confirm button once a row is selected',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);

        seedRate(itemName: 'Mini excavator — 1.5 ton', amount: 520);

        await pumpSheet(tester: tester, theme: theme);
        await tester.tap(find.text('Mini excavator — 1.5 ton'));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(YourRatesLookupSheet),
          matchesGoldenFile(
            'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/selected$suffix.png',
          ),
        );
      },
    );

    testWidgets(
      'shows the other-method message for one job price while Day is active (Figma X3b)',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);

        seedRate(itemName: 'Excavator + operator — half day', amount: 340);

        await pumpSheet(
          tester: tester,
          theme: theme,
          method: EquipmentPricingMethod.day,
        );
        await searchFor(tester, 'excavator half day');

        await expectLater(
          find.byType(YourRatesLookupSheet),
          matchesGoldenFile(
            'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/other_method_job_price$suffix.png',
          ),
        );
      },
    );

    testWidgets(
      'shows the count and range when several job prices match while Day is active',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);

        seedRate(itemName: 'Excavator + operator — half day', amount: 340);
        seedRate(itemName: 'Excavator + operator — full day', amount: 520);
        seedRate(itemName: 'Excavator + operator — 3 hours', amount: 400);

        await pumpSheet(
          tester: tester,
          theme: theme,
          method: EquipmentPricingMethod.day,
        );
        await searchFor(tester, 'excavator');

        await expectLater(
          find.byType(YourRatesLookupSheet),
          matchesGoldenFile(
            'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/other_method_job_prices_range$suffix.png',
          ),
        );
      },
    );

    testWidgets(
      'shows the other-method message for one day rate while Job is active',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);

        seedRate(
          itemName: 'Excavator + operator — half day',
          amount: 120,
          method: 'day',
        );

        await pumpSheet(tester: tester, theme: theme);
        await searchFor(tester, 'excavator half day');

        await expectLater(
          find.byType(YourRatesLookupSheet),
          matchesGoldenFile(
            'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/other_method_day_rate$suffix.png',
          ),
        );
      },
    );

    testWidgets(
      'shows the count and range when several day rates match while Job is active',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);

        seedRate(itemName: 'Excavator — half day', amount: 120, method: 'day');
        seedRate(itemName: 'Excavator — full day', amount: 180, method: 'day');

        await pumpSheet(tester: tester, theme: theme);
        await searchFor(tester, 'excavator');

        await expectLater(
          find.byType(YourRatesLookupSheet),
          matchesGoldenFile(
            'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/other_method_day_rates_range$suffix.png',
          ),
        );
      },
    );

    testWidgets(
      'lists the lone job price selected with its Use button after Show job prices (Figma X6b)',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);

        seedRate(itemName: 'Excavator + operator — half day', amount: 340);

        await pumpSheet(
          tester: tester,
          theme: theme,
          method: EquipmentPricingMethod.day,
        );
        await searchFor(tester, 'excavator half day');
        await tester.tap(
          find.byKey(const Key('your_rates_other_method_action')),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(YourRatesLookupSheet),
          matchesGoldenFile(
            'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/other_method_switched_lone_match$suffix.png',
          ),
        );
      },
    );

    testWidgets(
      'lists several job prices with none selected after Show job prices',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);

        seedRate(itemName: 'Excavator + operator — half day', amount: 340);
        seedRate(itemName: 'Excavator + operator — full day', amount: 520);

        await pumpSheet(
          tester: tester,
          theme: theme,
          method: EquipmentPricingMethod.day,
        );
        await searchFor(tester, 'excavator');
        await tester.tap(
          find.byKey(const Key('your_rates_other_method_action')),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(YourRatesLookupSheet),
          matchesGoldenFile(
            'goldens/your_rates_lookup_sheet/${size.width}x${size.height}/other_method_switched_several$suffix.png',
          ),
        );
      },
    );
  });
}

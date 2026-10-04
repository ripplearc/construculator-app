import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_lookup_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late AppLocalizations l10n;

  setUpAll(() {
    final clock = FakeClockImpl(DateTime(2026, 1, 15));
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() {
    fakeSupabase.addTableData('your_rates', [
      for (var i = 0; i < 4; i++)
        {
          'id': 'rate-$i',
          'company_id': 'company-1',
          'category': 'equipment',
          'item_name': 'Excavator $i',
          'rate_amount': 100 + i,
          'rate_currency': 'USD',
          'equipment_method': 'day',
          'saved_at': DateTime(2026, 1, 15 - i).toIso8601String(),
        },
    ]);
  });

  tearDown(() {
    fakeSupabase.reset();
  });

  Future<void> openSheet(
    WidgetTester tester,
    List<YourRateEntry?> results,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_sheet'),
                onPressed: () async {
                  results.add(
                    await YourRatesLookupSheet.show(
                      context: context,
                      method: EquipmentPricingMethod.day,
                      blocFactory: () => Modular.get<YourRatesBloc>(),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();
  }

  group('YourRatesLookupSheet – header', () {
    testWidgets('shows a back arrow next to the Look up a rate title', (
      tester,
    ) async {
      await openSheet(tester, []);

      expect(find.byKey(SheetHeader.backButtonKey), findsOneWidget);
      expect(find.text(l10n.yourRatesLookupTitle), findsOneWidget);
    });

    testWidgets('keeps the search field above the keyboard', (tester) async {
      fakeSupabase.reset();
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      addTearDown(tester.view.resetViewInsets);
      await openSheet(tester, []);

      final keyboardTop =
          (tester.view.physicalSize.height - 900) /
          tester.view.devicePixelRatio;
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byKey(const Key('your_rates_search_field'))).bottom,
        lessThanOrEqualTo(keyboardTop),
      );
    });

    testWidgets('scrolls the results when the sheet is too short for them', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 1200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await openSheet(tester, []);

      await tester.dragUntilVisible(
        find.byKey(const Key('your_rate_row_rate-3')),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('your_rate_row_rate-3')), findsOneWidget);
    });

    testWidgets('tapping the back arrow closes the sheet without a pick', (
      tester,
    ) async {
      final results = <YourRateEntry?>[];
      await openSheet(tester, results);

      await tester.tap(find.byKey(SheetHeader.backButtonKey));
      await tester.pumpAndSettle();

      expect(find.byType(YourRatesLookupSheet), findsNothing);
      expect(results, [null]);
    });
  });
}

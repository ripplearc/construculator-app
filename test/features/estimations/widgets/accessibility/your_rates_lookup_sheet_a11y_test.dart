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

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeClockImpl clock;

  setUpAll(() {
    clock = FakeClockImpl(DateTime(2026, 1, 15));
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    Modular.init(
      EstimationModule(
        FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase),
      ),
    );
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() {
    fakeSupabase.addTableData('your_rates', [
      {
        'id': 'rate-1',
        'company_id': 'company-1',
        'category': 'equipment',
        'item_name': 'Dumpster — 30 yd',
        'rate_amount': 400,
        'rate_currency': 'USD',
        'equipment_method': 'job',
        'saved_at': DateTime(2025, 12, 1).toIso8601String(),
        'last_used_at': DateTime(2026, 1, 8).toIso8601String(),
      },
    ]);
  });

  tearDown(() {
    fakeSupabase.reset();
  });

  Widget makeWidget(
    ThemeData theme, {
    EquipmentPricingMethod method = EquipmentPricingMethod.job,
  }) {
    return MaterialApp(
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
            clock: clock,
          ),
        ),
      ),
    );
  }

  group('YourRatesLookupSheet – accessibility', () {
    testWidgets('a11y: a saved rate row meets tap target and label '
        'guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeWidget,
        find.byKey(const Key('your_rate_row_rate-1')),
      );
    });

    testWidgets('a11y: the other-method action meets tap target and label '
        'guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeWidget(theme, method: EquipmentPricingMethod.day),
        find.byKey(const Key('your_rates_other_method_action')),
        setupAfterPump: (tester) async {
          await tester.enterText(
            find.byKey(CoreSearchBox.textFieldKey),
            'dumpster',
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pumpAndSettle();
        },
      );
    });
  });
}

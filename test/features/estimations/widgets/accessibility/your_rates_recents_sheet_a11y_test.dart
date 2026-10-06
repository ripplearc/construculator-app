import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_recents_sheet.dart';
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
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(EstimationModule(bootstrap));
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
        'item_name': 'Scissor lift — 19ft',
        'rate_amount': 120,
        'rate_currency': 'USD',
        'equipment_method': 'day',
        'saved_at': clock
            .now()
            .subtract(const Duration(days: 10))
            .toIso8601String(),
      },
    ]);
  });

  tearDown(() {
    fakeSupabase.reset();
  });

  Widget makeWidget(ThemeData theme) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<YourRatesBloc>(
          create: (_) => Modular.get<YourRatesBloc>(),
          child: YourRatesRecentsSheet(clock: clock),
        ),
      ),
    );
  }

  group('YourRatesRecentsSheet – accessibility', () {
    testWidgets(
      'a11y: a recent row meets tap target and label guidelines in both '
      'themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('your_rate_row_rate-1')),
        );
      },
    );

    testWidgets(
      'a11y: "New equipment cost" meets tap target and label guidelines in '
      'both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('new_equipment_cost_row')),
        );
      },
    );

    testWidgets(
      'a11y: "Try again" on the failed-read message meets tap target and label '
      'guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        fakeSupabase.shouldThrowOnSelectMatch = true;

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          makeWidget,
          find.byKey(const Key('your_rates_recents_try_again_button')),
        );
      },
    );

    testWidgets('a11y: the failed-read message is a live region so a screen '
        'reader reads it when the sheet opens', (tester) async {
      await setupA11yTest(tester);
      fakeSupabase.shouldThrowOnSelectMatch = true;
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(makeWidget(CoreTheme.light()));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Couldn’t open your saved prices.')),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });
  });
}

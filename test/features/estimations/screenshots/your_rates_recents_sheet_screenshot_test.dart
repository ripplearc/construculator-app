import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
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

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 500);
  const ratio = 1.0;
  const table = 'your_rates';
  late FakeSupabaseWrapper fakeSupabase;
  late FakeClockImpl clock;
  late List<Map<String, dynamic>> seededRows;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFontsAll();
    clock = FakeClockImpl(DateTime(2026, 1, 15));
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
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

  // Seeds a `your_rates` row directly on the fake backend — same approach as
  // `your_rates_lookup_sheet_screenshot_test.dart` — so each row's `saved_at`
  // can be set to an exact, deterministic offset from [clock]'s "now" for the
  // recency subtitle, rather than depending on wall-clock time.
  void seedRate({
    required String itemName,
    required double amount,
    required EquipmentPricingMethod method,
    required DateTime savedAt,
    DateTime? lastUsedAt,
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
        'equipment_method': method.name,
        'saved_at': savedAt.toIso8601String(),
        'last_used_at': lastUsedAt?.toIso8601String(),
      },
    ];
    fakeSupabase.addTableData(table, seededRows);
  }

  Future<void> pumpSheet({
    required WidgetTester tester,
    required ThemeData theme,
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
            child: YourRatesRecentsSheet(clock: clock),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('YourRatesRecentsSheet Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('displays only "+ New equipment cost" when nothing is saved', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpSheet(tester: tester, theme: theme);

      await expectLater(
        find.byType(YourRatesRecentsSheet),
        matchesGoldenFile(
          'goldens/your_rates_recents_sheet/${size.width}x${size.height}/empty$suffix.png',
        ),
      );
    });

    testWidgets(
      'displays day- and job-priced rows together, no heading or color split',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);

        seedRate(
          itemName: 'Scissor lift — 19ft',
          amount: 120,
          method: EquipmentPricingMethod.day,
          savedAt: clock.now().subtract(const Duration(days: 60)),
          lastUsedAt: clock.now().subtract(const Duration(days: 10)),
        );
        seedRate(
          itemName: 'Dumpster — 30 yd',
          amount: 400,
          method: EquipmentPricingMethod.job,
          savedAt: clock.now().subtract(const Duration(days: 60)),
          lastUsedAt: clock.now().subtract(const Duration(days: 20)),
        );

        await pumpSheet(tester: tester, theme: theme);

        expect(find.text('Used last week'), findsOneWidget);
        expect(find.text('Used 2 weeks ago'), findsOneWidget);

        await expectLater(
          find.byType(YourRatesRecentsSheet),
          matchesGoldenFile(
            'goldens/your_rates_recents_sheet/${size.width}x${size.height}/recents$suffix.png',
          ),
        );
      },
    );

    testWidgets('displays the error message when saved prices cannot be read', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      fakeSupabase.shouldThrowOnSelectMatch = true;

      await pumpSheet(tester: tester, theme: theme);

      await expectLater(
        find.byType(YourRatesRecentsSheet),
        matchesGoldenFile(
          'goldens/your_rates_recents_sheet/${size.width}x${size.height}/load_error$suffix.png',
        ),
      );
    });

    testWidgets('displays the disabled Try again button while it retries', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      fakeSupabase.shouldThrowOnSelectMatch = true;
      await pumpSheet(tester: tester, theme: theme);
      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = Completer<void>();

      await tester.tap(
        find.byKey(const Key('your_rates_recents_try_again_button')),
      );
      await tester.pump();

      await expectLater(
        find.byType(YourRatesRecentsSheet),
        matchesGoldenFile(
          'goldens/your_rates_recents_sheet/${size.width}x${size.height}/load_error_retrying$suffix.png',
        ),
      );

      fakeSupabase.completer!.complete();
      await tester.pumpAndSettle();
    });
    testWidgets(
      'displays Used rows ordered by last use above a never-added Saved row',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);
        clock.set(DateTime(2026, 1, 15, 12));

        seedRate(
          itemName: 'Mini excavator',
          amount: 250,
          method: EquipmentPricingMethod.day,
          savedAt: clock.now().subtract(const Duration(days: 90)),
          lastUsedAt: clock.now().subtract(const Duration(hours: 2)),
        );
        seedRate(
          itemName: 'Scissor lift — 19ft',
          amount: 120,
          method: EquipmentPricingMethod.day,
          savedAt: clock.now().subtract(const Duration(days: 3)),
        );
        seedRate(
          itemName: 'Dumpster — 30 yd',
          amount: 400,
          method: EquipmentPricingMethod.job,
          savedAt: clock.now().subtract(const Duration(days: 120)),
          lastUsedAt: clock.now().subtract(const Duration(days: 45)),
        );

        await pumpSheet(tester: tester, theme: theme);

        expect(find.text('Used today'), findsOneWidget);
        expect(find.text('Saved 3 days ago'), findsOneWidget);
        expect(find.text('Used last month'), findsOneWidget);

        await expectLater(
          find.byType(YourRatesRecentsSheet),
          matchesGoldenFile(
            'goldens/your_rates_recents_sheet/${size.width}x${size.height}/recents_used_and_saved$suffix.png',
          ),
        );
      },
    );
  });
}

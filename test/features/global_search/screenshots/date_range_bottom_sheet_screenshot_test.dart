import 'dart:async';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

class _DateRangeBottomSheetScreenshotModule extends Module {
  final AppBootstrap appBootstrap;

  _DateRangeBottomSheetScreenshotModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    GlobalSearchModule(appBootstrap),
  ];
}

void main() {
  const size = Size(390, 844);
  const ratio = 1.0;
  const testName = 'date_range_bottom_sheet';
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() async {
    await loadAppFontsAll();
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(_DateRangeBottomSheetScreenshotModule(bootstrap));
    final supabase = Modular.get<SupabaseWrapper>();
    expect(supabase, isA<FakeSupabaseWrapper>());
    fakeSupabase = supabase as FakeSupabaseWrapper;
  });

  tearDownAll(() {
    Modular.destroy();
  });

  setUp(() {
    fakeSupabase.reset();
  });

  // Opens CoreDateRangeSheet directly over the real page — with the same
  // labels GlobalSearchPage's CoreDateFilterChip passes — so the golden's
  // backdrop matches what users actually see while the pre-selected custom
  // range stays controllable without driving bloc state through the chip.
  Future<void> pumpPageAndOpenDateRangeSheet({
    required WidgetTester tester,
    DateRange? initialRange,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GlobalSearchPage(
          router: Modular.get<AppRouter>(),
          blocFactory: () => Modular.get<GlobalSearchBloc>(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();

    final pageContext = tester.element(find.byType(GlobalSearchPage));
    final l10n = pageContext.l10n;
    unawaited(
      CoreDateRangeSheet.show(
        context: pageContext,
        initialRange: initialRange,
        title: l10n.dateRangeSheetTitle,
        todayLabel: l10n.dateRangeSheetToday,
        last7DaysLabel: l10n.dateRangeSheetLast7Days,
        last30DaysLabel: l10n.dateRangeSheetLast30Days,
        thisMonthLabel: l10n.dateRangeSheetThisMonth,
        customRangeLabel: l10n.dateRangeSheetCustomRange,
        startDateLabel: l10n.dateRangeSheetStartDateLabel,
        endDateLabel: l10n.dateRangeSheetEndDateLabel,
        cancelLabel: l10n.dateRangeSheetCancel,
        applyLabel: l10n.dateRangeSheetApply,
        confirmLabel: l10n.dateRangeSheetConfirm,
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();
  }

  group('DateRangeBottomSheet Screenshot Tests - Light', () {
    testWidgets('renders default state with Today selected', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpPageAndOpenDateRangeSheet(tester: tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default.png',
        ),
      );
    });

    testWidgets('renders with a custom range pre-selected', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpPageAndOpenDateRangeSheet(
        tester: tester,
        initialRange: DateRange(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 5),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_custom_selected.png',
        ),
      );
    });
  });

  group('DateRangeBottomSheet Screenshot Tests - Dark', () {
    testWidgets('renders default state with Today selected', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpPageAndOpenDateRangeSheet(
        tester: tester,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default_dark.png',
        ),
      );
    });

    testWidgets('renders with a custom range pre-selected', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpPageAndOpenDateRangeSheet(
        tester: tester,
        initialRange: DateRange(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 5),
        ),
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_custom_selected_dark.png',
        ),
      );
    });
  });
}

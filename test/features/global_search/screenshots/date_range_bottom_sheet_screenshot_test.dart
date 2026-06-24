import 'dart:async';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/features/global_search/presentation/widgets/date_range_bottom_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

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

  // GlobalSearchPage doesn't yet expose a date filter chip (CA-170 wires that
  // up); until then this opens DateRangeBottomSheet directly over the real
  // page so the golden's backdrop matches what users will actually see.
  Future<void> pumpPageAndOpenDateRangeSheet({
    required WidgetTester tester,
    DateRange? initialRange,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GlobalSearchPage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();

    final pageContext = tester.element(find.byType(GlobalSearchPage));
    unawaited(
      DateRangeBottomSheet.show(
        context: pageContext,
        initialRange: initialRange,
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
}

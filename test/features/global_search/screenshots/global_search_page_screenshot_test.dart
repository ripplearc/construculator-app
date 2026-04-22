import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
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

class _GlobalSearchPageScreenshotModule extends Module {
  final AppBootstrap appBootstrap;
  _GlobalSearchPageScreenshotModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    GlobalSearchModule(appBootstrap),
  ];
}

void main() {
  const size = Size(390, 844);
  const ratio = 1.0;
  const testName = 'global_search_page';
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFontsAll();
  });

  setUp(() {
    final fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    final appBootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(_GlobalSearchPageScreenshotModule(appBootstrap));
    Modular.replaceInstance<SupabaseWrapper>(fakeSupabase);
  });

  tearDown(() {
    Modular.destroy();
  });

  Future<void> pumpGlobalSearchPage({required WidgetTester tester}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GlobalSearchPage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();
  }

  group('GlobalSearchPage Screenshot Tests', () {
    testWidgets('renders default state correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpGlobalSearchPage(tester: tester);

      await expectLater(
        find.byType(GlobalSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default.png',
        ),
      );
    });

    testWidgets(
      'renders with search text and clear button visible correctly',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;

        await pumpGlobalSearchPage(tester: tester);

        final textFieldFinder = find.descendant(
          of: find.byType(GlobalSearchPage),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(textFieldFinder, 'concrete');
        await tester.pumpAndSettle();
        expect(find.text('concrete'), findsOneWidget);

        await expectLater(
          find.byType(GlobalSearchPage),
          matchesGoldenFile(
            'goldens/$testName/${size.width}x${size.height}/${testName}_with_search_text.png',
          ),
        );
      },
    );
  });
}

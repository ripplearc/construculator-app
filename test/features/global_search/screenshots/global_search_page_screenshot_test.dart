import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

const String _testUserId = 'user-screenshot-test';
const String _testUserEmail = 'screenshot@test.com';

Map<String, dynamic> _fakeHistoryRow(String term) => {
  DatabaseConstants.idColumn: term,
  DatabaseConstants.userIdColumn: _testUserId,
  DatabaseConstants.searchTermColumn: term,
  DatabaseConstants.scopeColumn: 'dashboard',
  DatabaseConstants.searchCountColumn: 1,
  DatabaseConstants.createdAtColumn: '2024-01-01T00:00:00.000Z',
};

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

  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() async {
    await loadAppFontsAll();
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(_GlobalSearchPageScreenshotModule(bootstrap));
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

  Future<void> pumpGlobalSearchPage({required WidgetTester tester}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
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
  }

  group('GlobalSearchPage Screenshot Tests', () {
    testWidgets('renders default state correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

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
        addTearDown(tester.view.reset);

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

    testWidgets('renders with recent searches correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      fakeSupabase.setCurrentUser(
        FakeUser(
          id: _testUserId,
          email: _testUserEmail,
          createdAt: '2024-01-01T00:00:00.000Z',
        ),
      );
      fakeSupabase.addTableData(DatabaseConstants.searchHistoryTable, [
        _fakeHistoryRow('Material of building'),
        _fakeHistoryRow('MD bungalow'),
      ]);

      await pumpGlobalSearchPage(tester: tester);

      await expectLater(
        find.byType(GlobalSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_recent_searches.png',
        ),
      );
    });

    testWidgets('renders with active tag filter chips correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpGlobalSearchPage(tester: tester);

      Modular.get<GlobalSearchBloc>().add(
        const GlobalSearchTagFiltersApplied(tags: {'Roofing', 'Wall'}),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GlobalSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_active_tags.png',
        ),
      );
    });

    testWidgets('renders with active date filter chip correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpGlobalSearchPage(tester: tester);

      // Drive the interaction through the actual widget tree (tap) rather
      // than a second Modular.get<GlobalSearchBloc>() call, since the bloc
      // is registered as a factory (i.add) — a freshly resolved instance
      // would not be the one GlobalSearchPage's BlocProvider created.
      await tester.tap(find.byKey(const Key('global_search_date_filter_chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('date_range_apply_button')));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(GlobalSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_active_date_filter.png',
        ),
      );
    });
  });
}

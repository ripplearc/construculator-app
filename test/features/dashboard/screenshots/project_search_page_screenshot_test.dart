import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/project_search_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

const String _testUserId = 'user-project-search-screenshot-test';
const String _testUserEmail = 'project-search-screenshot@test.com';

class _ProjectSearchPageScreenshotModule extends Module {
  final AppBootstrap appBootstrap;

  _ProjectSearchPageScreenshotModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    DashboardModule(appBootstrap),
  ];

  @override
  void binds(Injector i) {
    i.add<ProjectDropdownBloc>(
      () => ProjectDropdownBloc(projectRepository: i(), authManager: i()),
    );
  }
}

void main() {
  const size = Size(390, 844);
  const ratio = 1.0;
  const testName = 'project_search_page';
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() async {
    await loadAppFontsAll();
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(_ProjectSearchPageScreenshotModule(bootstrap));
    final supabase = Modular.get<SupabaseWrapper>();
    expect(supabase, isA<FakeSupabaseWrapper>());
    fakeSupabase = supabase as FakeSupabaseWrapper;
  });

  tearDownAll(() {
    Modular.destroy();
  });

  setUp(() {
    fakeSupabase.reset();
    fakeSupabase.setCurrentUser(
      FakeUser(
        id: _testUserId,
        email: _testUserEmail,
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
    );
  });

  Future<void> pumpProjectSearchPage({
    required WidgetTester tester,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProjectSearchPage(
          router: Modular.get<AppRouter>(),
          blocFactory: () => Modular.get<ProjectSearchBloc>(),
          projectDropdownBloc: Modular.get<ProjectDropdownBloc>(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();
  }

  group('ProjectSearchPage Screenshot Tests - Light', () {
    testWidgets('renders default state correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectSearchPage(tester: tester);

      await expectLater(
        find.byType(ProjectSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default.png',
        ),
      );
    });

    testWidgets('renders with search text and clear button visible correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectSearchPage(tester: tester);

      final textFieldFinder = find.descendant(
        of: find.byType(ProjectSearchPage),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(textFieldFinder, 'wall');
      await tester.pumpAndSettle();
      expect(find.text('wall'), findsOneWidget);

      await expectLater(
        find.byType(ProjectSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_search_text.png',
        ),
      );
    });

    testWidgets('renders with recent searches correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      fakeSupabase.addTableData(DatabaseConstants.projectSearchHistoryTable, [
        {
          DatabaseConstants.userIdColumn: _testUserId,
          DatabaseConstants.searchTermColumn: 'foundation',
          DatabaseConstants.updatedAtColumn: '2024-06-01T00:00:00.000Z',
        },
        {
          DatabaseConstants.userIdColumn: _testUserId,
          DatabaseConstants.searchTermColumn: 'wall',
          DatabaseConstants.updatedAtColumn: '2024-05-01T00:00:00.000Z',
        },
      ]);

      await pumpProjectSearchPage(tester: tester);

      await expectLater(
        find.byType(ProjectSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_recent_searches.png',
        ),
      );
    });

    testWidgets('renders with suggestions correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      fakeSupabase.setRpcResponse(
        DatabaseConstants.projectSearchSuggestionsRpcFunction,
        ['Carpentry', 'Carparking cost', 'Plumbing'],
      );

      await pumpProjectSearchPage(tester: tester);

      final searchField = find.byType(TextFormField);
      await tester.enterText(searchField, 'Car');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(ProjectSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_suggestions.png',
        ),
      );
    });

    testWidgets('renders the chip row with an active tag filter correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      fakeSupabase.addTableData(DatabaseConstants.tagsTable, [
        {
          DatabaseConstants.idColumn: 'tag-Roofing',
          DatabaseConstants.nameColumn: 'Roofing',
        },
      ]);

      await pumpProjectSearchPage(tester: tester);

      // Drive the real flow: open the Tags sheet, select a tag, apply — so the
      // golden captures the active-pill chip row users will actually see.
      await tester.tap(
        find.byKey(const Key('project_search_tags_filter_chip')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('project_search_tag_filter_item_Roofing')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('project_search_tags_filter_apply_button')),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(ProjectSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_active_tag_filter.png',
        ),
      );
    });

    testWidgets('renders the chip row with an active date filter correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectSearchPage(tester: tester);

      // The date sheet derives its presets from the wall clock and
      // CoreDateFilterChip exposes no `today` override, so drive the bloc
      // with a fixed range instead of tapping through the sheet to keep the
      // active pill's label deterministic.
      final chipContext = tester.element(
        find.byKey(const Key('project_search_modified_filter_chip')),
      );
      BlocProvider.of<ProjectSearchBloc>(chipContext).add(
        ProjectSearchDateFilterAppliedEvent(
          range: DateRange(
            start: DateTime(2026, 1, 1),
            end: DateTime(2026, 1, 5),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(ProjectSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_active_date_filter.png',
        ),
      );
    });

    testWidgets('renders search results correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      fakeSupabase.setRpcResponse(
        DatabaseConstants.projectSearchSuggestionsRpcFunction,
        <String>[],
      );
      fakeSupabase.setRpcResponse(DatabaseConstants.globalSearchRpcFunction, {
        'projects': [
          {
            DatabaseConstants.idColumn: 'project-golden-1',
            DatabaseConstants.projectNameColumn: 'Downtown Office Complex',
            DatabaseConstants.descriptionColumn: 'Test description',
            DatabaseConstants.creatorUserIdColumn: _testUserId,
            DatabaseConstants.owningCompanyIdColumn: null,
            DatabaseConstants.exportFolderLinkColumn: null,
            DatabaseConstants.exportStorageProviderColumn: null,
            DatabaseConstants.createdAtColumn: '2024-01-01T10:00:00.000Z',
            DatabaseConstants.updatedAtColumn: '2024-01-01T10:00:00.000Z',
            DatabaseConstants.statusColumn: 'active',
          },
          {
            DatabaseConstants.idColumn: 'project-golden-2',
            DatabaseConstants.projectNameColumn: 'Shopping Mall Renovation',
            DatabaseConstants.descriptionColumn: 'Test description',
            DatabaseConstants.creatorUserIdColumn: _testUserId,
            DatabaseConstants.owningCompanyIdColumn: null,
            DatabaseConstants.exportFolderLinkColumn: null,
            DatabaseConstants.exportStorageProviderColumn: null,
            DatabaseConstants.createdAtColumn: '2024-02-15T14:30:00.000Z',
            DatabaseConstants.updatedAtColumn: '2024-02-15T14:30:00.000Z',
            DatabaseConstants.statusColumn: 'active',
          },
        ],
        'estimations': <Map<String, dynamic>>[],
        'members': <Map<String, dynamic>>[],
      });

      await pumpProjectSearchPage(tester: tester);

      final textFieldFinder = find.descendant(
        of: find.byType(ProjectSearchPage),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(textFieldFinder, 'project');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(ProjectSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_search_results.png',
        ),
      );
    });
  });

  group('ProjectSearchPage Screenshot Tests - Dark', () {
    testWidgets('renders default state correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectSearchPage(tester: tester, theme: createTestThemeDark());

      await expectLater(
        find.byType(ProjectSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default_dark.png',
        ),
      );
    });

    testWidgets(
      'renders with search text and clear button visible correctly',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);

        await pumpProjectSearchPage(tester: tester, theme: createTestThemeDark());

        final textFieldFinder = find.descendant(
          of: find.byType(ProjectSearchPage),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(textFieldFinder, 'wall');
        await tester.pumpAndSettle();
        expect(find.text('wall'), findsOneWidget);

        await expectLater(
          find.byType(ProjectSearchPage),
          matchesGoldenFile(
            'goldens/$testName/${size.width}x${size.height}/${testName}_with_search_text_dark.png',
          ),
        );
      },
    );

    testWidgets('renders with recent searches correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      fakeSupabase.addTableData(DatabaseConstants.projectSearchHistoryTable, [
        {
          DatabaseConstants.userIdColumn: _testUserId,
          DatabaseConstants.searchTermColumn: 'foundation',
          DatabaseConstants.updatedAtColumn: '2024-06-01T00:00:00.000Z',
        },
        {
          DatabaseConstants.userIdColumn: _testUserId,
          DatabaseConstants.searchTermColumn: 'wall',
          DatabaseConstants.updatedAtColumn: '2024-05-01T00:00:00.000Z',
        },
      ]);

      await pumpProjectSearchPage(tester: tester, theme: createTestThemeDark());

      await expectLater(
        find.byType(ProjectSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_recent_searches_dark.png',
        ),
      );
    });

    testWidgets('renders with suggestions correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      fakeSupabase.setRpcResponse(
        DatabaseConstants.projectSearchSuggestionsRpcFunction,
        ['Carpentry', 'Carparking cost', 'Plumbing'],
      );

      await pumpProjectSearchPage(tester: tester, theme: createTestThemeDark());

      final searchField = find.byType(TextFormField);
      await tester.enterText(searchField, 'Car');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.awaitImages();

      await expectLater(
        find.byType(ProjectSearchPage),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_suggestions_dark.png',
        ),
      );
    });
  });
}

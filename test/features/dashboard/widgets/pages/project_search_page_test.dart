import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/project_search_page.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_empty_recent_widget.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_recent_searches_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

const String _testUserId = 'user-project-search-page-test';
const String _testUserEmail = 'project-search-page@test.com';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  BuildContext? buildContext;

  setUpAll(() async {
    await loadAppFontsAll();
  });

  setUp(() {
    final clock = FakeClockImpl();
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: clock),
    );
    Modular.init(DashboardModule(bootstrap));
    final supabase = Modular.get<SupabaseWrapper>();
    expect(supabase, isA<FakeSupabaseWrapper>());
    fakeSupabase = supabase as FakeSupabaseWrapper;
    router = FakeAppRouter();

    fakeSupabase.setCurrentUser(
      FakeUser(
        id: _testUserId,
        email: _testUserEmail,
        createdAt: clock.now().toIso8601String(),
      ),
    );
  });

  tearDown(() {
    Modular.destroy();
  });

  void seedRecentSearches() {
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
  }

  Widget makeTestableWidget({required Widget child}) {
    return MaterialApp(
      theme: createTestTheme(),
      home: Builder(
        builder: (context) {
          buildContext = context;
          return child;
        },
      ),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> renderPage(WidgetTester tester) async {
    await tester.pumpWidget(
      makeTestableWidget(
        child: ProjectSearchPage(
          router: router,
          blocFactory: () => Modular.get<ProjectSearchBloc>(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('User on ProjectSearchPage', () {
    testWidgets('sees search field with hint text', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().searchProjectsHint), findsOneWidget);
    });

    testWidgets('sees back button', (tester) async {
      await renderPage(tester);

      expect(
        find.bySemanticsLabel(l10n().globalSearchBackSemanticLabel),
        findsOneWidget,
      );
    });

    testWidgets('tapping back button pops the page', (tester) async {
      await renderPage(tester);

      await tester.tap(find.byKey(const Key('project_search_back_button')));
      await tester.pump();

      expect(router.popCalls, equals(1));
    });

    testWidgets('sees empty state message when no recent searches', (
      tester,
    ) async {
      await renderPage(tester);

      expect(find.byType(GlobalSearchEmptyRecentWidget), findsOneWidget);
    });

    testWidgets('sees Recent searches section title', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().globalSearchRecentSearchesTitle), findsOneWidget);
    });
  });

  group('User on ProjectSearchPage with recent searches', () {
    testWidgets('sees recent search items', (tester) async {
      seedRecentSearches();
      await renderPage(tester);

      expect(find.byType(GlobalSearchRecentSearchesList), findsOneWidget);
      expect(find.text('foundation'), findsOneWidget);
      expect(find.text('wall'), findsOneWidget);
    });

    testWidgets('tapping trailing icon fills search field', (tester) async {
      seedRecentSearches();
      await renderPage(tester);

      final trailingIcon = find.descendant(
        of: find.byKey(const ValueKey('recent_search_item_foundation')),
        matching: find.byKey(const Key('trailing_icon')),
      );
      expect(trailingIcon, findsOneWidget);

      await tester.tap(trailingIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.descendant(
          of: find.byType(TextFormField),
          matching: find.text('foundation'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping row body fills search field and runs search', (
      tester,
    ) async {
      seedRecentSearches();
      await renderPage(tester);

      await tester.tap(find.byKey(const ValueKey('recent_search_item_foundation')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      expect(
        find.descendant(
          of: find.byType(TextFormField),
          matching: find.text('foundation'),
        ),
        findsOneWidget,
      );
    });
  });
}

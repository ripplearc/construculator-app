import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_empty_recent_widget.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_recent_searches_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
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

const String _testUserId = 'user-page-test';
const String _testUserEmail = 'page@test.com';

/// CoreToast displays for 3 seconds by default (the package does not export
/// the duration as a constant); pump just past it to flush the auto-dismiss
/// timer before the test ends.
const Duration _kToastDismissDuration = Duration(seconds: 4);

Map<String, dynamic> _fakeHistoryRow(String term) => {
  DatabaseConstants.idColumn: term,
  DatabaseConstants.userIdColumn: _testUserId,
  DatabaseConstants.searchTermColumn: term,
  DatabaseConstants.scopeColumn: 'dashboard',
  DatabaseConstants.searchCountColumn: 1,
  DatabaseConstants.createdAtColumn: '2024-01-01T00:00:00.000Z',
};

class _GlobalSearchPageTestModule extends Module {
  final AppBootstrap appBootstrap;

  _GlobalSearchPageTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    GlobalSearchModule(appBootstrap),
  ];
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  BuildContext? buildContext;

  setUpAll(() {
    final clock = FakeClockImpl();
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: clock),
    );
    Modular.init(_GlobalSearchPageTestModule(bootstrap));
    final supabase = Modular.get<SupabaseWrapper>();
    expect(supabase, isA<FakeSupabaseWrapper>());
    fakeSupabase = supabase as FakeSupabaseWrapper;

    final appRouter = Modular.get<AppRouter>();
    expect(appRouter, isA<FakeAppRouter>());
    router = appRouter as FakeAppRouter;
  });

  tearDownAll(() {
    Modular.destroy();
  });

  setUp(() {
    fakeSupabase.reset();
    router.reset();
  });

  Widget makeTestableWidget({required Widget child, ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
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

  void seedRecentSearches() {
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
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> renderPage(WidgetTester tester) async {
    await tester.pumpWidget(
      makeTestableWidget(
        child: GlobalSearchPage(
          router: router,
          blocFactory: () => Modular.get<GlobalSearchBloc>(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('User on GlobalSearchPage', () {
    testWidgets('sees search field with hint text', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().globalSearchHint), findsOneWidget);
    });

    testWidgets('sees back button', (tester) async {
      await renderPage(tester);

      expect(find.bySemanticsLabel(l10n().globalSearchBackSemanticLabel), findsOneWidget);
    });

    testWidgets('sees Tags filter chip', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().globalSearchFilterTags), findsOneWidget);
    });

    testWidgets('sees Modified filter chip', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().globalSearchFilterModified), findsOneWidget);
    });

    testWidgets('sees Type filter chip', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().globalSearchFilterType), findsOneWidget);
    });

    testWidgets(
      'tapping the Modified chip opens the date range sheet and applying shows the active pill',
      (tester) async {
        await renderPage(tester);

        await tester.tap(find.byKey(const Key('global_search_date_filter_chip')));
        await tester.pumpAndSettle();
        expect(find.text(l10n().dateRangeSheetTitle), findsOneWidget);

        await tester.tap(find.byKey(const Key('date_range_apply_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('active_date_filter_chip')), findsOneWidget);
        expect(find.byKey(const Key('global_search_date_filter_chip')), findsNothing);
      },
    );

    testWidgets('clearing the active date filter restores the inactive chip', (
      tester,
    ) async {
      await renderPage(tester);

      await tester.tap(find.byKey(const Key('global_search_date_filter_chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('date_range_apply_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('active_date_filter_chip')), findsOneWidget);

      await tester.tap(find.byKey(const Key('active_date_filter_chip')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('global_search_date_filter_chip')), findsOneWidget);
      expect(find.byKey(const Key('active_date_filter_chip')), findsNothing);
    });

    testWidgets('sees Recent searches section title', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().globalSearchRecentSearchesTitle), findsOneWidget);
    });

    testWidgets('sees empty state message when no recent searches', (
      tester,
    ) async {
      await renderPage(tester);

      expect(find.byType(GlobalSearchEmptyRecentWidget), findsOneWidget);
    });

    testWidgets('clear button is not visible when search field is empty', (
      tester,
    ) async {
      await renderPage(tester);

      expect(find.byKey(const ValueKey('core_search_box_clear_button')), findsNothing);
    });

    testWidgets(
      'clear button is visible after entering text and clears field on tap',
      (tester) async {
        await renderPage(tester);

        await tester.enterText(
          find.ancestor(
            of: find.text(l10n().globalSearchHint),
            matching: find.byType(TextFormField),
          ),
          'concrete',
        );
        await tester.pump();

        expect(find.byKey(const ValueKey('core_search_box_clear_button')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('core_search_box_clear_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byKey(const ValueKey('core_search_box_clear_button')), findsNothing);
      },
    );

    testWidgets('back button pops the route', (tester) async {
      await renderPage(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(router.popCalls, greaterThan(0));
    });

    testWidgets('submitting an empty search shows the empty-query toast', (
      tester,
    ) async {
      await renderPage(tester);

      final searchField = find.ancestor(
        of: find.text(l10n().globalSearchHint),
        matching: find.byType(TextFormField),
      );
      // Explicitly enter an empty string rather than relying on the field's
      // default state, so the test's intent survives setup changes.
      await tester.enterText(searchField, '');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(find.text(l10n().globalSearchEmptyQueryMessage), findsOneWidget);

      await tester.pump(_kToastDismissDuration);
    });

    testWidgets(
      'submitting a whitespace-only search shows the empty-query toast',
      (tester) async {
        await renderPage(tester);

        final searchField = find.ancestor(
          of: find.text(l10n().globalSearchHint),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(searchField, '   ');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();

        expect(find.text(l10n().globalSearchEmptyQueryMessage), findsOneWidget);

        await tester.pump(_kToastDismissDuration);
      },
    );
  });

  group('User on GlobalSearchPage with recent searches', () {
    testWidgets('sees recent search items', (tester) async {
      seedRecentSearches();
      await renderPage(tester);

      expect(find.byType(GlobalSearchRecentSearchesList), findsOneWidget);
      expect(find.text('Material of building'), findsOneWidget);
      expect(find.text('MD bungalow'), findsOneWidget);
    });

    testWidgets('tapping trailing icon fills search field', (tester) async {
      seedRecentSearches();
      await renderPage(tester);

      final trailingIcon = find.descendant(
        of: find.byKey(const ValueKey('recent_search_item_Material of building')),
        matching: find.byKey(const Key('trailing_icon')),
      );
      expect(trailingIcon, findsOneWidget);

      await tester.tap(trailingIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.descendant(
          of: find.byType(TextFormField),
          matching: find.text('Material of building'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping row body fills search field', (tester) async {
      seedRecentSearches();
      await renderPage(tester);

      await tester.tap(find.byKey(const ValueKey('recent_search_item_Material of building')));
      await tester.pump();
      // 5 s needed: filling the field fires onChanged → GlobalSearchQueryUpdated
      // → RxDart debounceTime(300 ms) timer → async RPC. Shorter durations leave
      // a pending timer at teardown and fail the !timersPending invariant.
      await tester.pump(const Duration(seconds: 5));

      expect(
        find.descendant(
          of: find.byType(TextFormField),
          matching: find.text('Material of building'),
        ),
        findsOneWidget,
      );
    });

  });
}

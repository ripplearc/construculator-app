import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/project_search_page.dart';
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

const String _testUserId = 'user-project-search-page-test';
const String _testUserEmail = 'project-search-page@test.com';

class _ProjectSearchPageTestModule extends Module {
  final AppBootstrap appBootstrap;

  _ProjectSearchPageTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    DashboardModule(appBootstrap),
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
    Modular.init(_ProjectSearchPageTestModule(bootstrap));
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
    fakeSupabase.setCurrentUser(
      FakeUser(
        id: _testUserId,
        email: _testUserEmail,
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
    );
  });

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> renderPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        home: Builder(
          builder: (context) {
            buildContext = context;
            return ProjectSearchPage(
              router: router,
              blocFactory: () => Modular.get<ProjectSearchBloc>(),
            );
          },
        ),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
        find.bySemanticsLabel(l10n().projectSearchBackSemanticLabel),
        findsOneWidget,
      );
    });

    testWidgets('dispatches ProjectSearchHistoryRequestedEvent on init', (
      tester,
    ) async {
      await renderPage(tester);

      // Assert the observable side effect of the event actually firing: the
      // recent-searches fetch hit the history table exactly once.
      final historyFetches = fakeSupabase
          .getMethodCallsFor('selectMatch')
          .where(
            (call) =>
                call['table'] == DatabaseConstants.projectSearchHistoryTable,
          );
      expect(historyFetches, hasLength(1));
    });

    testWidgets('tapping back button pops via router', (tester) async {
      await renderPage(tester);

      await tester.tap(find.byKey(const Key('project_search_back_button')));
      await tester.pump();

      expect(router.popCalls, 1);
    });

    testWidgets('sees Tags filter chip', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().projectSearchFilterTags), findsOneWidget);
    });

    testWidgets('sees Modified filter chip', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().projectSearchFilterModified), findsOneWidget);
    });

    testWidgets(
      'entering text in the search box dispatches ProjectSearchQueryUpdatedEvent',
      (tester) async {
        await renderPage(tester);

        final searchField = find.ancestor(
          of: find.text(l10n().searchProjectsHint),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(searchField, 'deck');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        final element = tester.element(
          find.descendant(
            of: find.byType(ProjectSearchPage),
            matching: find.byType(
              BlocBuilder<ProjectSearchBloc, ProjectSearchState>,
            ),
          ),
        );
        final state = BlocProvider.of<ProjectSearchBloc>(element).state;
        expect(state, isA<ProjectSearchInitial>());
        expect((state as ProjectSearchInitial).query, 'deck');

        // 5 s needed: filling the field fires onChanged → ProjectSearchQueryUpdatedEvent
        // → RxDart debounceTime(300 ms) timer → async RPC. Shorter durations leave
        // a pending timer at teardown and fail the !timersPending invariant.
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'submitting a search dispatches ProjectSearchPerformedEvent',
      (tester) async {
        fakeSupabase.setRpcResponse(DatabaseConstants.globalSearchRpcFunction, {
          'projects': [],
          'estimations': [],
          'members': [],
        });
        await renderPage(tester);

        final searchField = find.ancestor(
          of: find.text(l10n().searchProjectsHint),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(searchField, 'wall');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();
        await tester.pump();

        final element = tester.element(
          find.descendant(
            of: find.byType(ProjectSearchPage),
            matching: find.byType(
              BlocBuilder<ProjectSearchBloc, ProjectSearchState>,
            ),
          ),
        );
        final state = BlocProvider.of<ProjectSearchBloc>(element).state;
        expect(state, isA<ProjectSearchResultsLoaded>());

        await tester.pump(const Duration(seconds: 5));
      },
    );
  });
}

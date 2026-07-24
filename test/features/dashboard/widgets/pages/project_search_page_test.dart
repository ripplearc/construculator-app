import 'dart:async';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/project_search_page.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_empty_recent_widget.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_owner_filter_sheet.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_recent_searches_list.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_suggestions_list.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_tags_filter_sheet.dart';
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
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

const String _testUserId = 'user-project-search-page-test';
const String _testUserEmail = 'project-search-page@test.com';

/// CoreToast displays for 3 seconds by default (the package does not export
/// the duration as a constant); pump just past it to flush the auto-dismiss
/// timer before the test ends.
const Duration _kToastDismissDuration = Duration(seconds: 4);

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

  void seedSuggestions(List<String> terms) {
    fakeSupabase.setRpcResponse(
      DatabaseConstants.projectSearchSuggestionsRpcFunction,
      terms,
    );
  }

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

    testWidgets('sees Owner filter chip', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().projectSearchFilterOwner), findsOneWidget);
    });

    testWidgets('tapping the Modified chip opens the date range sheet', (
      tester,
    ) async {
      await renderPage(tester);

      await tester.tap(
        find.byKey(const Key('project_search_modified_filter_chip')),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n().dateRangeSheetTitle), findsOneWidget);

      await tester.tap(find.byKey(const Key('date_range_apply_button')));
      await tester.pumpAndSettle();

      // Applying a range swaps the plain chip for the active pill.
      expect(
        find.byKey(const Key('project_search_active_modified_filter_chip')),
        findsOneWidget,
      );
    });

    testWidgets(
      'choosing Custom range opens the start and end date pickers with the '
      'localized confirm label',
      (tester) async {
        await renderPage(tester);

        await tester.tap(
          find.byKey(const Key('project_search_modified_filter_chip')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('date_range_option_custom')));
        await tester.pumpAndSettle();

        // Start-date picker: the confirm button must carry the app's l10n
        // value, not CoreDatePicker's built-in default.
        expect(find.text(l10n().dateRangeSheetStartDateLabel), findsOneWidget);
        expect(find.text(l10n().dateRangeSheetConfirm), findsOneWidget);

        await tester.tap(find.text(l10n().dateRangeSheetConfirm));
        await tester.pumpAndSettle();

        // End-date picker renders the same localized confirm label.
        expect(find.text(l10n().dateRangeSheetEndDateLabel), findsOneWidget);
        expect(find.text(l10n().dateRangeSheetConfirm), findsOneWidget);
      },
    );

    testWidgets(
      'tapping the Tags chip opens the tags sheet; applying shows the '
      'active pill and tapping the pill clears it',
      (tester) async {
        fakeSupabase.addTableData(DatabaseConstants.tagsTable, [
          {
            DatabaseConstants.idColumn: 'tag-Roofing',
            DatabaseConstants.nameColumn: 'Roofing',
          },
        ]);
        await renderPage(tester);

        await tester.tap(
          find.byKey(const Key('project_search_tags_filter_chip')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProjectSearchTagsFilterSheet), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('project_search_tag_filter_item_Roofing')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('project_search_tags_filter_apply_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('project_search_active_tag_chip_Roofing')),
          findsOneWidget,
        );
        // The re-open chip stays available next to the active pill.
        expect(
          find.byKey(const Key('project_search_tags_filter_chip_active')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('project_search_active_tag_chip_Roofing')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('project_search_active_tag_chip_Roofing')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('project_search_tags_filter_chip')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping the Owner chip opens the owner sheet; applying shows the '
      'active pill with the owner name and tapping the pill clears it',
      (tester) async {
        fakeSupabase.setRpcResponse(
          DatabaseConstants.projectOwnersRpcFunction,
          [
            {
              DatabaseConstants.idColumn: 'owner-ada',
              DatabaseConstants.credentialIdColumn: null,
              DatabaseConstants.firstNameColumn: 'Ada',
              DatabaseConstants.lastNameColumn: 'Lovelace',
              DatabaseConstants.professionalRoleColumn: 'Engineer',
              DatabaseConstants.profilePhotoUrlColumn: null,
            },
          ],
        );
        await renderPage(tester);

        await tester.tap(
          find.byKey(const Key('project_search_owner_filter_chip')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProjectSearchOwnerFilterSheet), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('project_search_owner_filter_item_owner-ada')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('project_search_owner_filter_apply_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('project_search_active_owner_chip_owner-ada')),
          findsOneWidget,
        );
        // The active pill shows the owner's full name, not the raw id.
        expect(find.text('Ada Lovelace'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('project_search_active_owner_chip_owner-ada')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('project_search_active_owner_chip_owner-ada')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('project_search_owner_filter_chip')),
          findsOneWidget,
        );
      },
    );

    testWidgets('sees empty state message when no recent searches', (
      tester,
    ) async {
      await renderPage(tester);

      expect(find.byType(ProjectSearchEmptyRecentWidget), findsOneWidget);
    });

    testWidgets('sees Recent searches section title', (tester) async {
      await renderPage(tester);

      expect(
        find.text(l10n().projectSearchRecentSearchesTitle),
        findsOneWidget,
      );
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
          ).first,
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
          ).first,
        );
        final state = BlocProvider.of<ProjectSearchBloc>(element).state;
        expect(state, isA<ProjectSearchResultsLoaded>());

        await tester.pump(const Duration(seconds: 5));
      },
    );
  });

  group('User on ProjectSearchPage with recent searches', () {
    testWidgets('sees recent search items', (tester) async {
      seedRecentSearches();
      await renderPage(tester);

      expect(find.byType(ProjectSearchRecentSearchesList), findsOneWidget);
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

      await tester.tap(
        find.byKey(const ValueKey('recent_search_item_foundation')),
      );
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

    testWidgets('shows a loading indicator while history is loading', (
      tester,
    ) async {
      seedRecentSearches();
      // Hold the history fetch open so the isLoadingHistory frame is
      // observable; renderPage's pumpAndSettle would hang on the spinner.
      final completer = Completer<void>();
      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = completer;

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: ProjectSearchPage(
            router: router,
            blocFactory: () => Modular.get<ProjectSearchBloc>(),
          ),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pump();

      expect(find.byType(CoreLoadingIndicator), findsOneWidget);

      completer.complete();
      fakeSupabase.shouldDelayOperations = false;
      await tester.pump();
      await tester.pump();

      expect(find.byType(CoreLoadingIndicator), findsNothing);
      expect(find.text('foundation'), findsOneWidget);
    });

    testWidgets('renders a blank body once a search is performed', (
      tester,
    ) async {
      seedRecentSearches();
      fakeSupabase.setRpcResponse(DatabaseConstants.globalSearchRpcFunction, {
        'projects': [],
        'estimations': [],
        'members': [],
      });
      await renderPage(tester);
      expect(find.byType(ProjectSearchRecentSearchesList), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'wall');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump();

      // Post-search states are out of CA-690/CA-689 scope, so the body is
      // intentionally blank: no history list and no spinner.
      expect(find.byType(ProjectSearchRecentSearchesList), findsNothing);
      expect(find.byType(CoreLoadingIndicator), findsNothing);

      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('User on ProjectSearchPage with suggestions', () {
    testWidgets(
      'typing a non-empty query shows the suggestions title and list',
      (tester) async {
        seedSuggestions(['Carpentry', 'Carparking cost', 'Plumbing']);
        await renderPage(tester);

        final searchField = find.ancestor(
          of: find.text(l10n().searchProjectsHint),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(searchField, 'Car');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(find.text(l10n().projectSearchSuggestionsTitle), findsOneWidget);
        expect(find.byType(ProjectSearchSuggestionsList), findsOneWidget);
        expect(find.text('Carpentry'), findsOneWidget);
        expect(find.text('Carparking cost'), findsOneWidget);
        expect(find.text('Plumbing'), findsNothing);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets('clearing the query restores the recent searches title', (
      tester,
    ) async {
      seedRecentSearches();
      seedSuggestions(['Carpentry']);
      await renderPage(tester);

      final searchField = find.ancestor(
        of: find.text(l10n().searchProjectsHint),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(searchField, 'Car');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text(l10n().projectSearchSuggestionsTitle), findsOneWidget);

      await tester.enterText(searchField, '');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text(l10n().projectSearchRecentSearchesTitle), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('tapping a suggestion fills the search field', (tester) async {
      seedSuggestions(['Carpentry', 'Carparking cost']);
      await renderPage(tester);

      final searchField = find.ancestor(
        of: find.text(l10n().searchProjectsHint),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(searchField, 'Car');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('suggestion_item_Carpentry')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      expect(
        find.descendant(
          of: find.byType(TextFormField),
          matching: find.text('Carpentry'),
        ),
        findsOneWidget,
      );
    });
  });

  group('User on ProjectSearchPage with a failed search', () {
    Future<void> submitSearch(WidgetTester tester, String query) async {
      final searchField = find.ancestor(
        of: find.text(l10n().searchProjectsHint),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(searchField, query);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump();
    }

    testWidgets(
      'sees the search-failure toast and the persistent failure body with '
      'a retry button',
      (tester) async {
        // Suggestions succeed; global_search stays unconfigured so only the
        // performed search fails (the fake throws for unconfigured RPCs).
        seedSuggestions(const []);
        await renderPage(tester);

        await submitSearch(tester, 'office');

        expect(find.text(l10n().searchPerformErrorMessage), findsOneWidget);
        expect(find.text(l10n().searchFailureBodyMessage), findsOneWidget);
        expect(
          find.byKey(const Key('searchFailureRetryButton')),
          findsOneWidget,
        );

        await tester.pump(_kToastDismissDuration);
        // The toast dismisses; the failure body stays.
        expect(find.text(l10n().searchFailureBodyMessage), findsOneWidget);
      },
    );

    testWidgets(
      'tapping retry re-runs the failed search and clears the failure body '
      'on success',
      (tester) async {
        seedSuggestions(const []);
        await renderPage(tester);

        await submitSearch(tester, 'office');
        expect(find.text(l10n().searchFailureBodyMessage), findsOneWidget);
        await tester.pump(_kToastDismissDuration);

        fakeSupabase.setRpcResponse(DatabaseConstants.globalSearchRpcFunction, {
          'projects': <Map<String, dynamic>>[],
          'estimations': <Map<String, dynamic>>[],
          'members': <Map<String, dynamic>>[],
        });

        await tester.tap(find.byKey(const Key('searchFailureRetryButton')));
        await tester.pumpAndSettle();

        expect(find.text(l10n().searchFailureBodyMessage), findsNothing);
      },
    );
  });

  group('User on ProjectSearchPage with failing filter fetches', () {
    testWidgets(
      'sees the tags-load warning toast when fetching tags fails',
      (tester) async {
        seedSuggestions(const []);
        await renderPage(tester);

        // History load already succeeded during render; only the tags fetch
        // triggered by opening the sheet hits the failing select.
        fakeSupabase.shouldThrowOnSelectMatch = true;

        await tester.tap(
          find.byKey(const Key('project_search_tags_filter_chip')),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(l10n().projectSearchTagsLoadErrorMessage),
          findsOneWidget,
        );

        await tester.pump(_kToastDismissDuration);
      },
    );

    testWidgets(
      'sees the owners-load warning toast when fetching owners fails',
      (tester) async {
        seedSuggestions(const []);
        await renderPage(tester);

        // Only the owners RPC fires after this point, so the global flag
        // fails exactly the fetch under test.
        fakeSupabase.shouldThrowOnRpc = true;

        await tester.tap(
          find.byKey(const Key('project_search_owner_filter_chip')),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(l10n().projectSearchOwnersLoadErrorMessage),
          findsOneWidget,
        );

        await tester.pump(_kToastDismissDuration);
      },
    );
  });
}

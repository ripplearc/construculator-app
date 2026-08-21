import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
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

import '../../../../libraries/estimation/helpers/estimation_test_data_map_factory.dart'
    as estimation_factory;
import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/fake_project_dropdown_bloc_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

const String _testUserId = 'user-a11y-test';
const String _testUserEmail = 'a11y@test.com';

Map<String, dynamic> _fakeHistoryRow(String term) => {
  DatabaseConstants.idColumn: term,
  DatabaseConstants.userIdColumn: _testUserId,
  DatabaseConstants.searchTermColumn: term,
  DatabaseConstants.scopeColumn: 'dashboard',
  DatabaseConstants.searchCountColumn: 1,
  DatabaseConstants.createdAtColumn: '2024-01-01T00:00:00.000Z',
};

class _GlobalSearchPageA11yTestModule extends Module {
  final AppBootstrap appBootstrap;

  _GlobalSearchPageA11yTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    GlobalSearchModule(appBootstrap),
  ];
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  BuildContext? buildContext;

  setUpAll(() {
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(_GlobalSearchPageA11yTestModule(bootstrap));
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

  Widget makeTestableWidget({ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      home: Builder(
        builder: (context) {
          final projectDropdownBloc = FakeProjectDropdownBlocFactory.create();
          addTearDown(projectDropdownBloc.close);
          buildContext = context;
          return GlobalSearchPage(
            router: Modular.get<AppRouter>(),
            blocFactory: () => Modular.get<GlobalSearchBloc>(),
            estimationTileProvider: Modular.get<EstimationTileProvider>(),
            projectDropdownBloc: projectDropdownBloc,
          );
        },
      ),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  group('GlobalSearchPage – accessibility', () {
    testWidgets('meets a11y guidelines for back button in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(theme: theme),
        find.byKey(const Key('global_search_back_button')),
        checkTapTargetSize: true,
      );
    });

    testWidgets('meets a11y guidelines for clear button in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(theme: theme),
        find.byKey(const ValueKey('core_search_box_clear_button')),
        checkTapTargetSize: true,
        setupAfterPump: (t) async {
          await t.enterText(find.byType(TextFormField), 'concrete');
          await t.pump();
        },
      );
    });

    testWidgets(
      'meets a11y text contrast for recent searches title in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await tester.pumpWidget(makeTestableWidget());
        await tester.pumpAndSettle();
        final titleText = l10n().globalSearchRecentSearchesTitle;

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.text(titleText),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      },
    );

    testWidgets(
      'meets a11y text contrast for empty state message in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await tester.pumpWidget(makeTestableWidget());
        await tester.pumpAndSettle();
        final emptyText = l10n().globalSearchEmptyRecentMessage;

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.text(emptyText),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for recent search item in both themes',
      (tester) async {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        fakeSupabase.addTableData(DatabaseConstants.searchHistoryTable, [
          _fakeHistoryRow('Material of building'),
        ]);

        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const ValueKey('recent_search_item_Material of building')),
          checkTapTargetSize: true,
          checkLabeledTapTarget: true,
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for Tags filter chip in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('global_search_tags_filter_chip')),
          checkTapTargetSize: true,
          checkLabeledTapTarget: true,
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for Type filter chip in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('global_search_type_filter_chip')),
          checkTapTargetSize: true,
          checkLabeledTapTarget: true,
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for Modified date filter chip in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('global_search_date_filter_chip')),
          checkTapTargetSize: true,
          checkLabeledTapTarget: true,
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for active date filter dismiss chip in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('active_date_filter_chip')),
          checkTapTargetSize: true,
          checkLabeledTapTarget: true,
          setupAfterPump: (t) async {
            // Apply a fixed range to the in-tree BLoC so the active dismiss
            // pill renders. GlobalSearchPage owns the BlocProvider, so the BLoC
            // is read from a descendant element (the factory registration means
            // Modular.get would return a different instance).
            final element = t.element(
              find.descendant(
                of: find.byType(GlobalSearchPage),
                matching: find.byType(
                  BlocConsumer<GlobalSearchBloc, GlobalSearchState>,
                ),
              ),
            );
            BlocProvider.of<GlobalSearchBloc>(element).add(
              GlobalSearchDateFilterApplied(
                range: DateRange(
                  start: DateTime(2026, 1, 5),
                  end: DateTime(2026, 1, 12),
                ),
              ),
            );
            await t.pumpAndSettle();
          },
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for active tag dismiss chip in both themes',
      (tester) async {
        fakeSupabase.addTableData(DatabaseConstants.tagsTable, [
          {
            DatabaseConstants.idColumn: 'tag-Roofing',
            DatabaseConstants.nameColumn: 'Roofing',
          },
        ]);

        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('active_tag_chip_Roofing')),
          checkTapTargetSize: true,
          checkLabeledTapTarget: true,
          setupAfterPump: (t) async {
            // GlobalSearchBloc is registered as a factory (i.add), so every
            // pumpWidget starts with a fresh bloc and GlobalSearchStarted
            // resets selectedTags to empty — the chip is never pre-populated
            // here. This guard is a safety net in case registration ever
            // changes to a singleton; it is not a currently reachable path.
            if (find
                .byKey(const Key('active_tag_chip_Roofing'))
                .evaluate()
                .isNotEmpty) {
              return;
            }
            await t.tap(find.byKey(const Key('global_search_tags_filter_chip')));
            await t.pumpAndSettle();
            await t.tap(find.byKey(const Key('tag_filter_item_Roofing')));
            await t.pump();
            await t.tap(find.byKey(const Key('tags_filter_apply_button')));
            await t.pumpAndSettle();
          },
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for active type dismiss chip in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('active_type_chip_estimation')),
          checkTapTargetSize: true,
          checkLabeledTapTarget: true,
          setupAfterPump: (t) async {
            // Switch the scope on the in-tree BLoC so the active Type pill
            // renders (see the date-filter test above for why the BLoC is
            // read from a descendant element).
            final element = t.element(
              find.descendant(
                of: find.byType(GlobalSearchPage),
                matching: find.byType(
                  BlocConsumer<GlobalSearchBloc, GlobalSearchState>,
                ),
              ),
            );
            BlocProvider.of<GlobalSearchBloc>(element).add(
              const GlobalSearchScopeChanged(scope: SearchScope.estimation),
            );
            await t.pumpAndSettle();
          },
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for the Cost option row inside the open Type '
      'sheet in both themes',
      (tester) async {
        // A signed-in user keeps the recents load from failing, so no error
        // toast overlays the chip row while the sheet is being opened.
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('type_filter_option_cost')),
          checkTapTargetSize: true,
          checkLabeledTapTarget: true,
          setupAfterPump: (t) async {
            // The Navigator state survives the per-theme pumpWidget, so the
            // sheet route opened by the previous theme pass would leave a
            // modal barrier that swallows the chip tap — pop back first.
            t.state<NavigatorState>(find.byType(Navigator).first).popUntil(
              (route) => route.isFirst,
            );
            await t.pumpAndSettle();
            // The Type chip is the last chip in the horizontal filter row and
            // sits partially offscreen at the default surface width.
            await t.ensureVisible(
              find.byKey(const Key('global_search_type_filter_chip')),
            );
            await t.pumpAndSettle();
            await t.tap(find.byKey(const Key('global_search_type_filter_chip')));
            await t.pumpAndSettle();
          },
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for the disabled Calculation option row inside '
      'the open Type sheet in both themes',
      (tester) async {
        // A signed-in user keeps the recents load from failing, so no error
        // toast overlays the chip row while the sheet is being opened.
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('type_filter_option_calculation')),
          checkTapTargetSize: true,
          // The row is disabled (no tap action), so the labeled-tap-target
          // guideline does not apply; the default contrast check still
          // verifies its textDisable colour against the sheet background.
          checkLabeledTapTarget: false,
          setupAfterPump: (t) async {
            // The Navigator state survives the per-theme pumpWidget, so the
            // sheet route opened by the previous theme pass would leave a
            // modal barrier that swallows the chip tap — pop back first.
            t.state<NavigatorState>(find.byType(Navigator).first).popUntil(
              (route) => route.isFirst,
            );
            await t.pumpAndSettle();
            // The Type chip is the last chip in the horizontal filter row and
            // sits partially offscreen at the default surface width.
            await t.ensureVisible(
              find.byKey(const Key('global_search_type_filter_chip')),
            );
            await t.pumpAndSettle();
            await t.tap(find.byKey(const Key('global_search_type_filter_chip')));
            await t.pumpAndSettle();
          },
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for an estimation result card in both themes',
      (tester) async {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        fakeSupabase.setRpcResponse(
          DatabaseConstants.searchSuggestionsRpcFunction,
          <String>[],
        );
        fakeSupabase.setRpcResponse(DatabaseConstants.globalSearchRpcFunction, {
          'projects': <Map<String, dynamic>>[],
          'estimations': [
            estimation_factory
                .EstimationTestDataMapFactory.createFakeEstimationData(),
          ],
          'members': <Map<String, dynamic>>[],
        });

        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(
            ValueKey('estimationCard_${estimation_factory.estimateIdDefault}'),
          ),
          checkTapTargetSize: true,
          checkLabeledTapTarget: true,
          setupAfterPump: (t) async {
            await t.enterText(find.byType(TextFormField), 'estimate');
            await t.pump(const Duration(milliseconds: 400));
            await t.testTextInput.receiveAction(TextInputAction.search);
            await t.pumpAndSettle();
          },
        );
      },
    );

    testWidgets(
      'meets a11y text contrast for the no-results message in both themes',
      (tester) async {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        fakeSupabase.setRpcResponse(
          DatabaseConstants.searchSuggestionsRpcFunction,
          <String>[],
        );
        fakeSupabase.setRpcResponse(DatabaseConstants.globalSearchRpcFunction, {
          'projects': <Map<String, dynamic>>[],
          'estimations': <Map<String, dynamic>>[],
          'members': <Map<String, dynamic>>[],
        });

        await setupA11yTest(tester);

        // Pure l10n lookup — no widget tree needed; the guideline helper
        // below pumps the page itself.
        final emptyResultsText = lookupAppLocalizations(
          const Locale('en'),
        ).searchResultsEmpty('nonexistent');

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.text(emptyResultsText),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
          setupAfterPump: (t) async {
            await t.enterText(find.byType(TextFormField), 'nonexistent');
            await t.pump(const Duration(milliseconds: 400));
            await t.testTextInput.receiveAction(TextInputAction.search);
            await t.pumpAndSettle();
          },
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for search failure retry button in both themes',
      (tester) async {
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: _testUserId,
            email: _testUserEmail,
            createdAt: '2024-01-01T00:00:00.000Z',
          ),
        );
        // Suggestions succeed; global_search stays unconfigured so the
        // performed search fails and the retryable failure body renders.
        fakeSupabase.setRpcResponse(
          DatabaseConstants.searchSuggestionsRpcFunction,
          <String>[],
        );

        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('searchFailureRetryButton')),
          checkTapTargetSize: true,
          checkLabeledTapTarget: true,
          setupAfterPump: (t) async {
            await t.enterText(find.byType(TextFormField), 'concrete');
            await t.pump(const Duration(milliseconds: 400));
            await t.testTextInput.receiveAction(TextInputAction.search);
            await t.pump();
            await t.pump();
            // Flush the failure toast's auto-dismiss timer so no timer is
            // pending when the theme pass completes.
            await t.pump(const Duration(seconds: 4));
          },
        );
      },
    );
  });
}

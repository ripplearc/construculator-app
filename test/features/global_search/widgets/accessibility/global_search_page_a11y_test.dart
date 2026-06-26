import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/features/global_search/presentation/widgets/date_range_bottom_sheet.dart';
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

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
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
          buildContext = context;
          return GlobalSearchPage(
            router: Modular.get<AppRouter>(),
            blocFactory: () => Modular.get<GlobalSearchBloc>(),
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
  });
}

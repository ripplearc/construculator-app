import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/project_search_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
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

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

const String _testUserId = 'user-project-search-a11y-test';
const String _testUserEmail = 'project-search-a11y@test.com';

class _ProjectSearchPageA11yTestModule extends Module {
  final AppBootstrap appBootstrap;

  _ProjectSearchPageA11yTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    DashboardModule(appBootstrap),
  ];
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() {
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(_ProjectSearchPageA11yTestModule(bootstrap));
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

  Widget makeTestableWidget({ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      home: ProjectSearchPage(
        router: Modular.get<AppRouter>(),
        blocFactory: () => Modular.get<ProjectSearchBloc>(),
      ),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  group('ProjectSearchPage – accessibility', () {
    testWidgets('meets a11y guidelines for back button in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(theme: theme),
        find.byKey(const Key('project_search_back_button')),
        checkTapTargetSize: true,
      );
    });

    testWidgets('meets a11y guidelines for Tags filter chip in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(theme: theme),
        find.byKey(const Key('project_search_tags_filter_chip')),
        checkTapTargetSize: true,
        checkLabeledTapTarget: true,
      );
    });

    testWidgets('meets a11y guidelines for Owner filter chip in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(theme: theme),
        find.byKey(const Key('project_search_owner_filter_chip')),
        checkTapTargetSize: true,
        checkLabeledTapTarget: true,
      );
    });

    testWidgets(
      'meets a11y guidelines for Modified filter chip in both themes',
      (tester) async {
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('project_search_modified_filter_chip')),
          checkTapTargetSize: true,
          checkLabeledTapTarget: true,
        );
      },
    );

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
          await t.enterText(find.byType(TextFormField), 'wall');
          await t.pump();
        },
      );
    });

    testWidgets(
      'meets a11y guidelines for recent search fill icon in both themes',
      (tester) async {
        await setupA11yTest(tester);
        fakeSupabase.addTableData(
          DatabaseConstants.projectSearchHistoryTable,
          [
            {
              DatabaseConstants.userIdColumn: _testUserId,
              DatabaseConstants.searchTermColumn: 'foundation',
              DatabaseConstants.updatedAtColumn: '2024-06-01T00:00:00.000Z',
            },
          ],
        );

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.descendant(
            of: find.byKey(const ValueKey('recent_search_item_foundation')),
            matching: find.byKey(const Key('trailing_icon')),
          ),
          checkTapTargetSize: true,
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for suggestion fill icon in both themes',
      (tester) async {
        await setupA11yTest(tester);
        fakeSupabase.setRpcResponse(
          DatabaseConstants.projectSearchSuggestionsRpcFunction,
          ['Carpentry'],
        );

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.bySemanticsLabel(
            AppLocalizationsEn().projectSearchSuggestionFillSemanticLabel(
              'Carpentry',
            ),
          ),
          checkTapTargetSize: true,
          setupAfterPump: (t) async {
            await t.enterText(find.byType(TextFormField), 'Car');
            await t.pump(const Duration(milliseconds: 400));
            await t.pump();
          },
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for search failure retry button in both themes',
      (tester) async {
        await setupA11yTest(tester);
        // Suggestions succeed; global_search stays unconfigured so the
        // performed search fails and the retryable failure body renders.
        fakeSupabase.setRpcResponse(
          DatabaseConstants.projectSearchSuggestionsRpcFunction,
          <String>[],
        );

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('searchFailureRetryButton')),
          checkTapTargetSize: true,
          checkLabeledTapTarget: true,
          setupAfterPump: (t) async {
            await t.enterText(find.byType(TextFormField), 'office');
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

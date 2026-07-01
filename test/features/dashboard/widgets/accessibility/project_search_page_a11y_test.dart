import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/project_search_page.dart';
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

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

const String _testUserId = 'user-project-search-a11y-test';
const String _testUserEmail = 'project-search-a11y@test.com';

void main() {
  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() {
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(DashboardModule(bootstrap));
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
        router: FakeAppRouter(),
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
  });
}

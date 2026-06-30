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

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

const String _testUserId = 'user-project-search-screenshot-test';
const String _testUserEmail = 'project-search-screenshot@test.com';

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

  Future<void> pumpProjectSearchPage({required WidgetTester tester}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProjectSearchPage(
          router: FakeAppRouter(),
          blocFactory: () => Modular.get<ProjectSearchBloc>(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();
  }

  group('ProjectSearchPage Screenshot Tests', () {
    testWidgets('renders empty recent searches state correctly', (
      tester,
    ) async {
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
  });
}

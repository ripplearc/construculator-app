import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/fake_project_dropdown_bloc_factory.dart';
import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

class _TypeFilterSheetScreenshotModule extends Module {
  final AppBootstrap appBootstrap;

  _TypeFilterSheetScreenshotModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    GlobalSearchModule(appBootstrap),
  ];
}

void main() {
  const size = Size(390, 844);
  const ratio = 1.0;
  const testName = 'global_search_type_filter_sheet';
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() async {
    await loadAppFontsAll();
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(_TypeFilterSheetScreenshotModule(bootstrap));
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

  Future<void> pumpPageAndOpenTypeSheet({
    required WidgetTester tester,
    required ThemeData theme,
    SearchScope scopeBeforeOpen = SearchScope.dashboard,
  }) async {
    final projectDropdownBloc = FakeProjectDropdownBlocFactory.create();
    addTearDown(projectDropdownBloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GlobalSearchPage(
          router: Modular.get<AppRouter>(),
          blocFactory: () => Modular.get<GlobalSearchBloc>(),
          estimationTileProvider: Modular.get<EstimationTileProvider>(),
          projectDropdownBloc: projectDropdownBloc,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();

    if (scopeBeforeOpen != SearchScope.dashboard) {
      // GlobalSearchPage creates the BlocProvider internally, so we look up
      // the BLoC from a descendant element that sits below it.
      final element = tester.element(
        find.descendant(
          of: find.byType(GlobalSearchPage),
          matching: find.byType(
            BlocConsumer<GlobalSearchBloc, GlobalSearchState>,
          ),
        ),
      );
      final bloc = BlocProvider.of<GlobalSearchBloc>(element);
      bloc.add(GlobalSearchScopeChanged(scope: scopeBeforeOpen));
      await tester.pumpAndSettle();
    }

    final chipKey = scopeBeforeOpen == SearchScope.dashboard
        ? const Key('global_search_type_filter_chip')
        : const Key('global_search_type_filter_chip_active');
    // The Type chip sits at the end of the horizontally scrolling chip row
    // and starts off-screen once an active pill widens the row.
    await tester.ensureVisible(find.byKey(chipKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(chipKey));
    await tester.pumpAndSettle();
    await tester.awaitImages();
  }

  screenshotThemeGroups('GlobalSearchTypeFilterSheet Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders default state with nothing selected', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpPageAndOpenTypeSheet(tester: tester, theme: theme);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default$suffix.png',
        ),
      );
    });

    testWidgets('renders with the Cost scope selected', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpPageAndOpenTypeSheet(
        tester: tester,
        scopeBeforeOpen: SearchScope.estimation,
        theme: theme,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_cost_scope$suffix.png',
        ),
      );
    });
  });
}

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_tags_filter_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/await_images_extension.dart';
import '../../../utils/screenshot/font_loader.dart';

class _TagsFilterSheetScreenshotModule extends Module {
  final AppBootstrap appBootstrap;

  _TagsFilterSheetScreenshotModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    GlobalSearchModule(appBootstrap),
  ];
}

void main() {
  const size = Size(390, 844);
  const ratio = 1.0;
  const testName = 'global_search_tags_filter_sheet';
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabase;

  setUpAll(() async {
    await loadAppFontsAll();
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(_TagsFilterSheetScreenshotModule(bootstrap));
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

  Future<void> pumpPageAndOpenTagsSheet({
    required WidgetTester tester,
    Set<String> activeTagsBeforeOpen = const {},
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GlobalSearchPage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.awaitImages();

    if (activeTagsBeforeOpen.isNotEmpty) {
      // GlobalSearchPage creates the BlocProvider internally, so we look up
      // the BLoC from a descendant element that sits below it.
      final element = tester.element(
        find.descendant(
          of: find.byType(GlobalSearchPage),
          matching: find.byType(BlocConsumer<GlobalSearchBloc, GlobalSearchState>),
        ),
      );
      final bloc = BlocProvider.of<GlobalSearchBloc>(element);
      bloc.add(
        GlobalSearchTagFiltersApplied(
          tags: Set.unmodifiable(activeTagsBeforeOpen),
        ),
      );
      await tester.pumpAndSettle();
    }

    final chipKey = activeTagsBeforeOpen.isEmpty
        ? const Key('global_search_tags_filter_chip')
        : const Key('global_search_tags_filter_chip_active');
    await tester.tap(find.byKey(chipKey));
    await tester.pumpAndSettle();
    await tester.awaitImages();
  }

  group('GlobalSearchTagsFilterSheet Screenshot Tests', () {
    testWidgets('renders default state with no tags selected', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpPageAndOpenTagsSheet(tester: tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default.png',
        ),
      );
    });

    testWidgets('renders with pre-selected tags checked', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpPageAndOpenTagsSheet(
        tester: tester,
        activeTagsBeforeOpen: const {'Roofing', 'Wall'},
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_selected_tags.png',
        ),
      );
    });

    testWidgets('renders with search query filtering the tag list', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpPageAndOpenTagsSheet(tester: tester);

      await tester.enterText(
        find.descendant(
          of: find.byType(GlobalSearchTagsFilterSheet),
          matching: find.byType(TextFormField),
        ),
        'ing',
      );
      await tester.pump();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_with_search_query.png',
        ),
      );
    });
  });
}

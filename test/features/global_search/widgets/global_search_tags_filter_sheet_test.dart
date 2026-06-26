import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/bloc/global_search_bloc/global_search_bloc.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/features/global_search/presentation/widgets/global_search_tags_filter_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

class _TagsFilterSheetTestModule extends Module {
  final AppBootstrap appBootstrap;

  _TagsFilterSheetTestModule(this.appBootstrap);

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
    Modular.init(_TagsFilterSheetTestModule(bootstrap));
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

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  void seedTags(List<String> names) {
    fakeSupabase.addTableData(
      DatabaseConstants.tagsTable,
      names
          .map(
            (name) => <String, dynamic>{
              DatabaseConstants.idColumn: 'tag-$name',
              DatabaseConstants.nameColumn: name,
            },
          )
          .toList(),
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    List<String> tags = const ['Roofing', 'Carpeting', 'Flooring', 'Wall'],
  }) async {
    seedTags(tags);
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            buildContext = context;
            return GlobalSearchPage(
              router: Modular.get<AppRouter>(),
              blocFactory: () => Modular.get<GlobalSearchBloc>(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester, {bool active = false}) async {
    final chipKey = active
        ? const Key('global_search_tags_filter_chip_active')
        : const Key('global_search_tags_filter_chip');
    await tester.tap(find.byKey(chipKey));
    await tester.pumpAndSettle();
  }

  bool isTagChecked(WidgetTester tester, String tag) {
    final tile = tester.widget<CheckboxListTile>(
      find.byKey(Key('tag_filter_item_$tag')),
    );
    return tile.value == true;
  }

  group('User on GlobalSearchTagsFilterSheet', () {
    testWidgets('opens the sheet by tapping the Tags filter chip', (
      tester,
    ) async {
      await pumpPage(tester);

      await openSheet(tester);

      expect(find.byType(GlobalSearchTagsFilterSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GlobalSearchTagsFilterSheet),
          matching: find.text(l10n().globalSearchTagsSheetTitle),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('tag_filter_item_Roofing')), findsOneWidget);
    });

    testWidgets('shows the empty label when no tags are available', (
      tester,
    ) async {
      await pumpPage(tester, tags: const []);

      await openSheet(tester);

      expect(find.byKey(const Key('tags_filter_empty_label')), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
    });

    testWidgets('filters the tag list when typing a search query', (
      tester,
    ) async {
      await pumpPage(tester);
      await openSheet(tester);

      await tester.enterText(
        find.descendant(
          of: find.byType(GlobalSearchTagsFilterSheet),
          matching: find.byType(TextFormField),
        ),
        'Roof',
      );
      await tester.pump();

      expect(find.byKey(const Key('tag_filter_item_Roofing')), findsOneWidget);
      expect(find.byKey(const Key('tag_filter_item_Wall')), findsNothing);
    });

    testWidgets('shows all tags again when the search query is cleared', (
      tester,
    ) async {
      await pumpPage(tester);
      await openSheet(tester);

      final searchField = find.descendant(
        of: find.byType(GlobalSearchTagsFilterSheet),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(searchField, 'Roof');
      await tester.pump();
      expect(find.byKey(const Key('tag_filter_item_Wall')), findsNothing);

      await tester.enterText(searchField, '');
      await tester.pump();

      expect(find.byKey(const Key('tag_filter_item_Wall')), findsOneWidget);
    });

    testWidgets('toggles a tag checkbox on tap', (tester) async {
      await pumpPage(tester);
      await openSheet(tester);

      expect(isTagChecked(tester, 'Roofing'), isFalse);

      await tester.tap(find.byKey(const Key('tag_filter_item_Roofing')));
      await tester.pump();
      expect(isTagChecked(tester, 'Roofing'), isTrue);

      await tester.tap(find.byKey(const Key('tag_filter_item_Roofing')));
      await tester.pump();
      expect(isTagChecked(tester, 'Roofing'), isFalse);
    });

    testWidgets(
      'applies selected tags, closes the sheet, and shows active chips',
      (tester) async {
        await pumpPage(tester);
        await openSheet(tester);

        await tester.tap(find.byKey(const Key('tag_filter_item_Roofing')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('tags_filter_apply_button')));
        await tester.pumpAndSettle();

        expect(find.byType(GlobalSearchTagsFilterSheet), findsNothing);
        expect(
          find.byKey(const Key('active_tag_chip_Roofing')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('global_search_tags_filter_chip_active')),
          findsOneWidget,
        );
      },
    );

    testWidgets('pre-checks previously applied tags when reopened', (
      tester,
    ) async {
      await pumpPage(tester);
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('tag_filter_item_Roofing')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('tags_filter_apply_button')));
      await tester.pumpAndSettle();

      await openSheet(tester, active: true);

      expect(isTagChecked(tester, 'Roofing'), isTrue);
      expect(isTagChecked(tester, 'Wall'), isFalse);
    });

    testWidgets('Clear all deselects every tag without closing the sheet', (
      tester,
    ) async {
      await pumpPage(tester);
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('tag_filter_item_Roofing')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('tag_filter_item_Wall')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('tags_filter_clear_all_button')));
      await tester.pump();

      expect(find.byType(GlobalSearchTagsFilterSheet), findsOneWidget);
      expect(isTagChecked(tester, 'Roofing'), isFalse);
      expect(isTagChecked(tester, 'Wall'), isFalse);
    });

    testWidgets('applying an empty selection restores the default Tags chip', (
      tester,
    ) async {
      await pumpPage(tester);
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('tag_filter_item_Roofing')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('tags_filter_apply_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('active_tag_chip_Roofing')), findsOneWidget);

      await openSheet(tester, active: true);
      await tester.tap(find.byKey(const Key('tags_filter_clear_all_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('tags_filter_apply_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('active_tag_chip_Roofing')), findsNothing);
      expect(
        find.byKey(const Key('global_search_tags_filter_chip')),
        findsOneWidget,
      );
    });

    testWidgets('tapping an active tag chip clears that tag filter', (
      tester,
    ) async {
      await pumpPage(tester);
      await openSheet(tester);

      await tester.tap(find.byKey(const Key('tag_filter_item_Roofing')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('tag_filter_item_Wall')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('tags_filter_apply_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('active_tag_chip_Roofing')), findsOneWidget);
      expect(find.byKey(const Key('active_tag_chip_Wall')), findsOneWidget);

      await tester.tap(find.byKey(const Key('active_tag_chip_Roofing')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('active_tag_chip_Roofing')), findsNothing);
      expect(find.byKey(const Key('active_tag_chip_Wall')), findsOneWidget);
    });
  });
}

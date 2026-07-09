import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_search_tags_filter_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
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

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

class _TagsFilterSheetTestModule extends Module {
  final AppBootstrap appBootstrap;

  _TagsFilterSheetTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [DashboardModule(appBootstrap)];
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late ProjectSearchBloc bloc;
  BuildContext? buildContext;

  setUp(() {
    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(_TagsFilterSheetTestModule(bootstrap));
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    fakeSupabase.setCurrentUser(
      FakeUser(
        id: 'user-1',
        email: 'user@test.com',
        createdAt: DateTime(2024).toIso8601String(),
      ),
    );
  });

  tearDown(() {
    bloc.close();
    fakeSupabase.reset();
    Modular.destroy();
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

  /// Pumps a host page whose button opens [ProjectSearchTagsFilterSheet] via
  /// [CoreQuickSheet], mirroring how the production page presents the sheet.
  Future<void> pumpAndOpenSheet(
    WidgetTester tester, {
    List<String> tags = const ['Roofing', 'Carpeting', 'Flooring', 'Wall'],
    Set<String> initialSelectedTags = const {},
  }) async {
    // Create the bloc inside the test zone: a bloc created in setUp lives
    // outside the fake-async zone and its awaits never resume under pump.
    bloc = Modular.get<ProjectSearchBloc>();
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
            return Scaffold(
              body: Center(
                child: CoreFilterChip(
                  key: const Key('open_sheet_button'),
                  label: 'open',
                  onTap: () {
                    bloc.add(const ProjectSearchAvailableTagsRequestedEvent());
                    CoreQuickSheet.show(
                      context: context,
                      child: BlocProvider.value(
                        value: bloc,
                        child: ProjectSearchTagsFilterSheet(
                          initialSelectedTags: initialSelectedTags,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_sheet_button')));
    await tester.pumpAndSettle();
  }

  bool isTagChecked(WidgetTester tester, String tag) {
    final tile = tester.widget<CheckboxListTile>(
      find.byKey(Key('project_search_tag_filter_item_$tag')),
    );
    return tile.value == true;
  }

  group('User on ProjectSearchTagsFilterSheet', () {
    testWidgets('sees the sheet title and the available tag list', (
      tester,
    ) async {
      await pumpAndOpenSheet(tester);

      expect(find.byType(ProjectSearchTagsFilterSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ProjectSearchTagsFilterSheet),
          matching: find.text(l10n().projectSearchTagsSheetTitle),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('project_search_tag_filter_item_Roofing')),
        findsOneWidget,
      );
    });

    testWidgets('sees the empty label when no tags are available', (
      tester,
    ) async {
      await pumpAndOpenSheet(tester, tags: const []);

      expect(
        find.byKey(const Key('project_search_tags_filter_empty_label')),
        findsOneWidget,
      );
      expect(find.byType(CheckboxListTile), findsNothing);
    });

    testWidgets('filters the tag list when typing a search query', (
      tester,
    ) async {
      await pumpAndOpenSheet(tester);

      await tester.enterText(
        find.descendant(
          of: find.byType(ProjectSearchTagsFilterSheet),
          matching: find.byType(TextFormField),
        ),
        'Roof',
      );
      await tester.pump();

      expect(
        find.byKey(const Key('project_search_tag_filter_item_Roofing')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('project_search_tag_filter_item_Wall')),
        findsNothing,
      );
    });

    testWidgets('toggles a tag checkbox on tap', (tester) async {
      await pumpAndOpenSheet(tester);

      expect(isTagChecked(tester, 'Roofing'), isFalse);

      await tester.tap(
        find.byKey(const Key('project_search_tag_filter_item_Roofing')),
      );
      await tester.pump();
      expect(isTagChecked(tester, 'Roofing'), isTrue);

      await tester.tap(
        find.byKey(const Key('project_search_tag_filter_item_Roofing')),
      );
      await tester.pump();
      expect(isTagChecked(tester, 'Roofing'), isFalse);
    });

    testWidgets('pre-checks the initially selected tags', (tester) async {
      await pumpAndOpenSheet(tester, initialSelectedTags: {'Wall'});

      expect(isTagChecked(tester, 'Wall'), isTrue);
      expect(isTagChecked(tester, 'Roofing'), isFalse);
    });

    testWidgets(
      'Apply dispatches the selection to the bloc and closes the sheet',
      (tester) async {
        await pumpAndOpenSheet(tester);

        await tester.tap(
          find.byKey(const Key('project_search_tag_filter_item_Roofing')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('project_search_tags_filter_apply_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProjectSearchTagsFilterSheet), findsNothing);
        final state = bloc.state;
        expect(state, isA<ProjectSearchInitial>());
        expect((state as ProjectSearchInitial).selectedTags, {'Roofing'});
      },
    );

    testWidgets('Clear all deselects every tag without closing the sheet', (
      tester,
    ) async {
      await pumpAndOpenSheet(tester);

      await tester.tap(
        find.byKey(const Key('project_search_tag_filter_item_Roofing')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('project_search_tag_filter_item_Wall')),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(const Key('project_search_tags_filter_clear_all_button')),
      );
      await tester.pump();

      expect(find.byType(ProjectSearchTagsFilterSheet), findsOneWidget);
      expect(isTagChecked(tester, 'Roofing'), isFalse);
      expect(isTagChecked(tester, 'Wall'), isFalse);
    });
  });
}

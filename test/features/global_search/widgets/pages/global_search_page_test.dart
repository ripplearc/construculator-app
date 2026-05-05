import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

class _GlobalSearchPageTestModule extends Module {
  final AppBootstrap appBootstrap;
  _GlobalSearchPageTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    GlobalSearchModule(appBootstrap),
  ];
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  BuildContext? buildContext;

  Widget makeTestableWidget({required Widget child, ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      home: Builder(
        builder: (context) {
          buildContext = context;
          return child;
        },
      ),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  setUp(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());

    final appBootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );

    Modular.init(_GlobalSearchPageTestModule(appBootstrap));
    Modular.replaceInstance<SupabaseWrapper>(fakeSupabase);
    router = Modular.get<AppRouter>() as FakeAppRouter;
  });

  tearDown(() {
    Modular.destroy();
  });

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> renderPage(WidgetTester tester) async {
    await tester.pumpWidget(
      makeTestableWidget(child: const GlobalSearchPage()),
    );
    await tester.pumpAndSettle();
  }

  group('User on GlobalSearchPage', () {
    testWidgets('sees search field with hint text', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().globalSearchHint), findsOneWidget);
    });

    testWidgets('sees back button', (tester) async {
      await renderPage(tester);

      expect(find.bySemanticsLabel(l10n().globalSearchBackSemanticLabel), findsOneWidget);
    });

    testWidgets('sees Tags filter chip', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().globalSearchFilterTags), findsOneWidget);
    });

    testWidgets('sees Modified filter chip', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().globalSearchFilterModified), findsOneWidget);
    });

    testWidgets('sees Type filter chip', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().globalSearchFilterType), findsOneWidget);
    });

    testWidgets('sees Recent searches section title', (tester) async {
      await renderPage(tester);

      expect(find.text(l10n().globalSearchRecentSearchesTitle), findsOneWidget);
    });

    testWidgets('sees empty state message when no recent searches', (
      tester,
    ) async {
      await renderPage(tester);

      expect(find.text(l10n().globalSearchEmptyRecentMessage), findsOneWidget);
    });

    testWidgets('clear button is not visible when search field is empty', (
      tester,
    ) async {
      await renderPage(tester);

      expect(find.byKey(const ValueKey('core_search_box_clear_button')), findsNothing);
    });

    testWidgets(
      'clear button is visible after entering text and clears field on tap',
      (tester) async {
        await renderPage(tester);

        await tester.enterText(
          find.ancestor(
            of: find.text(l10n().globalSearchHint),
            matching: find.byType(TextFormField),
          ),
          'concrete',
        );
        await tester.pump();

        expect(find.byKey(const ValueKey('core_search_box_clear_button')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('core_search_box_clear_button')));
        await tester.pump();

        expect(find.byKey(const ValueKey('core_search_box_clear_button')), findsNothing);
      },
    );

    testWidgets('back button pops the route', (tester) async {
      await renderPage(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(router.popCalls, greaterThan(0));
    });
  });
}

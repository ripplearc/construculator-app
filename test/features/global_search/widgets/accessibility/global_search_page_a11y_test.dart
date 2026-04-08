import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/global_search/global_search_module.dart';
import 'package:construculator/features/global_search/presentation/pages/global_search_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

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
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());

    final appBootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );

    Modular.init(_GlobalSearchPageA11yTestModule(appBootstrap));
    Modular.replaceInstance<SupabaseWrapper>(fakeSupabase);
  });

  tearDownAll(() {
    Modular.destroy();
  });

  Widget makeTestableWidget({ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      home: Builder(
        builder: (context) {
          buildContext = context;
          return const GlobalSearchPage();
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
        find.byKey(const Key('global_search_clear_button')),
        checkTapTargetSize: true,
        setupAfterPump: (t) async {
          await t.enterText(find.byType(TextField), 'concrete');
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
  });
}

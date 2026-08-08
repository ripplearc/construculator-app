import 'package:construculator/features/app_header/app_header_module.dart';
import 'package:construculator/features/app_header/presentation/widgets/header_row.dart';
import 'package:construculator/features/app_header/presentation/widgets/title_search_app_bar.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_project_ui_provider.dart';
import 'package:construculator/libraries/router/routes/global_search_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  group('AppHeaderModule.buildHeader', () {
    late FakeCurrentProjectNotifier fakeNotifier;
    late FakeAppRouter fakeRouter;

    setUp(() {
      fakeNotifier = FakeCurrentProjectNotifier();
      fakeRouter = FakeAppRouter();
    });

    Widget makeApp() {
      return MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppHeaderModule.buildHeader(
            currentProjectNotifier: fakeNotifier,
            router: fakeRouter,
            projectUIProvider: FakeProjectUIProvider(),
          ),
        ),
      );
    }

    testWidgets('returns TitleSearchAppBar with no project selected', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());

      expect(find.byType(TitleSearchAppBar), findsOneWidget);
      expect(find.byType(HeaderRow), findsNothing);
    });

    testWidgets('wires the TitleSearchAppBar search tap to the global search route', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp());

      await tester.tap(
        find.byKey(const Key('title_search_app_bar_search_button')),
      );
      await tester.pump();

      expect(fakeRouter.navigationHistory, [
        const RouteCall(fullGlobalSearchRoute, null),
      ]);
    });

    testWidgets('returns the project header when a project is selected', (
      tester,
    ) async {
      fakeNotifier.setCurrentProjectId('project-1');

      await tester.pumpWidget(makeApp());

      expect(find.byType(FakeProjectAppBar), findsOneWidget);
      expect(find.byType(HeaderRow), findsNothing);
    });
  });
}

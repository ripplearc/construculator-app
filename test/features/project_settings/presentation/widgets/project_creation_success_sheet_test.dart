import 'package:construculator/features/project_settings/presentation/widgets/project_creation_success_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  BuildContext? buildContext;

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Widget buildContent({
    VoidCallback? onContinue,
  }) {
    return MaterialApp(
      theme: createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          buildContext = context;
          return Scaffold(
            body: ProjectCreationSuccessSheetContent(
              onContinue: onContinue ?? () {},
            ),
          );
        },
      ),
    );
  }

  setUpAll(loadAppFontsAll);

  group('ProjectCreationSuccessSheetContent', () {
    testWidgets('renders project creation success message', (tester) async {
      await tester.pumpWidget(buildContent());
      await tester.pumpAndSettle();

      expect(find.text(l10n().projectCreationSuccessMessage), findsOneWidget);
    });

    testWidgets(
      '"Continue to Dashboard" button triggers onContinue callback',
      (tester) async {
        bool called = false;

        await tester.pumpWidget(
          buildContent(onContinue: () => called = true),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('continue_to_dashboard_button')));
        await tester.pump();

        expect(called, isTrue);
      },
    );
  });
}

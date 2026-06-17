import 'package:construculator/features/project_settings/presentation/widgets/project_creation_success_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  BuildContext? buildContext;

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Widget buildContent({
    VoidCallback? onBackToCalculation,
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
              onBackToCalculation: onBackToCalculation ?? () {},
              onContinue: onContinue ?? () {},
            ),
          );
        },
      ),
    );
  }

  group('ProjectCreationSuccessSheetContent', () {
    testWidgets('renders project creation success message', (tester) async {
      await tester.pumpWidget(buildContent());
      await tester.pumpAndSettle();

      expect(find.text(l10n().projectCreationSuccessMessage), findsOneWidget);
    });

    testWidgets(
      '"Back to calculation" button triggers onBackToCalculation callback',
      (tester) async {
        bool called = false;

        await tester.pumpWidget(
          buildContent(onBackToCalculation: () => called = true),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('back_to_calculation_button')));
        await tester.pump();

        expect(called, isTrue);
      },
    );

    testWidgets(
      '"Continue" button triggers onContinue callback',
      (tester) async {
        bool called = false;

        await tester.pumpWidget(
          buildContent(onContinue: () => called = true),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('continue_button')));
        await tester.pump();

        expect(called, isTrue);
      },
    );
  });
}

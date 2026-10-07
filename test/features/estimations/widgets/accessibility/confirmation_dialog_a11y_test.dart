import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

void main() {
  Widget makeWidget(ThemeData theme) => MaterialApp(
    theme: theme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(
      body: Center(
        child: ConfirmationDialog(
          title: 'Discard this line?',
          body: 'Interior paint has not been added to the estimate.',
          secondaryLabel: 'Discard',
          primaryLabel: 'Keep editing',
        ),
      ),
    ),
  );

  group('ConfirmationDialog – accessibility', () {
    testWidgets('a11y: the primary button meets tap target and label '
        'guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeWidget,
        find.byKey(ConfirmationDialog.primaryButtonKey),
      );
    });

    testWidgets('a11y: the secondary button meets tap target and label '
        'guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeWidget,
        find.byKey(ConfirmationDialog.secondaryButtonKey),
      );
    });
  });
}

import 'package:construculator/features/global_search/presentation/widgets/date_range_bottom_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  Widget buildSheet(ThemeData theme) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: DateRangeBottomSheet()),
    );
  }

  group('DateRangeBottomSheet accessibility', () {
    testWidgets('meets a11y guidelines for the Today range option', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildSheet,
        find.text(l10n.dateRangeSheetToday),
      );
    });

    testWidgets('meets a11y guidelines for the Custom range option', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildSheet,
        find.text(l10n.dateRangeSheetCustomRange),
      );
    });

    testWidgets('meets a11y guidelines for the Cancel button', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildSheet,
        find.text(l10n.dateRangeSheetCancel),
      );
    });

    testWidgets('meets a11y guidelines for the Apply button', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildSheet,
        find.text(l10n.dateRangeSheetApply),
      );
    });
  });
}

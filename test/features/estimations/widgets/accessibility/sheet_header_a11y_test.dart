import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  Widget makeApp(ThemeData theme) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SheetHeader(title: 'Scissor lift', subtitle: r'$120.00 / day'),
      ),
    );
  }

  group('SheetHeader – accessibility', () {
    testWidgets('back arrow has a label and meets tap target guidelines', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        makeApp,
        find.byKey(SheetHeader.backButtonKey),
      );
      expect(find.bySemanticsLabel(l10n.backLabel), findsOneWidget);
    });

    testWidgets('back arrow tap area is at least 48x48', (tester) async {
      await tester.pumpWidget(makeApp(CoreTheme.light()));

      final size = tester.getSize(find.byKey(SheetHeader.backButtonKey));

      expect(size.width, greaterThanOrEqualTo(CoreSpacing.space12));
      expect(size.height, greaterThanOrEqualTo(CoreSpacing.space12));
    });
  });
}

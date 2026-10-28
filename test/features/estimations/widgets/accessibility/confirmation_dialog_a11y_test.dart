import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

void main() {
  Widget makeWidget(ThemeData theme, {double textScale = 1.0}) => MaterialApp(
    theme: theme,
    locale: const Locale('en'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(
      body: Center(
        child: ConfirmationDialog(
          title: 'Discard this line?',
          body: TextSpan(
            text: 'Interior paint has not been added to the estimate.',
          ),
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

    for (final entry in {
      'the primary button': ConfirmationDialog.primaryButtonKey,
      'the secondary button': ConfirmationDialog.secondaryButtonKey,
    }.entries) {
      final key = entry.value;
      testWidgets('a11y: ${entry.key} offers a tap action to assistive '
          'technology', (tester) async {
        await setupA11yTest(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(makeWidget(CoreTheme.light()));

        final label = key == ConfirmationDialog.primaryButtonKey
            ? 'Keep editing'
            : 'Discard';
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          matchesSemantics(label: label, isButton: true, hasTapAction: true),
        );
        handle.dispose();
      });

      testWidgets('a11y: ${entry.key} has a tap area of '
          'at least 48 by 48 dp', (tester) async {
        await setupA11yTest(tester);
        await tester.pumpWidget(makeWidget(CoreTheme.light()));

        expect(
          tester.getSize(find.byKey(key)),
          predicate<Size>((size) => size.width >= 48 && size.height >= 48),
        );
      });

      testWidgets('a11y: ${entry.key} grows its tap '
          'area with a 200 percent text size', (tester) async {
        await setupA11yTest(tester);
        await tester.pumpWidget(makeWidget(CoreTheme.light(), textScale: 2.0));

        expect(tester.getSize(find.byKey(key)).height, greaterThan(48));
      });
    }
  });
}

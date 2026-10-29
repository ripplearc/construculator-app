import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget makeTestableWidget({ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CalculatorPage(),
    );
  }

  group('CalculatorPage – accessibility', () {
    testWidgets(
      'close button meets label and contrast guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        // Tap target size is disabled: CoreUI's close button and keyboard drag
        // handle are designed at 40×40 and 12px tall respectively (per Figma
        // spec), both below the 48dp Android / 44pt iOS minimums. Tracked
        // separately in the CoreUI design system.
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.bySemanticsLabel(AppLocalizationsEn().closeButton),
          checkTapTargetSize: false,
        );
      },
    );

    testWidgets(
      'a suggestion chip and a conversion chip meet the label and contrast '
      'guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        Future<void> type(List<String> keys) async {
          for (final key in keys) {
            await tester.tap(find.byKey(ValueKey(key)));
            await tester.pump();
          }
          await tester.pump();
          await tester.pump(CoreSuggestionArea.animationDuration);
          await tester.pump();
        }

        // The themes are pumped by hand: the shared helper waits for the
        // page to settle, and a strip chip animates while it is on screen.
        // Tap target size is disabled as in the close-button test: the
        // guideline reads the whole page, where CoreUI's close button and
        // drag handle sit below 48dp by design (tracked in CoreUI).
        for (final theme in kA11yTestThemes) {
          // A Slope answer fills row 1 and leaves row 2 empty, so the
          // contrast guideline, which also reads the whole page, judges the
          // suggestion chips alone.
          await tester.pumpWidget(makeTestableWidget(theme: theme));
          await type(const ['calc_key_Slope', 'calc_key_seven']);
          await expectMeetsTapTargetAndLabelGuidelines(
            tester,
            find.byKey(CoreSuggestionArea.chipTestKey(0)),
            checkTapTargetSize: false,
          );

          // Text contrast is not checked on the conversions row: the
          // guideline samples its mini chips' text at the page background
          // (a 1.05 ratio) while the same chips pass CoreUI's own a11y
          // tests. CA-1377 takes it up in CoreUI.
          await tester.pumpWidget(makeTestableWidget(theme: theme));
          await type(const [
            'calc_key_Length',
            'calc_key_two',
            'calc_key_two',
            'calc_key_feet',
          ]);
          await expectMeetsTapTargetAndLabelGuidelines(
            tester,
            find.byKey(CoreSuggestionArea.conversionChipTestKey(0)),
            checkTapTargetSize: false,
            checkTextContrast: false,
          );
        }
      },
    );

    testWidgets(
      'an abbreviated key is read by its face, then its full name as a hint',
      (tester) async {
        final l10n = AppLocalizationsEn();
        await tester.pumpWidget(makeTestableWidget());

        final diag = tester.getSemantics(
          find.byKey(const ValueKey('calc_key_Diag')),
        );

        expect(diag.label, contains(l10n.calculatorKeyDiag));
        expect(diag.hint, equals(l10n.calculatorKeyDiagFullName));
      },
    );
  });
}

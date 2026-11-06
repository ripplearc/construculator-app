import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
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
      home: CalculatorPage(router: FakeAppRouter()),
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
      'the label row with a reading meets the contrast guideline in both '
      'themes',
      (tester) async {
        await setupA11yTest(tester);
        final l10n = AppLocalizationsEn();
        for (final theme in kA11yTestThemes) {
          await tester.pumpWidget(makeTestableWidget(theme: theme));
          for (final key in const [
            'calc_key_clearAll',
            'calc_key_Pitch',
            'calc_key_eight',
            'calc_key_decimal',
            'calc_key_four',
            'calc_key_five',
          ]) {
            await tester.tap(find.byKey(ValueKey(key)));
            await tester.pump();
          }
          await tester.pump(CoreSuggestionArea.animationDuration);
          await tester.pump();

          // Tap target size is disabled as in the close-button test.
          await expectMeetsTapTargetAndLabelGuidelines(
            tester,
            find.text(
              '${l10n.calculatorKeyPitch} · ${l10n.calculatorReadingDegrees}',
            ),
            checkTapTargetSize: false,
          );
        }
      },
    );

    testWidgets('the Read-as pill meets the label and contrast guidelines '
        'in both themes, and say what a tap does', (tester) async {
      await setupA11yTest(tester);
      final l10n = AppLocalizationsEn();
      Future<void> type(List<String> keys) async {
        for (final key in keys) {
          await tester.tap(find.byKey(ValueKey(key)));
          await tester.pump();
        }
        await tester.pump(CoreSuggestionArea.animationDuration);
        await tester.pump();
      }

      final pill = find.byKey(CoreDisplayArea.dependentKeyTestKey(0));
      // Tap target size is disabled as in the close-button test.
      for (final theme in kA11yTestThemes) {
        // The page keeps its bloc across the theme pumps, so each round
        // starts from an empty tape.
        await tester.pumpWidget(makeTestableWidget(theme: theme));
        await type(const [
          'calc_key_clearAll',
          'calc_key_Pitch',
          'calc_key_eight',
          'calc_key_decimal',
          'calc_key_four',
          'calc_key_five',
        ]);
        await expectMeetsTapTargetAndLabelGuidelines(
          tester,
          pill,
          checkTapTargetSize: false,
        );
        expect(tester.getSemantics(pill).hint, l10n.calculatorPillReadAsHint);
      }
    });

    testWidgets('a strip note meets the contrast guideline in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);
      final l10n = AppLocalizationsEn();
      for (final theme in kA11yTestThemes) {
        await tester.pumpWidget(makeTestableWidget(theme: theme));
        for (final key in const [
          'calc_key_clearAll',
          'calc_key_Pitch',
          'calc_key_nine',
          'calc_key_five',
        ]) {
          await tester.tap(find.byKey(ValueKey(key)));
          await tester.pump();
        }
        await tester.pump(CoreSuggestionArea.animationDuration);
        await tester.pump();

        // Tap target size is disabled as in the close-button test.
        await expectMeetsTapTargetAndLabelGuidelines(
          tester,
          find.text(l10n.calculatorNotePitchUnderRightAngle),
          checkTapTargetSize: false,
        );
      }
    });

    testWidgets(
      'the value row is a live region, so a screen reader announces the '
      'value as it changes (CA-1043)',
      (tester) async {
        await tester.pumpWidget(makeTestableWidget());

        await tester.tap(find.byKey(const ValueKey('calc_key_Length')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('calc_key_two')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('calc_key_four')));
        await tester.pump();

        // The chip reads "Length 24"; only the value row's node is "24".
        final valueRow = find.semantics.byLabel('24').evaluate().single;
        expect(valueRow.flagsCollection.isLiveRegion, isTrue);
      },
    );

    testWidgets(
      'a chip on the tape is read by the name of its key and its value, and '
      'a bracket chip in words that tell an open bracket from a closed one, '
      'led by the operator before it',
      (tester) async {
        final l10n = AppLocalizationsEn();
        await tester.pumpWidget(makeTestableWidget());

        await tester.tap(find.byKey(const ValueKey('calc_key_Length')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('calc_key_two')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('calc_key_feet')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('calc_key_add')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('calc_key_paren')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('calc_key_three')));
        await tester.pump();

        Finder chip(CoreCalculatorChipType type) => find.byWidgetPredicate(
          (widget) => widget is CoreCalculatorChip && widget.type == type,
        );
        final length = tester.getSemantics(
          chip(CoreCalculatorChipType.editable),
        );
        expect(length.label, contains(l10n.calculatorKeyLength));
        expect(length.label, contains('2ft'));
        expect(
          tester.getSemantics(chip(CoreCalculatorChipType.bracketOpen)).label,
          '+${l10n.calculatorBracketOpenSemantics('3')}',
        );

        await tester.tap(find.byKey(const ValueKey('calc_key_paren')));
        await tester.pump();

        expect(
          tester.getSemantics(chip(CoreCalculatorChipType.bracketClosed)).label,
          '+${l10n.calculatorBracketClosedSemantics('3')}',
        );
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

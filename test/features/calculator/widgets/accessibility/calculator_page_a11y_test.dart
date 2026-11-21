import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';
import '../../utils/calculator_test_harness.dart';

// TODO: [CA-1474] The Width, Rise and Slope function keys draw their text
// below 4.5:1 in the light theme (coreui 0.99.0 and later), and the page-wide
// text contrast guideline reads every key on the strip. Until CoreUI fixes the
// key colours, the light theme checks the text of the element under test
// alone (an icon's glyph is no text, as for the page-wide guideline); the
// dark theme still runs the
// page-wide guideline. https://ripplearc.youtrack.cloud/issue/CA-1474
Future<void> _expectLightThemeContrastOf(
  WidgetTester tester,
  ThemeData theme,
  Finder finder,
) async {
  if (theme.brightness == Brightness.dark) return;
  final text = find.descendant(
    of: finder,
    matching: find.byElementPredicate(
      (element) =>
          element.widget is RichText &&
          element.findAncestorWidgetOfExactType<Icon>() == null,
    ),
    matchRoot: true,
  );
  await expectLater(
    tester,
    meetsGuideline(CustomMinimumContrastGuideline(finder: text)),
  );
}

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
      home: CalculatorPage(calculatorBlocFactory: calculatorBlocForTests),
    );
  }

  group('CalculatorPage – accessibility', () {
    testWidgets(
      'close button meets label guidelines in both themes, and text contrast in dark',
      (tester) async {
        await setupA11yTest(tester);
        // Tap target size is disabled: CoreUI's close button and keyboard drag
        // handle are designed at 40×40 and 12px tall respectively (per Figma
        // spec), both below the 48dp Android / 44pt iOS minimums. Tracked
        // separately in the CoreUI design system.
        // TODO: [CA-1474] The Width and Rise function keys draw their text
        // below 4.5:1 in the light theme, so the text contrast check stays off
        // there until CoreUI fixes the key colors.
        // https://ripplearc.youtrack.cloud/issue/CA-1474
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.bySemanticsLabel(AppLocalizationsEn().closeButton),
          checkTapTargetSize: false,
          checkTextContrast: false,
        );

        await tester.pumpWidget(
          makeTestableWidget(theme: createTestThemeDark()),
        );
        await tester.pumpAndSettle();
        await expectMeetsTapTargetAndLabelGuidelines(
          tester,
          find.bySemanticsLabel(AppLocalizationsEn().closeButton),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      },
    );

    testWidgets(
      'the System of units pill meets the label and contrast guidelines in '
      'both themes, and says what a tap does',
      (tester) async {
        await setupA11yTest(tester);
        // Tap target size is disabled as in the close-button test: the
        // guideline reads the whole page, where CoreUI's close button and
        // drag handle sit below 48dp by design (tracked in CoreUI).
        for (final theme in kA11yTestThemes) {
          await tester.pumpWidget(makeTestableWidget(theme: theme));
          await tester.pumpAndSettle();
          await expectMeetsTapTargetAndLabelGuidelines(
            tester,
            find.byKey(CalculatorPage.unitsPillKey),
            checkTapTargetSize: false,
            checkTextContrast: theme.brightness == Brightness.dark,
          );
          await _expectLightThemeContrastOf(
            tester,
            theme,
            find.byKey(CalculatorPage.unitsPillKey),
          );
        }
        // The pill's own target is measured here.
        final pill = tester.getSize(find.byKey(CalculatorPage.unitsPillKey));
        expect(pill.height, greaterThanOrEqualTo(48));
        expect(pill.width, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(find.byKey(CalculatorPage.unitsPillKey)).hint,
          AppLocalizationsEn().calculatorUnitsSwitchToMetric,
        );
      },
    );

    testWidgets(
      'a setting sheet\'s options and Update meet the tap target and label '
      'guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        for (final theme in kA11yTestThemes) {
          await tester.pumpWidget(makeTestableWidget(theme: theme));
          BlocProvider.of<CalculatorBloc>(
            tester.element(find.byType(CoreKeyboard)),
          ).add(
            const CalculatorSettingSheetOpened(
              CalculatorSetting.fractionResolution,
            ),
          );
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Tap target size is disabled as in the close-button test (the
          // guideline reads the whole page, where CoreUI's close button sits
          // below 48dp), so Update and an option row are measured below.
          // Text contrast is not checked over the open sheet: the guideline
          // samples the sheet's text at the page behind it (a 1.05 ratio),
          // the sampling CA-1377 takes up; CorePreferenceOptionSheet's own
          // a11y tests in CoreUI cover its contrast.
          await expectMeetsTapTargetAndLabelGuidelines(
            tester,
            find.byKey(CalculatorPage.settingUpdateKey),
            checkTapTargetSize: false,
            checkTextContrast: false,
          );
          await expectMeetsTapTargetAndLabelGuidelines(
            tester,
            find.byKey(CalculatorPage.settingOptionKey('half')),
            checkTapTargetSize: false,
            checkTextContrast: false,
          );
          expect(
            tester.getSize(find.byKey(CalculatorPage.settingUpdateKey)).height,
            greaterThanOrEqualTo(48),
          );
          expect(
            tester
                .getSize(find.byKey(CalculatorPage.settingOptionKey('half')))
                .height,
            greaterThanOrEqualTo(48),
          );

          await tester.tap(
            find.bySemanticsLabel(AppLocalizationsEn().calculatorSettingBack),
          );
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
        }
      },
    );

    testWidgets('an abbreviated key is read by its full name', (tester) async {
      final l10n = AppLocalizationsEn();
      await tester.pumpWidget(makeTestableWidget());

      final diag = tester.getSemantics(
        find.byKey(const ValueKey('calc_key_Diag')),
      );

      expect(diag.label, equals(l10n.calculatorKeyDiagFullName));
      expect(diag.hint, isEmpty);
    });
  });
}

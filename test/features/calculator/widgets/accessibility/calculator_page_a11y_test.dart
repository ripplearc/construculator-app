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
      'the System of units pill meets the label and contrast guidelines in '
      'both themes, and says what a tap does',
      (tester) async {
        await setupA11yTest(tester);
        // Tap target size is disabled as in the close-button test: the
        // guideline reads the whole page, where CoreUI's close button and
        // drag handle sit below 48dp by design (tracked in CoreUI).
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(CalculatorPage.unitsPillKey),
          checkTapTargetSize: false,
        );
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

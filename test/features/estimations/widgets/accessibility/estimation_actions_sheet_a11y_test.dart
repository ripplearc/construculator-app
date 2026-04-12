import 'package:construculator/features/estimation/presentation/widgets/estimation_actions_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  BuildContext? buildContext;

  Widget createWidget({
    String estimationName = 'Test Estimation',
    bool isLocked = false,
    ValueNotifier<bool>? lockStatusNotifier,
    ThemeData? theme,
  }) {
    final notifier = lockStatusNotifier ?? ValueNotifier<bool>(isLocked);
    theme ??= createTestTheme();

    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          buildContext = context;
          return Scaffold(
            body: EstimationActionsSheet(
              estimationName: estimationName,
              lockStatusNotifier: notifier,
              onRename: () {},
              onFavourite: () {},
              onRemove: () {},
              onLockToggle: (_) {},
            ),
          );
        },
      ),
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  tearDown(() {
    buildContext = null;
  });

  Future<void> testA11yForTextElement(
    WidgetTester tester,
    String Function(AppLocalizations) getLabelText, {
    bool checkTapTargetSize = true,
    bool checkLabeledTapTarget = true,
  }) async {
    await setupA11yTest(tester);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
      tester,
      (theme) => createWidget(theme: theme),
      find.text(getLabelText(l10n())),
      checkTapTargetSize: checkTapTargetSize,
      checkLabeledTapTarget: checkLabeledTapTarget,
    );
  }

  group('EstimationActionsSheet accessibility', () {
    group('Quick Action Buttons', () {
      testWidgets('rename button meets a11y guidelines in both themes', (
        tester,
      ) async {
        await testA11yForTextElement(tester, (l10n) => l10n.renameAction);
      });

      testWidgets('favourite button meets a11y guidelines in both themes', (
        tester,
      ) async {
        await testA11yForTextElement(tester, (l10n) => l10n.favouriteAction);
      });

      testWidgets('remove button meets a11y guidelines in both themes', (
        tester,
      ) async {
        await testA11yForTextElement(tester, (l10n) => l10n.removeAction);
      });
    });

    group('Action List Items', () {
      testWidgets('copy action meets a11y guidelines in both themes', (
        tester,
      ) async {
        await testA11yForTextElement(
          tester,
          (l10n) => l10n.copyEstimationAction,
        );
      });

      testWidgets('share action meets a11y guidelines in both themes', (
        tester,
      ) async {
        await testA11yForTextElement(tester, (l10n) => l10n.shareExportAction);
      });

      testWidgets('logs action meets a11y guidelines in both themes', (
        tester,
      ) async {
        await testA11yForTextElement(tester, (l10n) => l10n.logsAction);
      });

      testWidgets('lock action meets a11y guidelines in both themes', (
        tester,
      ) async {
        await testA11yForTextElement(
          tester,
          (l10n) => l10n.lockEstimationAction,
        );
      });
    });

    group('Lock Toggle Integration', () {
      Future<void> verifySwitchSemanticLabels(
        WidgetTester tester,
        bool isLocked,
      ) async {
        await setupA11yTest(tester);

        await tester.pumpWidget(createWidget(isLocked: isLocked));
        await tester.pumpAndSettle();

        final switchWidget = tester.widget<CoreSwitch>(find.byType(CoreSwitch));
        expect(switchWidget.value, isLocked);
        expect(switchWidget.activeLabel, l10n().lockLabel);
        expect(switchWidget.inactiveLabel, l10n().unlockLabel);
      }

      testWidgets(
        'passes correct semantic labels to CoreSwitch when unlocked',
        (tester) async => await verifySwitchSemanticLabels(tester, false),
      );

      testWidgets(
        'passes correct semantic labels to CoreSwitch when locked',
        (tester) async => await verifySwitchSemanticLabels(tester, true),
      );
    });

    group('Sheet Structure', () {
      testWidgets('estimation name meets text contrast guidelines', (
        tester,
      ) async {
        await setupA11yTest(tester);

        const estimationName = 'Kitchen Renovation Project';

        await tester.pumpWidget(createWidget(estimationName: estimationName));
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => createWidget(theme: theme, estimationName: estimationName),
          find.text(estimationName),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      });
    });
  });
}

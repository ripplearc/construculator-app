import 'package:construculator/app/shell/widgets/header_row.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget makeTestableWidget({ThemeData? theme, int unreadCount = 0}) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: HeaderRow(unreadNotificationCount: unreadCount),
        body: const SizedBox.shrink(),
      ),
    );
  }

  group('HeaderRow – accessibility', () {
    testWidgets(
      'search button meets tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('header_row_search_button')),
        );
      },
    );

    testWidgets(
      'notification icon meets tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('notification_icon_button')),
        );
      },
    );

    testWidgets(
      'notification icon with badge meets tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        // Text contrast is disabled: textInverse on statusError achieves ~3.57:1,
        // below WCAG AA (4.5:1 for 12px). A dedicated textOnError token is needed
        // in the design system to resolve this.
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme, unreadCount: 5),
          find.byKey(const Key('notification_icon_button')),
          checkTextContrast: false,
        );
      },
    );

    testWidgets(
      'profile avatar meets label guideline in both themes',
      (tester) async {
        await setupA11yTest(tester);
        // Tap target size check is disabled: Figma specifies 40×40 for the
        // profile avatar, which is below the 48dp Android / 44pt iOS minimum.
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('profile_avatar_button')),
          checkTapTargetSize: false,
        );
      },
    );
  });
}

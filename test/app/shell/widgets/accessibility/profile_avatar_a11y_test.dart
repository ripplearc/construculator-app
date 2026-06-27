import 'package:construculator/app/shell/widgets/profile_avatar.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget makeTestableWidget({ThemeData? theme, String name = 'John'}) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: ProfileAvatar(name: name)),
      ),
    );
  }

  group('ProfileAvatar – accessibility', () {
    testWidgets(
      'meets label guideline for letter avatar in both themes',
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

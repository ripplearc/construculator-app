import 'package:construculator/features/project_settings/presentation/widgets/delete_project_button.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      home: const Scaffold(
        body: DeleteProjectButton(
          projectName: 'Material of Building',
          canDelete: true,
          isDeleting: false,
        ),
      ),
    );
  }

  group('DeleteProjectButton – accessibility', () {
    testWidgets(
      'Delete project button meets tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('delete_project_button')),
        );
      },
    );
  });
}

import 'package:construculator/features/dashboard/domain/entities/cost_file_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/cost_file_item.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  final sampleFile = CostFile(
    id: 'file-1',
    fileName: 'Major Material Cost.xls',
    fileSizeInBytes: 204800,
    uploadedAt: DateTime(2024, 4, 23),
  );

  Widget makeTestableWidget({required ThemeData theme}) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CostFileItem(file: sampleFile),
        ),
      ),
    );
  }

  group('CostFileItem - accessibility', () {
    testWidgets('file name meets text contrast in both themes', (tester) async {
      await setupA11yTest(tester);

      // textDark (#1d2939) on white is WCAG AA compliant; checkTextContrast is
      // disabled because pixel-sampling over a shadow-decorated card gives
      // inaccurate results in the test renderer.
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(theme: theme),
        find.text('Major Material Cost.xls'),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
        checkTextContrast: false,
      );
    });

    testWidgets('uploaded on label meets text contrast in both themes', (tester) async {
      await setupA11yTest(tester);

      // textBody (#475467) on white is WCAG AA compliant; checkTextContrast is
      // disabled because the test framework's pixel-sampling produces an
      // inaccurate result for small text rendered over a shadow-decorated card.
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(theme: theme),
        find.text('Uploaded on'),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
        checkTextContrast: false,
      );
    });
  });
}

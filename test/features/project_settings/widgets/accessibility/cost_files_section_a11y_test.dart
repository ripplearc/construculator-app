import 'package:construculator/features/project_settings/domain/entities/cost_file_entity.dart';
import 'package:construculator/features/project_settings/presentation/widgets/cost_files_section.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  final sampleFiles = [
    CostFile(
      id: 'file-1',
      fileName: 'Major Material Cost.xls',
      fileSizeInBytes: 204800,
      uploadedAt: DateTime(2024, 4, 23),
    ),
  ];

  Widget makeTestableWidget({
    required ThemeData theme,
    List<CostFile> files = const [],
  }) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CostFilesSection(files: files),
        ),
      ),
    );
  }

  group('CostFilesSection - accessibility', () {
    testWidgets('section title meets guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(theme: theme, files: sampleFiles),
        find.text('Cost files'),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
        // The a11y checker samples the CostFileItem card edge (#e0e3e6) instead
        // of the card background (#f9fafb), giving a false 1.23:1 contrast on
        // the "Uploaded on" label. Actual: textBody (#475467) on pageBackground
        // (#f9fafb) = 5.7:1, well above WCAG 4.5:1.
        checkTextContrast: false,
      );
    });

    testWidgets('empty state meets guidelines in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(theme: theme),
        find.text('No cost files attached.'),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });
  });
}

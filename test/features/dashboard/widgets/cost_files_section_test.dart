import 'package:construculator/features/dashboard/domain/entities/cost_file_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/cost_files_section.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  CostFile buildFile({String id = 'file-1', String fileName = 'Report.xls'}) {
    return CostFile(
      id: id,
      fileName: fileName,
      fileSizeInBytes: 204800,
      uploadedAt: DateTime(2024, 4, 23),
    );
  }

  Widget buildTestApp({required List<CostFile> files}) {
    return MaterialApp(
      theme: createTestTheme(),
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

  testWidgets('shows the section title', (tester) async {
    await tester.pumpWidget(buildTestApp(files: [buildFile()]));
    await tester.pump();

    expect(find.text('Cost files'), findsOneWidget);
  });

  testWidgets('renders one CostFileItem per file', (tester) async {
    await tester.pumpWidget(buildTestApp(files: [
      buildFile(id: '1', fileName: 'File A.xls'),
      buildFile(id: '2', fileName: 'File B.xls'),
    ]));
    await tester.pump();

    expect(find.text('File A.xls'), findsOneWidget);
    expect(find.text('File B.xls'), findsOneWidget);
  });

  testWidgets('shows empty state when no files are attached', (tester) async {
    await tester.pumpWidget(buildTestApp(files: []));
    await tester.pump();

    expect(find.text('No cost files attached.'), findsOneWidget);
  });
}

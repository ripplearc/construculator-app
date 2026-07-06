import 'package:construculator/features/dashboard/domain/entities/cost_file_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/cost_file_item.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  CostFile buildFile({
    String fileName = 'Major Material Cost.xls',
    int fileSizeInBytes = 204800,
    DateTime? uploadedAt,
  }) {
    return CostFile(
      id: 'file-1',
      fileName: fileName,
      fileSizeInBytes: fileSizeInBytes,
      uploadedAt: uploadedAt ?? DateTime(2024, 4, 23),
    );
  }

  Widget buildTestApp({required CostFile file}) {
    return MaterialApp(
      theme: createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CostFileItem(file: file),
        ),
      ),
    );
  }

  testWidgets('renders the file name', (tester) async {
    await tester.pumpWidget(buildTestApp(file: buildFile()));
    await tester.pump();

    expect(find.text('Major Material Cost.xls'), findsOneWidget);
  });

  testWidgets('renders formatted file size in KB', (tester) async {
    await tester.pumpWidget(buildTestApp(file: buildFile(fileSizeInBytes: 204800)));
    await tester.pump();

    expect(find.text('200KB'), findsOneWidget);
  });

  testWidgets('renders formatted file size in MB', (tester) async {
    await tester.pumpWidget(buildTestApp(file: buildFile(fileSizeInBytes: 1572864)));
    await tester.pump();

    expect(find.text('1.5MB'), findsOneWidget);
  });

  testWidgets('renders formatted file size in bytes for small files', (tester) async {
    await tester.pumpWidget(buildTestApp(file: buildFile(fileSizeInBytes: 512)));
    await tester.pump();

    expect(find.text('512B'), findsOneWidget);
  });

  testWidgets('renders the uploaded on label', (tester) async {
    await tester.pumpWidget(buildTestApp(file: buildFile()));
    await tester.pump();

    expect(find.text('Uploaded on'), findsOneWidget);
  });

  testWidgets('renders the formatted upload date', (tester) async {
    await tester.pumpWidget(
      buildTestApp(file: buildFile(uploadedAt: DateTime(2024, 4, 23))),
    );
    await tester.pump();

    expect(find.text('Apr 23, 2024'), findsOneWidget);
  });

  testWidgets('file name widget is configured to truncate with ellipsis', (tester) async {
    const longName = 'Very Long File Name That Should Be Truncated With Ellipsis.xlsx';
    await tester.pumpWidget(buildTestApp(file: buildFile(fileName: longName)));
    await tester.pump();

    final text = tester.widget<Text>(find.text(longName));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}

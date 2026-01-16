import 'package:construculator/features/estimation/presentation/widgets/delete_estimation_confirmation_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../screenshots/font_loader.dart';

void main() {
  final size = const Size(390, 420);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  group('DeleteEstimationConfirmationSheet Screenshot Tests', () {
    Future<void> pumpConfirmationSheet({
      required WidgetTester tester,
      required String estimationName,
      int? imagesAttachedCount,
      int? documentsAttachedCount,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DeleteEstimationConfirmationSheet(
              estimationName: estimationName,
              onConfirm: () {},
              onCancel: () {},
              imagesAttachedCount: imagesAttachedCount,
              documentsAttachedCount: documentsAttachedCount,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders with default state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpConfirmationSheet(
        tester: tester,
        estimationName: '2nd wall cost',
      );

      await expectLater(
        find.byType(DeleteEstimationConfirmationSheet),
        matchesGoldenFile(
          'goldens/delete_confirmation_sheet/${size.width}x${size.height}/delete_confirmation_sheet_default.png',
        ),
      );
    });

    testWidgets('renders with attachment counts', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpConfirmationSheet(
        tester: tester,
        estimationName: '2nd wall cost',
        imagesAttachedCount: 25,
        documentsAttachedCount: 5,
      );

      await expectLater(
        find.byType(DeleteEstimationConfirmationSheet),
        matchesGoldenFile(
          'goldens/delete_confirmation_sheet/${size.width}x${size.height}/delete_confirmation_sheet_with_attachments.png',
        ),
      );
    });

    testWidgets('renders with long estimation name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpConfirmationSheet(
        tester: tester,
        estimationName:
            'This is a very long estimation name that should be truncated with ellipsis to prevent layout overflow issues in the UI',
      );

      await expectLater(
        find.byType(DeleteEstimationConfirmationSheet),
        matchesGoldenFile(
          'goldens/delete_confirmation_sheet/${size.width}x${size.height}/delete_confirmation_sheet_long_name.png',
        ),
      );
    });
  });
}

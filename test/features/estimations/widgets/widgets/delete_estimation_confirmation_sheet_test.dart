import 'package:construculator/features/estimation/presentation/widgets/delete_estimation_confirmation_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  group('DeleteEstimationConfirmationSheet', () {
    const testEstimationName = 'Test Estimation';

    BuildContext? buildContext;

    Widget createWidget({
      String estimationName = testEstimationName,
      VoidCallback? onConfirm,
      VoidCallback? onCancel,
      int? imagesAttachedCount,
      int? documentsAttachedCount,
    }) {
      return MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            buildContext = context;
            return Scaffold(
              body: DeleteEstimationConfirmationSheet(
                estimationName: estimationName,
                onConfirm: onConfirm,
                onCancel: onCancel,
                imagesAttachedCount: imagesAttachedCount,
                documentsAttachedCount: documentsAttachedCount,
              ),
            );
          },
        ),
      );
    }

    AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

    group('Button callbacks', () {
      testWidgets('should call onConfirm when Yes, Delete button is tapped', (
        WidgetTester tester,
      ) async {
        bool onConfirmCalled = false;

        await tester.pumpWidget(
          createWidget(onConfirm: () => onConfirmCalled = true),
        );

        await tester.tap(find.text(l10n().yesDeleteButton));
        await tester.pump();

        expect(onConfirmCalled, isTrue);
      });

      testWidgets('should call onCancel when No, Keep button is tapped', (
        WidgetTester tester,
      ) async {
        bool onCancelCalled = false;

        await tester.pumpWidget(
          createWidget(onCancel: () => onCancelCalled = true),
        );

        await tester.tap(find.text(l10n().noKeepButton));
        await tester.pump();

        expect(onCancelCalled, isTrue);
      });

      testWidgets('should handle multiple button taps', (
        WidgetTester tester,
      ) async {
        int confirmCallCount = 0;

        await tester.pumpWidget(
          createWidget(onConfirm: () => confirmCallCount++),
        );

        await tester.tap(find.text(l10n().yesDeleteButton));
        await tester.pump();
        await tester.tap(find.text(l10n().yesDeleteButton));
        await tester.pump();

        expect(confirmCallCount, 2);
        expect(tester.takeException(), isNull);
      });
    });

    group('Attachment counts conditional rendering', () {
      testWidgets('should show only images count when documents is null', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidget(imagesAttachedCount: 10));

        expect(find.text(l10n().imagesAttachedCount(10)), findsOneWidget);
        expect(
          find.byKey(const Key('documents_attached_count_container')),
          findsNothing,
        );
      });

      testWidgets('should show only documents count when images is null', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidget(documentsAttachedCount: 3));

        expect(find.text(l10n().documentsAttachedCount(3)), findsOneWidget);
        expect(
          find.byKey(const Key('images_attached_count_container')),
          findsNothing,
        );
      });

      testWidgets('should not show attachment section when both are null', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidget());

        expect(
          find.byKey(const Key('images_attached_count_container')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('documents_attached_count_container')),
          findsNothing,
        );
      });

      testWidgets('should show zero counts when explicitly set to zero', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createWidget(imagesAttachedCount: 0, documentsAttachedCount: 0),
        );

        expect(find.text(l10n().imagesAttachedCount(0)), findsOneWidget);
        expect(find.text(l10n().documentsAttachedCount(0)), findsOneWidget);
      });
    });

    group('Edge cases', () {
      testWidgets('should handle empty estimation name', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidget(estimationName: ''));

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle large attachment counts', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createWidget(imagesAttachedCount: 9999, documentsAttachedCount: 9999),
        );

        expect(find.text(l10n().imagesAttachedCount(9999)), findsOneWidget);
        expect(find.text(l10n().documentsAttachedCount(9999)), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

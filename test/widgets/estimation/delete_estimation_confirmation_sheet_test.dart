import 'package:construculator/features/estimation/presentation/widgets/delete_estimation_confirmation_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  group('DeleteEstimationConfirmationSheet', () {
    const testEstimationName = 'Test Estimation';
    const customEstimationName = '2nd wall cost';
    const veryLongEstimationName =
        'This is a very long estimation name that should be truncated with ellipsis to prevent layout overflow issues in the UI';

    late Widget Function({
      String? estimationName,
      VoidCallback? onConfirm,
      VoidCallback? onCancel,
      int? imagesAttachedCount,
      int? documentsAttachedCount,
    }) createWidget;

    setUp(() {
      createWidget = ({
        String? estimationName,
        VoidCallback? onConfirm,
        VoidCallback? onCancel,
        int? imagesAttachedCount,
        int? documentsAttachedCount,
      }) {
        return MaterialApp(
          home: Scaffold(
            body: DeleteEstimationConfirmationSheet(
              estimationName: estimationName ?? testEstimationName,
              onConfirm: onConfirm ?? () {},
              onCancel: onCancel ?? () {},
              imagesAttachedCount: imagesAttachedCount,
              documentsAttachedCount: documentsAttachedCount,
            ),
          ),
        );
      };
    });

    testWidgets('should render with estimation name in title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidget(estimationName: customEstimationName),
      );

      expect(
        find.textContaining('Are you sure you want to remove'),
        findsOneWidget,
      );
      expect(find.textContaining(customEstimationName), findsOneWidget);
    });

    testWidgets('should render title and warning message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());

      expect(
        find.textContaining('Are you sure you want to remove'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'By removing you will lose all the Material, Labour and Equipment',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should render both action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('No, Keep'), findsOneWidget);
      expect(find.text('Yes, Delete'), findsOneWidget);
    });

    testWidgets('should call onConfirm when Yes, Delete button is tapped', (
      WidgetTester tester,
    ) async {
      bool onConfirmCalled = false;

      await tester.pumpWidget(
        createWidget(onConfirm: () => onConfirmCalled = true),
      );

      await tester.tap(find.text('Yes, Delete'));
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

      await tester.tap(find.text('No, Keep'));
      await tester.pump();

      expect(onCancelCalled, isTrue);
    });

    testWidgets('should display delete icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());

      final iconWidget = find.byWidgetPredicate(
        (widget) =>
            widget is CoreIconWidget && widget.icon == CoreIcons.delete,
      );

      expect(iconWidget, findsOneWidget);
    });

    testWidgets('should display attachment counts when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidget(
          imagesAttachedCount: 25,
          documentsAttachedCount: 5,
        ),
      );

      expect(find.text('25 images attached'), findsOneWidget);
      expect(find.text('5 documents attached'), findsOneWidget);
    });

    testWidgets('should display only images count when documents count is null',
        (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidget(imagesAttachedCount: 10),
      );

      expect(find.text('10 images attached'), findsOneWidget);
      expect(find.text('3 documents attached'), findsNothing);
    });

    testWidgets(
        'should display only documents count when images count is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidget(documentsAttachedCount: 3),
      );

      expect(find.text('3 documents attached'), findsOneWidget);
      expect(find.text('10 images attached'), findsNothing);
    });

    testWidgets('should not display attachment counts when both are null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('10 images attached'), findsNothing);
      expect(find.text('3 documents attached'), findsNothing);
      expect(find.text('0 images attached'), findsNothing);
      expect(find.text('0 documents attached'), findsNothing);
    });

    group('Edge cases tests for DeleteEstimationConfirmationSheet', () {
      testWidgets('should handle very long estimation names', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createWidget(estimationName: veryLongEstimationName),
        );

        expect(find.textContaining('This is a very long'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle empty estimation name', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidget(estimationName: ''));

        expect(tester.takeException(), isNull);
        expect(
          find.textContaining('Are you sure you want to remove'),
          findsOneWidget,
        );
      });

      testWidgets('should render correctly with all callbacks provided', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeleteEstimationConfirmationSheet(
                estimationName: testEstimationName,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.textContaining('Are you sure you want to remove'),
          findsOneWidget,
        );
      });

      testWidgets('buttons should not throw when tapped multiple times', (
        WidgetTester tester,
      ) async {
        int confirmCallCount = 0;
        int cancelCallCount = 0;

        await tester.pumpWidget(
          createWidget(
            onConfirm: () => confirmCallCount++,
            onCancel: () => cancelCallCount++,
          ),
        );

        await tester.tap(find.text('Yes, Delete'));
        await tester.pump();
        await tester.tap(find.text('Yes, Delete'));
        await tester.pump();

        expect(confirmCallCount, 2);

        await tester.tap(find.text('No, Keep'));
        await tester.pump();
        await tester.tap(find.text('No, Keep'));
        await tester.pump();

        expect(cancelCallCount, 2);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle zero attachment counts', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createWidget(
            imagesAttachedCount: 0,
            documentsAttachedCount: 0,
          ),
        );

        expect(find.text('0 images attached'), findsOneWidget);
        expect(find.text('0 documents attached'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle large attachment counts', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createWidget(
            imagesAttachedCount: 999,
            documentsAttachedCount: 888,
          ),
        );

        expect(find.text('999 images attached'), findsOneWidget);
        expect(find.text('888 documents attached'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('UI Structure tests', () {
      testWidgets('should have handle indicator at the top', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidget());

        // Check for the handle indicator container
        final handleIndicator = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).borderRadius != null,
        );

        expect(handleIndicator, findsAtLeastNWidgets(1));
      });

      testWidgets('should have circular delete icon container', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createWidget());

        // Check for the circular icon container
        final circularContainer = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle,
        );

        expect(circularContainer, findsOneWidget);
      });
    });
  });
}

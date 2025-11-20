import 'package:construculator/features/estimation/presentation/widgets/estimation_actions_sheet_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EstimationActionsSheet', () {
    const testEstimationName = 'Test Estimation';
    const customEstimationName = 'Wall cost';
    const veryLongEstimationName =
        'This is a very long estimation name that should be truncated with ellipsis to prevent layout overflow issues in the UI';

    late Widget Function({
      String? estimationName,
      bool isLocked,
      bool isFavourite,
      VoidCallback? onRename,
      VoidCallback? onFavourite,
      VoidCallback? onRemove,
      VoidCallback? onCopy,
      VoidCallback? onShare,
      VoidCallback? onLogs,
      VoidCallback? onLock,
    })
    createWidget;

    setUp(() {
      createWidget =
          ({
            String? estimationName,
            bool isLocked = false,
            bool isFavourite = false,
            VoidCallback? onRename,
            VoidCallback? onFavourite,
            VoidCallback? onRemove,
            VoidCallback? onCopy,
            VoidCallback? onShare,
            VoidCallback? onLogs,
            VoidCallback? onLock,
          }) {
            return MaterialApp(
              home: Scaffold(
                body: EstimationActionsSheetBody(
                  estimationName: estimationName ?? testEstimationName,
                  isFavourite: isFavourite,
                  onRename: onRename,
                  onFavourite: onFavourite,
                  onRemove: onRemove,
                ),
              ),
            );
          };
    });

    testWidgets('should render with estimation name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidget(estimationName: customEstimationName),
      );

      expect(find.text(customEstimationName), findsOneWidget);
    });

    testWidgets('should render all quick action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Favourite'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('should call onRename when rename button is tapped', (
      WidgetTester tester,
    ) async {
      bool onRenameCalled = false;

      await tester.pumpWidget(
        createWidget(onRename: () => onRenameCalled = true),
      );

      await tester.tap(find.text('Rename'));
      await tester.pump();

      expect(onRenameCalled, isTrue);
    });

    testWidgets('should display divider between sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(Divider), findsOneWidget);
    });

    group('Edge tases tests for EstimationActionsSheet', () {
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
      });
    });
  });
}

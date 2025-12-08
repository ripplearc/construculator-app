import 'package:construculator/features/estimation/presentation/widgets/estimation_actions_sheet_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test constants
const _testEstimationName = 'Test Estimation';
const _customEstimationName = 'Wall cost';
const _veryLongEstimationName =
    'This is a very long estimation name that should be truncated with ellipsis to prevent layout overflow issues in the UI';

// UI label constants matching the widget
const _renameLabel = 'Rename';
const _favouriteLabel = 'Favourite';
const _removeLabel = 'Remove';
const _copyLabel = 'Copy cost estimation';
const _shareLabel = 'Share / Export';
const _logsLabel = 'Logs';
const _lockLabel = 'Lock estimation';

void main() {
  group('EstimationActionsSheet', () {

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
                  estimationName: estimationName ?? _testEstimationName,
                  isFavourite: isFavourite,
                  isLocked: isLocked,
                  onRename: onRename,
                  onFavourite: onFavourite,
                  onRemove: onRemove,
                  onLock: onLock,
                  onCopy: onCopy,
                  onShare: onShare,
                  onLogs: onLogs,
                ),
              ),
            );
          };
    });

    testWidgets('should render with estimation name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidget(estimationName: _customEstimationName),
      );

      expect(find.text(_customEstimationName), findsOneWidget);
    });

    testWidgets('should render all quick action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());

      expect(find.text(_renameLabel), findsOneWidget);
      expect(find.text(_favouriteLabel), findsOneWidget);
      expect(find.text(_removeLabel), findsOneWidget);
    });

    testWidgets('should render all list action items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());

      expect(find.text(_copyLabel), findsOneWidget);
      expect(find.text(_shareLabel), findsOneWidget);
      expect(find.text(_logsLabel), findsOneWidget);
      expect(find.text(_lockLabel), findsOneWidget);
    });

    testWidgets('should call onRename when rename button is tapped', (
      WidgetTester tester,
    ) async {
      bool onRenameCalled = false;

      await tester.pumpWidget(
        createWidget(onRename: () => onRenameCalled = true),
      );

      await tester.tap(find.text(_renameLabel));
      await tester.pump();

      expect(onRenameCalled, isTrue);
    });

    testWidgets('should call onShare when share button is tapped', (
      WidgetTester tester,
    ) async {
      bool onShareCalled = false;

      await tester.pumpWidget(
        createWidget(onShare: () => onShareCalled = true),
      );

      await tester.tap(find.text(_shareLabel));
      await tester.pump();

      expect(onShareCalled, isTrue);
    });

    testWidgets('should call onCopy when copy button is tapped', (
      WidgetTester tester,
    ) async {
      bool onCopyCalled = false;

      await tester.pumpWidget(createWidget(onCopy: () => onCopyCalled = true));

      await tester.tap(find.text(_copyLabel));
      await tester.pump();

      expect(onCopyCalled, isTrue);
    });

    testWidgets('should call onFavourite when favourite button is tapped', (
      WidgetTester tester,
    ) async {
      bool onFavouriteCalled = false;

      await tester.pumpWidget(
        createWidget(onFavourite: () => onFavouriteCalled = true),
      );

      await tester.tap(find.text(_favouriteLabel));
      await tester.pump();

      expect(onFavouriteCalled, isTrue);
    });

    testWidgets('should call onRemove when remove button is tapped', (
      WidgetTester tester,
    ) async {
      bool onRemoveCalled = false;

      await tester.pumpWidget(
        createWidget(onRemove: () => onRemoveCalled = true),
      );

      await tester.tap(find.text(_removeLabel));
      await tester.pump();

      expect(onRemoveCalled, isTrue);
    });

    testWidgets('should call onLogs when logs button is tapped', (
      WidgetTester tester,
    ) async {
      bool onLogsCalled = false;

      await tester.pumpWidget(
        createWidget(onLogs: () => onLogsCalled = true),
      );

      await tester.tap(find.text(_logsLabel));
      await tester.pump();

      expect(onLogsCalled, isTrue);
    });

    testWidgets('should call onLock when lock button is tapped', (
      WidgetTester tester,
    ) async {
      bool onLockCalled = false;

      await tester.pumpWidget(
        createWidget(onLock: () => onLockCalled = true),
      );

      await tester.tap(find.text(_lockLabel));
      await tester.pump();

      expect(onLockCalled, isTrue);
    });

    testWidgets('should display divider between sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(Divider), findsOneWidget);
    });

    group('Edge cases tests for EstimationActionsSheet', () {
      testWidgets('should handle very long estimation names', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createWidget(estimationName: _veryLongEstimationName),
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

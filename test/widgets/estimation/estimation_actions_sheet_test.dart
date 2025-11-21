import 'package:construculator/features/estimation/presentation/widgets/estimation_actions_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  group('EstimationActionsSheet', () {
    const testEstimationName = 'Test Estimation';
    const customEstimationName = 'Wall cost';

    BuildContext? buildContext;

    Widget createWidget({
      String estimationName = testEstimationName,
      bool isLocked = false,
      VoidCallback? onRename,
      VoidCallback? onFavourite,
      VoidCallback? onRemove,
      VoidCallback? onCopy,
      VoidCallback? onShare,
      VoidCallback? onLogs,
      void Function(bool)? onLock,
    }) {
      return MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              buildContext = context;
              return EstimationActionsSheet(
                estimationName: estimationName,
                onRename: onRename,
                onFavourite: onFavourite,
                onRemove: onRemove,
                onCopy: onCopy,
                onShare: onShare,
                onLogs: onLogs,
                isLocked: isLocked,
                onLock: onLock,
              );
            },
          ),
        ),
      );
    }

    AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

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

      expect(find.text(l10n().renameAction), findsOneWidget);
      expect(find.text(l10n().favouriteAction), findsOneWidget);
      expect(find.text(l10n().removeAction), findsOneWidget);
    });

    testWidgets('should call onRemove when remove button is tapped', (
      WidgetTester tester,
    ) async {
      bool onRemoveCalled = false;

      await tester.pumpWidget(
        createWidget(onRemove: () => onRemoveCalled = true),
      );

      await tester.tap(find.text(l10n().removeAction));
      await tester.pump();

      expect(onRemoveCalled, isTrue);
    });

    testWidgets('should call onFavourite when favourite button is tapped', (
      WidgetTester tester,
    ) async {
      bool onFavouriteCalled = false;

      await tester.pumpWidget(
        createWidget(onFavourite: () => onFavouriteCalled = true),
      );

      await tester.tap(find.text(l10n().favouriteAction));
      await tester.pump();

      expect(onFavouriteCalled, isTrue);
    });

    testWidgets('should call onRename when rename button is tapped', (
      WidgetTester tester,
    ) async {
      bool onRenameCalled = false;

      await tester.pumpWidget(
        createWidget(onRename: () => onRenameCalled = true),
      );

      await tester.tap(find.text(l10n().renameAction));
      await tester.pump();

      expect(onRenameCalled, isTrue);
    });

    testWidgets('should call onLock when lock switch is toggled', (
      WidgetTester tester,
    ) async {
      bool? lockedValue;

      await tester.pumpWidget(
        createWidget(isLocked: false, onLock: (value) => lockedValue = value),
      );

      await tester.tap(find.byType(CoreSwitch));
      await tester.pump();

      expect(lockedValue, isTrue);
    });

    testWidgets('should display lock icon when estimation is locked', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget(isLocked: true));

      final lockIcon = find.byWidgetPredicate(
        (widget) => widget is CoreIconWidget && widget.icon == CoreIcons.lock,
      );
      expect(lockIcon, findsOneWidget);
    });

    testWidgets('should display unlock icon when estimation is not locked', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget(isLocked: false));

      final unlockIcon = find.byWidgetPredicate(
        (widget) => widget is CoreIconWidget && widget.icon == CoreIcons.unlock,
      );
      expect(unlockIcon, findsOneWidget);
    });

    testWidgets('should render all action list items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());

      expect(find.text(l10n().copyEstimationAction), findsOneWidget);
      expect(find.text(l10n().shareExportAction), findsOneWidget);
      expect(find.text(l10n().logsAction), findsOneWidget);
      expect(find.text(l10n().lockEstimationAction), findsOneWidget);
    });

    testWidgets('should call onCopy when copy action is tapped', (
      WidgetTester tester,
    ) async {
      bool onCopyCalled = false;

      await tester.pumpWidget(createWidget(onCopy: () => onCopyCalled = true));

      await tester.tap(find.text(l10n().copyEstimationAction));
      await tester.pump();

      expect(onCopyCalled, isTrue);
    });

    testWidgets('should call onShare when share action is tapped', (
      WidgetTester tester,
    ) async {
      bool onShareCalled = false;

      await tester.pumpWidget(
        createWidget(onShare: () => onShareCalled = true),
      );

      await tester.tap(find.text(l10n().shareExportAction));
      await tester.pump();

      expect(onShareCalled, isTrue);
    });

    testWidgets('should call onLogs when logs action is tapped', (
      WidgetTester tester,
    ) async {
      bool onLogsCalled = false;

      await tester.pumpWidget(createWidget(onLogs: () => onLogsCalled = true));

      await tester.tap(find.text(l10n().logsAction));
      await tester.pump();

      expect(onLogsCalled, isTrue);
    });
  });
}

import 'package:construculator/features/estimation/presentation/widgets/estimation_actions_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  group('EstimationActionsSheet', () {
    const testEstimationName = 'Test Estimation';
    const customEstimationName = 'Wall cost';
    const veryLongEstimationName =
        'This is a very long estimation name that should be truncated with ellipsis to prevent layout overflow issues in the UI';

    BuildContext? buildContext;

    Widget createWidget({
      String? estimationName,
      bool isLocked = false,
      bool isFavourite = false,
      VoidCallback? onRename,
      VoidCallback? onFavourite,
      VoidCallback? onRemove,
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
                estimationName: estimationName ?? testEstimationName,
                isFavourite: isFavourite,
                onRename: onRename,
                onFavourite: onFavourite,
                onRemove: onRemove,
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
    });
  });
}

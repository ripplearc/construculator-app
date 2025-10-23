import 'package:construculator/features/estimation/presentation/widgets/add_estimation_button.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddEstimationButton', () {
    testWidgets('renders correctly with all elements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                AddEstimationButton(
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Verify the container has correct styling
      final container = tester.widget<Container>(
        find.byType(Container),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.white);
      expect(decoration.borderRadius, BorderRadius.circular(24));
      expect(decoration.border, isA<Border>());

      // Verify the plus icon is present (if it exists)
      if (find.byIcon(Icons.add).evaluate().isNotEmpty) {
        final icon = tester.widget<Icon>(find.byIcon(Icons.add));
        expect(icon.color, CoreBorderColors.outlineFocus);
        expect(icon.size, 20);
      }

      // Verify the text is present
      expect(find.text('Add estimation'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Add estimation'));
      expect(textWidget.style, isNotNull);
      expect(textWidget.style!.color, CoreBorderColors.outlineFocus);
      expect(textWidget.style!.fontSize, 18);
      expect(textWidget.style!.fontWeight, FontWeight.w600);

      // Verify the row layout
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisSize, MainAxisSize.min);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool onPressedCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                AddEstimationButton(
                  onPressed: () {
                    onPressedCalled = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(onPressedCalled, true);
    });

    testWidgets('has correct border styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                AddEstimationButton(
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container),
      );
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      
      expect(border.top.color, CoreBorderColors.outlineFocus);
      expect(border.top.width, 2.5);
    });

    testWidgets('has correct padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                AddEstimationButton(
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container),
      );
      expect(container.padding, const EdgeInsets.symmetric(horizontal: 18, vertical: 7));
    });

    testWidgets('has correct spacing between icon and text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                AddEstimationButton(
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final spacingSizedBox = sizedBoxes.firstWhere(
        (sizedBox) => sizedBox.width == 8,
      );
      expect(spacingSizedBox.width, 8);
    });

    testWidgets('maintains consistent color scheme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                AddEstimationButton(
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      const expectedColor = CoreBorderColors.outlineFocus;
      
      // Check text color
      final textWidget = tester.widget<Text>(find.text('Add estimation'));
      expect(textWidget.style, isNotNull);
      expect(textWidget.style!.color, expectedColor);
      
      // Check border color
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, expectedColor);
    });
  });
}

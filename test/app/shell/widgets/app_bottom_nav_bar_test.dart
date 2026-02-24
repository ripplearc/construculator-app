import 'package:construculator/app/shell/widgets/app_bottom_nav_bar.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  Widget makeApp({
    required double screenWidth,
    int currentIndex = 0,
    ValueChanged<int>? onTap,
  }) {
    return MaterialApp(
      theme: createTestTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(size: Size(screenWidth, 800)),
        child: Scaffold(
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: currentIndex,
            onTap: onTap ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('Tab rendering and interaction', () {
    testWidgets('renders four tabs and calls onTap', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        makeApp(screenWidth: 400, onTap: (index) => tappedIndex = index),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Calculations'), findsOneWidget);
      expect(find.text('Cost Estimation'), findsOneWidget);
      expect(find.text('Members'), findsOneWidget);

      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 3);
    });

    testWidgets('highlights selected tab', (tester) async {
      await tester.pumpWidget(makeApp(screenWidth: 400, currentIndex: 2));

      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(navBar.currentIndex, 2);
    });
  });

  group('Adaptive sizing', () {
    testWidgets('uses small icons and fonts for narrow screens (width < 360)', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp(screenWidth: 320));

      final icons = tester.widgetList<Icon>(find.byType(Icon));

      // All icons should have size 20 on narrow screens
      for (final icon in icons) {
        expect(icon.size, 20.0);
      }

      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.selectedFontSize, 10.0);
      expect(navBar.unselectedFontSize, 10.0);
    });

    testWidgets(
      'uses medium icons and fonts for medium screens (360 <= width <= 600)',
      (tester) async {
        await tester.pumpWidget(makeApp(screenWidth: 400));

        final icons = tester.widgetList<Icon>(find.byType(Icon));

        for (final icon in icons) {
          expect(icon.size, 24.0);
        }

        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.selectedFontSize, 12.0);
        expect(navBar.unselectedFontSize, 12.0);
      },
    );

    testWidgets('uses large icons and fonts for wide screens (width > 600)', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp(screenWidth: 800));

      final icons = tester.widgetList<Icon>(find.byType(Icon));

      for (final icon in icons) {
        expect(icon.size, 28.0);
      }

      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.selectedFontSize, 13.0);
      expect(navBar.unselectedFontSize, 13.0);
    });

    testWidgets('boundary test: width exactly 360 uses medium sizing', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp(screenWidth: 360));

      final icons = tester.widgetList<Icon>(find.byType(Icon));

      for (final icon in icons) {
        expect(icon.size, 24.0);
      }
    });

    testWidgets('boundary test: width exactly 600 uses medium sizing', (
      tester,
    ) async {
      await tester.pumpWidget(makeApp(screenWidth: 600));

      final icons = tester.widgetList<Icon>(find.byType(Icon));

      for (final icon in icons) {
        expect(icon.size, 24.0);
      }
    });
  });
}

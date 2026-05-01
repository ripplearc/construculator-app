import 'package:construculator/features/estimation/presentation/widgets/shared_estimation_tile.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  final testDate = DateTime(2024, 3, 15, 14, 30);

  Widget createWidget({
    required EstimationTileData data,
    VoidCallback? onTap,
    VoidCallback? onMenuTap,
  }) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SharedEstimationTile(
          data: data,
          onTap: onTap ?? () {},
          onMenuTap: onMenuTap,
        ),
      ),
    );
  }

  group('SharedEstimationTile', () {
    group('Basic Rendering', () {
      testWidgets('renders all required elements', (tester) async {
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'Test', displayDate: testDate),
        ));

        expect(find.byKey(const Key('moneyIcon')), findsOneWidget);
        expect(find.byKey(const Key('calendarIcon')), findsOneWidget);
        expect(find.byKey(const Key('menuIcon')), findsOneWidget);
        expect(find.text('Test'), findsOneWidget);
        expect(find.text('Mar 15, 2024'), findsOneWidget);
        expect(find.text('2:30 PM'), findsOneWidget);
      });

      testWidgets('displays estimate name', (tester) async {
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'My Custom Estimate', displayDate: testDate),
        ));

        expect(find.text('My Custom Estimate'), findsOneWidget);
      });
    });

    group('Cost Display', () {
      testWidgets('formats cost with currency symbol', (tester) async {
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'E', displayDate: testDate, totalCost: 15000.50),
        ));

        expect(find.text('\$15,000.50'), findsOneWidget);
      });

      testWidgets('shows dash when totalCost is null', (tester) async {
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'E', displayDate: testDate, totalCost: null),
        ));

        expect(find.text('-'), findsOneWidget);
        expect(find.textContaining('\$'), findsNothing);
      });

      testWidgets('shows zero cost correctly', (tester) async {
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'E', displayDate: testDate, totalCost: 0.0),
        ));

        expect(find.text('\$0.00'), findsOneWidget);
      });

      testWidgets('formats large cost correctly', (tester) async {
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'E', displayDate: testDate, totalCost: 999999999.99),
        ));

        expect(find.text('\$999,999,999.99'), findsOneWidget);
      });
    });

    group('displayDate', () {
      testWidgets('shows date from displayDate', (tester) async {
        final date = DateTime(2024, 12, 1, 9, 15);
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'E', displayDate: date),
        ));

        expect(find.text('Dec 01, 2024'), findsOneWidget);
        expect(find.text('9:15 AM'), findsOneWidget);
      });

      testWidgets('different displayDate values produce different output', (tester) async {
        final createdAt = DateTime(2024, 1, 1, 8, 0);
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'E', displayDate: createdAt),
        ));
        expect(find.text('Jan 01, 2024'), findsOneWidget);

        final updatedAt = DateTime(2024, 6, 15, 17, 45);
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'E', displayDate: updatedAt),
        ));
        expect(find.text('Jun 15, 2024'), findsOneWidget);
      });
    });

    group('Menu semantics', () {
      testWidgets('includes semantics label on menu button when onMenuTap is provided', (tester) async {
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'Test Estimate', displayDate: testDate),
          onMenuTap: () {},
        ));

        final semantics = tester.getSemantics(find.byKey(const Key('menuIcon')));
        expect(semantics.label, contains('Test Estimate'));
      });

      testWidgets('excludes menu area from a11y tree when onMenuTap is null', (tester) async {
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'Test Estimate', displayDate: testDate),
          onMenuTap: null,
        ));

        final excludeWidgets = tester.widgetList(find.byType(ExcludeSemantics));
        expect(excludeWidgets, isNotEmpty);
      });
    });

    group('Card semantics', () {
      testWidgets('card has a Semantics widget with button:true', (tester) async {
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'Bridge Project', displayDate: testDate),
        ));

        final semanticsWidgets = tester.widgetList<Semantics>(find.byType(Semantics));
        final cardSemantics = semanticsWidgets.where(
          (s) => s.properties.label == 'Bridge Project' && (s.properties.button ?? false),
        );
        expect(cardSemantics, isNotEmpty);
      });
    });

    group('Tap Callbacks', () {
      testWidgets('calls onTap when tile body is tapped', (tester) async {
        bool tapped = false;
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'Test', displayDate: testDate),
          onTap: () => tapped = true,
        ));

        await tester.tap(find.text('Test'));
        expect(tapped, isTrue);
      });

      testWidgets('calls onMenuTap when menu icon is tapped', (tester) async {
        bool menuTapped = false;
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'Test', displayDate: testDate),
          onMenuTap: () => menuTapped = true,
        ));

        await tester.tap(find.byKey(const Key('menuIcon')));
        await tester.pump();

        expect(menuTapped, isTrue);
      });

      testWidgets('does not crash when onMenuTap is null and menu icon tapped', (tester) async {
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: 'Test', displayDate: testDate),
          onMenuTap: null,
        ));

        await tester.tap(find.byKey(const Key('menuIcon')));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles very long estimate names without overflow errors', (tester) async {
        const longName = 'This is a very long estimation name that might cause layout issues if not handled properly';
        await tester.pumpWidget(createWidget(
          data: _FakeData(estimateName: longName, displayDate: testDate),
        ));

        expect(find.text(longName), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

class _FakeData implements EstimationTileData {
  @override
  final String estimateName;

  @override
  final double? totalCost;

  @override
  final DateTime displayDate;

  const _FakeData({
    required this.estimateName,
    required this.displayDate,
    this.totalCost = 15000.50,
  });
}

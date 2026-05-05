import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/global_search/presentation/widgets/estimation_card_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  final testDate = DateTime(2024, 3, 15, 14, 30);

  CostEstimate makeEstimation({
    String estimateName = '2nd Wall Cost',
    double? totalCost = 15000.50,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final date = createdAt ?? testDate;
    return CostEstimate.defaultEstimate(
      estimateName: estimateName,
      totalCost: totalCost,
      createdAt: date,
      updatedAt: updatedAt ?? date,
    );
  }

  Widget createWidget({
    CostEstimate? estimation,
    String? ownerName,
    VoidCallback? onTap,
    VoidCallback? onMenuTap,
  }) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EstimationCard(
          estimation: estimation ?? makeEstimation(),
          ownerName: ownerName,
          onTap: onTap ?? () {},
          onMenuTap: onMenuTap,
        ),
      ),
    );
  }

  group('EstimationCard', () {
    group('Basic Rendering', () {
      testWidgets('renders all structural icons', (tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byKey(const Key('moneyIcon')), findsOneWidget);
        expect(find.byKey(const Key('calendarIcon')), findsOneWidget);
        expect(find.byKey(const Key('menuIcon')), findsOneWidget);
      });

      testWidgets('renders estimation name', (tester) async {
        await tester.pumpWidget(createWidget(estimation: makeEstimation(estimateName: '2nd Wall Cost')));

        expect(find.text('2nd Wall Cost'), findsOneWidget);
      });

      testWidgets('does not render personIcon when ownerName is null', (tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byKey(const Key('personIcon')), findsNothing);
      });

      testWidgets('renders custom estimation name', (tester) async {
        const name = 'Custom Search Result Estimate';
        await tester.pumpWidget(createWidget(estimation: makeEstimation(estimateName: name)));

        expect(find.text(name), findsOneWidget);
      });
    });

    group('Semantics', () {
      testWidgets('card body has button semantics with estimation name as label', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(createWidget(estimation: makeEstimation(estimateName: '2nd Wall Cost')));

        final semantics = tester.getSemantics(find.byKey(const Key('cardGestureDetector')));
        expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
        expect(semantics.label, contains('2nd Wall Cost'));
        handle.dispose();
      });

      testWidgets('menu button has labeled semantics when onMenuTap is provided', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(createWidget(onMenuTap: () {}));

        expect(
          tester.getSemantics(find.byKey(const Key('menuIcon'))),
          matchesSemantics(isButton: true, hasTapAction: true),
        );
        handle.dispose();
      });

      testWidgets('menu button is excluded from semantics when onMenuTap is null', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(createWidget(onMenuTap: null));

        expect(
          tester.getSemantics(find.byKey(const Key('menuIcon'))),
          isNot(matchesSemantics(isButton: true)),
        );
        handle.dispose();
      });
    });

    group('Date uses updatedAt', () {
      testWidgets('shows updatedAt date and time, not createdAt', (tester) async {
        final createdAt = DateTime(2023, 1, 1, 9, 0);
        final updatedAt = DateTime(2024, 6, 20, 17, 45);
        await tester.pumpWidget(
          createWidget(
            estimation: makeEstimation(createdAt: createdAt, updatedAt: updatedAt),
          ),
        );

        expect(find.text('Jun 20, 2024'), findsOneWidget);
        expect(find.text('5:45 PM'), findsOneWidget);
        expect(find.text('Jan 01, 2023'), findsNothing);
      });

      testWidgets('formats date as MMM dd, yyyy', (tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Mar 15, 2024'), findsOneWidget);
      });

      testWidgets('formats time as h:mm a (12-hour)', (tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('2:30 PM'), findsOneWidget);
      });

      testWidgets('handles midnight edge case', (tester) async {
        final midnight = DateTime(2024, 12, 1, 0, 0);
        await tester.pumpWidget(
          createWidget(
            estimation: makeEstimation(createdAt: midnight, updatedAt: midnight),
          ),
        );

        expect(find.text('Dec 01, 2024'), findsOneWidget);
        expect(find.text('12:00 AM'), findsOneWidget);
      });
    });

    group('Owner Row', () {
      testWidgets('does not render owner row when ownerName is null', (tester) async {
        await tester.pumpWidget(createWidget(ownerName: null));

        expect(find.byKey(const Key('personIcon')), findsNothing);
      });

      testWidgets('renders personIcon and owner text when ownerName is provided', (tester) async {
        await tester.pumpWidget(createWidget(ownerName: 'Jane Smith'));

        expect(find.byKey(const Key('personIcon')), findsOneWidget);
        expect(find.textContaining('Jane Smith'), findsOneWidget);
      });

      testWidgets('renders l10n-formatted owner label', (tester) async {
        await tester.pumpWidget(createWidget(ownerName: 'John Doe'));

        expect(find.text('Owner: John Doe'), findsOneWidget);
      });

      testWidgets('handles very long owner name without overflow error', (tester) async {
        const longOwner = 'Mr. Very Very Very Long Owner Name That Exceeds Available Width In The Card';
        await tester.pumpWidget(createWidget(ownerName: longOwner));

        expect(find.byKey(const Key('personIcon')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Cost Display', () {
      testWidgets('shows formatted cost', (tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text(r'$15,000.50'), findsOneWidget);
      });

      testWidgets('shows dash when totalCost is null', (tester) async {
        await tester.pumpWidget(
          createWidget(estimation: makeEstimation(totalCost: null)),
        );

        expect(find.text('-'), findsOneWidget);
        expect(find.textContaining(r'$'), findsNothing);
      });

      testWidgets('formats whole dollar amount with two decimal places', (tester) async {
        await tester.pumpWidget(
          createWidget(estimation: makeEstimation(totalCost: 1000.0)),
        );

        expect(find.text(r'$1,000.00'), findsOneWidget);
      });

      testWidgets('shows zero cost as \$0.00', (tester) async {
        await tester.pumpWidget(
          createWidget(estimation: makeEstimation(totalCost: 0.0)),
        );

        expect(find.text(r'$0.00'), findsOneWidget);
      });

      testWidgets('formats large cost with thousands separator', (tester) async {
        await tester.pumpWidget(
          createWidget(estimation: makeEstimation(totalCost: 999999999.99)),
        );

        expect(find.text(r'$999,999,999.99'), findsOneWidget);
      });
    });

    group('Tap Callbacks', () {
      testWidgets('calls onTap when card body is tapped', (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          createWidget(
            estimation: makeEstimation(estimateName: '2nd Wall Cost'),
            onTap: () => tapped = true,
          ),
        );

        await tester.tap(find.text('2nd Wall Cost'));

        expect(tapped, isTrue);
      });

      testWidgets('calls onMenuTap when menu icon is tapped', (tester) async {
        var menuTapped = false;
        await tester.pumpWidget(createWidget(onMenuTap: () => menuTapped = true));

        await tester.tap(find.byKey(const Key('menuIcon')));
        await tester.pump();

        expect(menuTapped, isTrue);
      });

      testWidgets('does not throw when onMenuTap is null and menu is tapped', (tester) async {
        await tester.pumpWidget(createWidget(onMenuTap: null));

        await tester.tap(find.byKey(const Key('menuIcon')));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles very long estimate name without overflow error', (tester) async {
        const longName =
            'This is a very long estimation name that might cause layout issues if not handled properly in the card widget';
        await tester.pumpWidget(
          createWidget(estimation: makeEstimation(estimateName: longName)),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('renders correctly with all optional fields provided', (tester) async {
        await tester.pumpWidget(
          createWidget(ownerName: 'Alice', onMenuTap: () {}),
        );

        expect(find.byKey(const Key('moneyIcon')), findsOneWidget);
        expect(find.byKey(const Key('calendarIcon')), findsOneWidget);
        expect(find.byKey(const Key('menuIcon')), findsOneWidget);
        expect(find.byKey(const Key('personIcon')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders correctly with all optional fields absent', (tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byKey(const Key('personIcon')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

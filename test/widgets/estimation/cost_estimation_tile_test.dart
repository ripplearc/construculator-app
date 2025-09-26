import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums/markup_type_enum.dart';
import 'package:construculator/features/estimation/domain/entities/enums/markup_value_type_enum.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostEstimationTile', () {
    late CostEstimate mockEstimation;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 3, 15, 14, 30); // March 15, 2024, 2:30 PM
      
      mockEstimation = CostEstimate(
        id: 'test-id',
        projectId: 'project-id',
        estimateName: 'Test Estimation',
        estimateDescription: 'Test description',
        creatorUserId: 'user-id',
        markupConfiguration: MarkupConfiguration(
          overallType: MarkupType.overall,
          overallValue: MarkupValue(
            type: MarkupValueType.percentage,
            value: 10.0,
          ),
        ),
        totalCost: 15000.50,
        lockStatus: const UnlockedStatus(),
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    Widget createWidget({
      CostEstimate? estimation,
      VoidCallback? onTap,
      VoidCallback? onMenuTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CostEstimationTile(
            estimation: estimation ?? mockEstimation,
            onTap: onTap,
            onMenuTap: onMenuTap,
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render with all required elements', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // Check if all icons are present
        expect(find.byType(Image), findsNWidgets(3)); // money, calendar, menu icons

        // Check if the estimate name is displayed
        expect(find.text('Test Estimation'), findsOneWidget);

        // Check if date and time are displayed
        expect(find.text('Mar 15, 2024'), findsOneWidget);
        expect(find.text('2:30 PM'), findsOneWidget);

        // Check if cost is displayed
        expect(find.text('\$15,000.50'), findsOneWidget);
      });

      testWidgets('should display correct estimate name', (WidgetTester tester) async {
        const customName = 'Custom Estimation Name';
        final customEstimation = CostEstimate(
          id: 'test-id',
          projectId: 'project-id',
          estimateName: customName,
          creatorUserId: 'user-id',
          markupConfiguration: MarkupConfiguration(
            overallType: MarkupType.overall,
            overallValue: MarkupValue(
              type: MarkupValueType.percentage,
              value: 10.0,
            ),
          ),
          lockStatus: const UnlockedStatus(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        await tester.pumpWidget(createWidget(estimation: customEstimation));

        expect(find.text(customName), findsOneWidget);
      });
    });

    group('Cost Display', () {
      testWidgets('should display cost when totalCost is provided', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('\$15,000.50'), findsOneWidget);
      });

      testWidgets('should display N/A when totalCost is null', (WidgetTester tester) async {
        final estimationWithoutCost = CostEstimate(
          id: 'test-id',
          projectId: 'project-id',
          estimateName: 'Test Estimation',
          creatorUserId: 'user-id',
          markupConfiguration: MarkupConfiguration(
            overallType: MarkupType.overall,
            overallValue: MarkupValue(
              type: MarkupValueType.percentage,
              value: 10.0,
            ),
          ),
          totalCost: null,
          lockStatus: const UnlockedStatus(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        await tester.pumpWidget(createWidget(estimation: estimationWithoutCost));

        expect(find.text('N/A'), findsOneWidget);
        expect(find.textContaining('\$'), findsNothing);
      });

      testWidgets('should format cost with correct currency symbol and decimals', (WidgetTester tester) async {
        final estimationWithWholeNumber = CostEstimate(
          id: 'test-id',
          projectId: 'project-id',
          estimateName: 'Test Estimation',
          creatorUserId: 'user-id',
          markupConfiguration: MarkupConfiguration(
            overallType: MarkupType.overall,
            overallValue: MarkupValue(
              type: MarkupValueType.percentage,
              value: 10.0,
            ),
          ),
          totalCost: 1000.0,
          lockStatus: const UnlockedStatus(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        await tester.pumpWidget(createWidget(estimation: estimationWithWholeNumber));

        expect(find.text('\$1,000.00'), findsOneWidget);
      });
    });

    group('Date and Time Formatting', () {
      testWidgets('should format date correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('Mar 15, 2024'), findsOneWidget);
      });

      testWidgets('should format time correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.text('2:30 PM'), findsOneWidget);
      });

      testWidgets('should handle different date formats', (WidgetTester tester) async {
        final differentDate = DateTime(2024, 12, 1, 9, 15); // Dec 1, 2024, 9:15 AM
        final estimationWithDifferentDate = CostEstimate(
          id: 'test-id',
          projectId: 'project-id',
          estimateName: 'Test Estimation',
          creatorUserId: 'user-id',
          markupConfiguration: MarkupConfiguration(
            overallType: MarkupType.overall,
            overallValue: MarkupValue(
              type: MarkupValueType.percentage,
              value: 10.0,
            ),
          ),
          totalCost: 1000.0,
          lockStatus: const UnlockedStatus(),
          createdAt: differentDate,
          updatedAt: differentDate,
        );

        await tester.pumpWidget(createWidget(estimation: estimationWithDifferentDate));

        expect(find.text('Dec 01, 2024'), findsOneWidget);
        expect(find.text('9:15 AM'), findsOneWidget);
      });
    });

    group('Tap Callbacks', () {
      testWidgets('should call onTap when tile is tapped', (WidgetTester tester) async {
        bool onTapCalled = false;
        
        await tester.pumpWidget(createWidget(
          onTap: () => onTapCalled = true,
        ));

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        expect(onTapCalled, isTrue);
      });

      testWidgets('should call onMenuTap when menu button is tapped', (WidgetTester tester) async {
        bool onMenuTapCalled = false;
        
        await tester.pumpWidget(createWidget(
          onMenuTap: () => onMenuTapCalled = true,
        ));

        // Find the menu button (third Image widget - money, calendar, menu)
        final menuButton = find.byType(Image).at(1);
        await tester.tap(menuButton);
        await tester.pump();

        expect(onMenuTapCalled, isTrue);
      });

      testWidgets('should not crash when onTap is null', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(onTap: null));

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        // Should not throw any exceptions
        expect(tester.takeException(), isNull);
      });

      testWidgets('should not crash when onMenuTap is null', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(onMenuTap: null));

        final menuButton = find.byType(Image).at(2);
        await tester.tap(menuButton);
        await tester.pump();

        // Should not throw any exceptions
        expect(tester.takeException(), isNull);
      });
    });

    group('UI Elements', () {
      testWidgets('should display all required icons', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // Check for money icon
        final moneyIcon = find.byType(Image).at(0);
        expect(moneyIcon, findsOneWidget);

        // Check for calendar icon
        final calendarIcon = find.byType(Image).at(1);
        expect(calendarIcon, findsOneWidget);

        // Check for menu icon
        final menuIcon = find.byType(Image).at(2);
        expect(menuIcon, findsOneWidget);
      });

      testWidgets('should have correct spacing and layout', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // Check if SizedBox widgets are present for spacing
        expect(find.byType(SizedBox), findsWidgets);

        // Check if Spacer is present in bottom row
        expect(find.byType(Spacer), findsOneWidget);

        // Check if Container with separator dot is present
        expect(find.byWidgetPredicate(
          (widget) => widget is Container && 
                      widget.decoration is BoxDecoration &&
                      (widget.decoration as BoxDecoration).shape == BoxShape.circle,
        ), findsOneWidget);
      });

      testWidgets('should have correct text styles', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // Check estimate name text style
        final estimateNameText = find.text('Test Estimation');
        expect(estimateNameText, findsOneWidget);

        // Check date text style
        final dateText = find.text('Mar 15, 2024');
        expect(dateText, findsOneWidget);

        // Check time text style
        final timeText = find.text('2:30 PM');
        expect(timeText, findsOneWidget);

        // Check cost text style
        final costText = find.text('\$15,000.50');
        expect(costText, findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle very long estimate names', (WidgetTester tester) async {
        const longName = 'This is a very long estimation name that might cause layout issues if not handled properly';
        final estimationWithLongName = CostEstimate(
          id: 'test-id',
          projectId: 'project-id',
          estimateName: longName,
          creatorUserId: 'user-id',
          markupConfiguration: MarkupConfiguration(
            overallType: MarkupType.overall,
            overallValue: MarkupValue(
              type: MarkupValueType.percentage,
              value: 10.0,
            ),
          ),
          totalCost: 1000.0,
          lockStatus: const UnlockedStatus(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        await tester.pumpWidget(createWidget(estimation: estimationWithLongName));

        expect(find.text(longName), findsOneWidget);
        // Should not throw any exceptions
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle zero cost', (WidgetTester tester) async {
        final estimationWithZeroCost = CostEstimate(
          id: 'test-id',
          projectId: 'project-id',
          estimateName: 'Test Estimation',
          creatorUserId: 'user-id',
          markupConfiguration: MarkupConfiguration(
            overallType: MarkupType.overall,
            overallValue: MarkupValue(
              type: MarkupValueType.percentage,
              value: 10.0,
            ),
          ),
          totalCost: 0.0,
          lockStatus: const UnlockedStatus(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        await tester.pumpWidget(createWidget(estimation: estimationWithZeroCost));

        expect(find.text('\$0.00'), findsOneWidget);
      });

      testWidgets('should handle very large costs', (WidgetTester tester) async {
        final estimationWithLargeCost = CostEstimate(
          id: 'test-id',
          projectId: 'project-id',
          estimateName: 'Test Estimation',
          creatorUserId: 'user-id',
          markupConfiguration: MarkupConfiguration(
            overallType: MarkupType.overall,
            overallValue: MarkupValue(
              type: MarkupValueType.percentage,
              value: 10.0,
            ),
          ),
          totalCost: 999999999.99,
          lockStatus: const UnlockedStatus(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        await tester.pumpWidget(createWidget(estimation: estimationWithLargeCost));

        expect(find.text('\$999,999,999.99'), findsOneWidget);
      });
    });
  });
}

import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:construculator/features/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/features/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostEstimationTile', () {
    late CostEstimate testEstimation;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.parse('2024-03-15 14:30:00');
      
      testEstimation = CostEstimate(
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
      estimation ??= testEstimation;
      return MaterialApp(
        home: Scaffold(
          body: CostEstimationTile(
            estimation: estimation,
            onTap: onTap,
            onMenuTap: onMenuTap,
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render with all required elements', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byKey(const Key('moneyIcon')), findsOneWidget);
        expect(find.byKey(const Key('calendarIcon')), findsOneWidget);
        expect(find.byKey(const Key('menuIcon')), findsOneWidget);

        expect(find.text('Test Estimation'), findsOneWidget);

        expect(find.text('Mar 15, 2024'), findsOneWidget);
        expect(find.text('2:30 PM'), findsOneWidget);

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

        expect(find.text('-'), findsOneWidget);
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
        final differentDate = DateTime.parse('2024-12-01 09:15:00');
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

        final menuButton = find.byKey(const Key('menuIcon'));
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

        final menuButton = find.byKey(const Key('menuIcon'));
        await tester.tap(menuButton);
        await tester.pump();

        // Should not throw any exceptions
        expect(tester.takeException(), isNull);
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

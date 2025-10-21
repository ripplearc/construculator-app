import 'package:construculator/features/estimation/presentation/pages/cost_estimation_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CostEstimationDetailsPage', () {
    const testEstimationId = 'test-estimation-id';

    Widget createTestWidget() {
      return MaterialApp(
        home: CostEstimationDetailsPage(estimationId: testEstimationId),
      );
    }

    testWidgets('should display coming soon message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Cost estimation details will be available in a future update.'), findsOneWidget);
    });

    testWidgets('should display estimation ID', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Estimation ID: $testEstimationId'), findsOneWidget);
    });
  });
}

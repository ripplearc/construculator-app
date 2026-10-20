import 'package:construculator/features/estimation/presentation/widgets/underline_text_field.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());

  tearDown(() => controller.dispose());

  Future<void> pumpField(WidgetTester tester, {bool largeValue = false}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: CoreTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => UnderlineTextField(
                label: 'Amount',
                controller: controller,
                valueStyle: largeValue
                    ? context.textTheme.headlineMediumRegular
                    : null,
              ),
            ),
          ),
        ),
      );

  double labelToValueGap(WidgetTester tester) =>
      tester.getTopLeft(find.byType(TextField)).dy -
      tester.getBottomLeft(find.text('Amount')).dy;

  double valueToRuleGap(WidgetTester tester) =>
      tester.getTopLeft(find.byType(AnimatedContainer)).dy -
      tester.getBottomLeft(find.byType(TextField)).dy;

  group('UnderlineTextField value placement', () {
    testWidgets('a default value sits 3 dp under the label', (tester) async {
      await pumpField(tester);

      expect(labelToValueGap(tester), 3);
    });

    testWidgets('a larger value style sits 5 dp lower under the label', (
      tester,
    ) async {
      await pumpField(tester, largeValue: true);

      expect(labelToValueGap(tester), 8);
    });

    testWidgets('a larger value style keeps 5 dp less above the rule', (
      tester,
    ) async {
      await pumpField(tester);
      final defaultGap = valueToRuleGap(tester);

      await pumpField(tester, largeValue: true);

      expect(valueToRuleGap(tester), defaultGap - 5);
    });
  });
}

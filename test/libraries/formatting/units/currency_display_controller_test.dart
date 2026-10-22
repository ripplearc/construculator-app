import 'package:construculator/libraries/formatting/currency_display_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FocusNode focusNode;
  late CurrencyDisplayController controller;

  setUp(() {
    focusNode = FocusNode();
    controller = CurrencyDisplayController(focusNode: focusNode);
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Future<String> paintedText(WidgetTester tester) async {
    late String painted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                key: const Key('field'),
                controller: controller,
                focusNode: focusNode,
              ),
              Builder(
                builder: (context) {
                  painted = controller
                      .buildTextSpan(context: context, withComposing: false)
                      .toPlainText();
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
    return painted;
  }

  testWidgets('paints a whole number as currency while unfocused', (
    tester,
  ) async {
    controller.text = '400';

    expect(await paintedText(tester), '\$400.00');
  });

  testWidgets('paints a decimal as currency with two decimals', (tester) async {
    controller.text = '145.5';

    expect(await paintedText(tester), '\$145.50');
  });

  testWidgets('keeps the text itself a plain number', (tester) async {
    controller.text = '400';
    await paintedText(tester);

    expect(controller.text, '400');
    expect(double.tryParse(controller.text), 400);
  });

  testWidgets('paints the raw number once the field is focused', (
    tester,
  ) async {
    controller.text = '400';
    await paintedText(tester);

    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();

    expect(await paintedText(tester), '400');
  });

  testWidgets('paints currency again after the field loses focus', (
    tester,
  ) async {
    controller.text = '400';
    await paintedText(tester);
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();

    focusNode.unfocus();
    await tester.pump();

    expect(await paintedText(tester), '\$400.00');
  });

  testWidgets('paints text that is not a number as typed', (tester) async {
    controller.text = '4x';

    expect(await paintedText(tester), '4x');
  });

  testWidgets('paints nothing for empty text', (tester) async {
    expect(await paintedText(tester), '');
  });

  testWidgets('puts the caret at the end of the number when the field gains '
      'focus', (tester) async {
    controller.text = '145';
    await paintedText(tester);

    focusNode.requestFocus();
    await tester.pump();

    expect(controller.selection, const TextSelection.collapsed(offset: 3));
  });

  testWidgets('keeps the number the user typed when the field loses focus', (
    tester,
  ) async {
    controller.text = '145';
    await paintedText(tester);
    focusNode.requestFocus();
    await tester.pump();

    focusNode.unfocus();
    await tester.pump();

    expect(controller.text, '145');
  });
}

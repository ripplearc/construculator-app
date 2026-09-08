import 'package:construculator/features/dashboard/presentation/widgets/project_selection_indicator.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  Widget buildTestApp({required Widget child}) {
    return MaterialApp(
      theme: createTestTheme(),
      home: Scaffold(
        body: Material(
          child: ProjectSelectionIndicator(child: child),
        ),
      ),
    );
  }

  Ink inkOf(WidgetTester tester) {
    return tester.widget<Ink>(
      find.descendant(
        of: find.byType(ProjectSelectionIndicator),
        matching: find.byType(Ink),
      ),
    );
  }

  testWidgets('renders its child', (tester) async {
    await tester.pumpWidget(
      buildTestApp(child: const Text('hello')),
    );
    await tester.pump();

    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('has a 3 px border', (tester) async {
    await tester.pumpWidget(
      buildTestApp(child: const SizedBox()),
    );
    await tester.pump();

    final border = (inkOf(tester).decoration as BoxDecoration).border as Border;
    expect(border.top.width, 3);
  });

  testWidgets('uses the lineHighlight color on the border', (tester) async {
    await tester.pumpWidget(
      buildTestApp(child: const SizedBox()),
    );
    await tester.pump();

    final border = (inkOf(tester).decoration as BoxDecoration).border as Border;
    final expectedColor = tester
        .element(find.byType(ProjectSelectionIndicator))
        .colorTheme
        .lineHighlight;
    expect(border.top.color, expectedColor);
  });

  testWidgets('uses the card border radius', (tester) async {
    await tester.pumpWidget(
      buildTestApp(child: const SizedBox()),
    );
    await tester.pump();

    final decoration = inkOf(tester).decoration as BoxDecoration;
    expect(
      decoration.borderRadius,
      BorderRadius.circular(CoreSpacing.space3),
    );
  });
}

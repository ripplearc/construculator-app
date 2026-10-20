import 'package:construculator/features/estimation/presentation/widgets/added_to_estimate_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  testWidgets('announces the message as a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        home: const Material(
          child: AddedToEstimateToast(message: 'Added to Bedroom 2'),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(AddedToEstimateToast));

    expect(node.label, 'Added to Bedroom 2');
    expect(node.flagsCollection.isLiveRegion, isTrue);
    expect(node.flagsCollection.isButton, isFalse);
    handle.dispose();
  });
}

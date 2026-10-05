import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  Future<SemanticsNode> pumpAndReadPanel(
    WidgetTester tester, {
    AddToEstimateBlock? block,
  }) async {
    await setupA11yTest(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AddToEstimatePanel(
            key: const Key('panel'),
            lineTotal: 520,
            deliveryFee: null,
            estimateName: 'Bedroom 2',
            estimateTotal: 2993.62,
            block: block,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getSemantics(find.byKey(const Key('panel')));
  }

  group('AddToEstimatePanel – accessibility', () {
    testWidgets('a11y: the totals are read as one live region', (tester) async {
      final semantics = await pumpAndReadPanel(tester);

      expect(semantics.label, contains('Adds to this estimate'));
      expect(semantics.label, contains(r'$520.00'));
      expect(semantics.label, contains(r'$3,513.62'));
      expect(semantics.flagsCollection.isLiveRegion, isTrue);
    });

    testWidgets('a11y: a blocked panel reads why it has no total', (
      tester,
    ) async {
      final semantics = await pumpAndReadPanel(
        tester,
        block: const AddToEstimateBlock(
          note: 'Needs a rate before it can total',
          buttonLabel: 'Enter a rate to continue',
        ),
      );

      expect(semantics.label, contains('Needs a rate before it can total'));
    });
  });
}

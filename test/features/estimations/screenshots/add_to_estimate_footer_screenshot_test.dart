import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_footer.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(412, 236);
  const footerBoundaryKey = Key('footer_boundary');
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpFooter(
    WidgetTester tester,
    ThemeData theme, {
    double lineTotal = 520,
    double? deliveryFee,
    AddToEstimateBlock? block,
    bool isSubmitting = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Material(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RepaintBoundary(
                key: footerBoundaryKey,
                child: ColoredBox(
                  color: context.colorTheme.pageBackground,
                  child: AddToEstimateFooter(
                    lineTotal: lineTotal,
                    deliveryFee: deliveryFee,
                    estimateName: 'Bedroom 2',
                    estimateTotal: 2993.62,
                    block: block,
                    isSubmitting: isSubmitting,
                    onAdd: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expectGolden(WidgetTester tester, String name, String suffix) =>
      expectLater(
        find.byType(AddToEstimateFooter),
        matchesGoldenFile('goldens/add_to_estimate_footer/$name$suffix.png'),
      );

  screenshotThemeGroups('AddToEstimateFooter Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('ready, no delivery fee', (tester) async {
      await pumpFooter(tester, theme);
      await expectGolden(tester, 'ready', suffix);
    });

    testWidgets('ready, with delivery fee', (tester) async {
      await pumpFooter(tester, theme, lineTotal: 605, deliveryFee: 85);
      await expectGolden(tester, 'ready_with_delivery', suffix);
    });

    testWidgets('submitting', (tester) async {
      await pumpFooter(tester, theme, isSubmitting: true);
      await expectGolden(tester, 'submitting', suffix);
    });

    const blocks = {
      'name': (
        'Needs a name before it can total',
        'Enter an equipment name to continue',
      ),
      'duration': (
        'Needs a duration before it can total',
        'Enter a duration to continue',
      ),
      'zero_duration': (
        'Needs a duration above zero before it can total',
        'Fix the duration to continue',
      ),
      'rate': ('Needs a rate before it can total', 'Enter a rate to continue'),
      'amount': (
        'Needs an amount before it can total',
        'Enter an amount to continue',
      ),
    };
    for (final entry in blocks.entries) {
      testWidgets('blocked: ${entry.key}', (tester) async {
        await pumpFooter(
          tester,
          theme,
          block: AddToEstimateBlock(
            note: entry.value.$1,
            buttonLabel: entry.value.$2,
          ),
        );
        await expectGolden(tester, 'blocked_${entry.key}', suffix);
      });
    }
  });
}

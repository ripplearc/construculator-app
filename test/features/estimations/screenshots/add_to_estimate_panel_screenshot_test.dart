import 'package:construculator/features/estimation/presentation/widgets/add_to_estimate_panel.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(412, 150);
  const panelBoundaryKey = Key('panel_boundary');
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpPanel(
    WidgetTester tester,
    ThemeData theme, {
    double lineTotal = 520,
    double? deliveryFee,
    String estimateName = 'Bedroom 2',
    AddToEstimateBlock? block,
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
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                key: panelBoundaryKey,
                child: ColoredBox(
                  color: context.colorTheme.pageBackground,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AddToEstimatePanel(
                      lineTotal: lineTotal,
                      deliveryFee: deliveryFee,
                      estimateName: estimateName,
                      estimateTotal: 2993.62,
                      block: block,
                    ),
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
        find.byKey(panelBoundaryKey),
        matchesGoldenFile('goldens/add_to_estimate_panel/$name$suffix.png'),
      );

  screenshotThemeGroups('AddToEstimatePanel Screenshot Tests', (theme, suffix) {
    testWidgets('ready, no delivery fee', (tester) async {
      await pumpPanel(tester, theme);
      await expectGolden(tester, 'ready', suffix);
    });

    testWidgets('ready, with delivery fee', (tester) async {
      await pumpPanel(tester, theme, lineTotal: 605, deliveryFee: 85);
      await expectGolden(tester, 'ready_with_delivery', suffix);
    });

    testWidgets('ready, with a long estimate name', (tester) async {
      await pumpPanel(
        tester,
        theme,
        estimateName: 'Master bedroom, flooring, drywall and trim',
      );
      await expectGolden(tester, 'ready_long_name', suffix);
    });

    const blocks = {
      'name': 'Needs a name before it can total',
      'duration': 'Needs a duration before it can total',
      'zero_duration': 'Needs a duration above zero before it can total',
      'rate': 'Needs a rate before it can total',
      'amount': 'Needs an amount before it can total',
    };
    for (final entry in blocks.entries) {
      testWidgets('blocked: ${entry.key}', (tester) async {
        await pumpPanel(
          tester,
          theme,
          block: AddToEstimateBlock(note: entry.value, buttonLabel: ''),
        );
        await expectGolden(tester, 'blocked_${entry.key}', suffix);
      });
    }
  });
}

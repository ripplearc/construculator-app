import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_of_measurement_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390.0, 80.0);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpWidget({
    required WidgetTester tester,
    required ThemeData theme,
    bool fromCostFile = false,
    Unit? selectedUnit,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: UnitOfMeasurementField(
              fromCostFile: fromCostFile,
              selectedUnit: selectedUnit,
              onUnitSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('UnitOfMeasurementField Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('manual empty state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: theme);
      await expectLater(
        find.byType(UnitOfMeasurementField),
        matchesGoldenFile(
          'goldens/unit_of_measurement_field/${size.width}x${size.height}/manual_empty$suffix.png',
        ),
      );
    });

    testWidgets('manual selected state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, selectedUnit: Unit.kilograms, theme: theme);
      await expectLater(
        find.byType(UnitOfMeasurementField),
        matchesGoldenFile(
          'goldens/unit_of_measurement_field/${size.width}x${size.height}/manual_selected$suffix.png',
        ),
      );
    });
  });
}

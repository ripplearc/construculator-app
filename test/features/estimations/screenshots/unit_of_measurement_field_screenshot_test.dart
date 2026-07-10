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
    bool fromCostFile = false,
    Unit? selectedUnit,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
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

  group('UnitOfMeasurementField Screenshot Tests', () {
    testWidgets('manual empty state in light theme', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester);
      await expectLater(
        find.byType(UnitOfMeasurementField),
        matchesGoldenFile(
          'goldens/unit_of_measurement_field/${size.width}x${size.height}/manual_empty_light.png',
        ),
      );
    });

    testWidgets('manual empty state in dark theme', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, theme: createTestThemeDark());
      await expectLater(
        find.byType(UnitOfMeasurementField),
        matchesGoldenFile(
          'goldens/unit_of_measurement_field/${size.width}x${size.height}/manual_empty_dark.png',
        ),
      );
    });

    testWidgets('manual selected state in light theme', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, selectedUnit: Unit.kilograms);
      await expectLater(
        find.byType(UnitOfMeasurementField),
        matchesGoldenFile(
          'goldens/unit_of_measurement_field/${size.width}x${size.height}/manual_selected_light.png',
        ),
      );
    });

    testWidgets('manual selected state in dark theme', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(
        tester: tester,
        selectedUnit: Unit.kilograms,
        theme: createTestThemeDark(),
      );
      await expectLater(
        find.byType(UnitOfMeasurementField),
        matchesGoldenFile(
          'goldens/unit_of_measurement_field/${size.width}x${size.height}/manual_selected_dark.png',
        ),
      );
    });
  });
}

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
    String? errorText,
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
              errorText: errorText,
              onUnitSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('UnitOfMeasurementField Screenshot Tests', () {
    group('bottom sheet opened state', () {
      const openedSize = Size(390.0, 844.0);

      Future<void> pumpAndOpenSheet({
        required WidgetTester tester,
        ThemeData? theme,
      }) async {
        tester.view.physicalSize = openedSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme ?? createTestTheme(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: UnitOfMeasurementField(
                  fromCostFile: false,
                  selectedUnit: null,
                  onUnitSelected: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(UnitOfMeasurementField));
        await tester.pumpAndSettle();
      }

      Future<void> pumpAndOpenSheetInManuallyMode({
        required WidgetTester tester,
        ThemeData? theme,
      }) async {
        await pumpAndOpenSheet(tester: tester, theme: theme);
        final l10n = await AppLocalizations.delegate.load(const Locale('en'));
        await tester.tap(find.text(l10n.uomManuallyOption));
        await tester.pumpAndSettle();
      }

      testWidgets('bottom sheet open in light theme', (tester) async {
        await pumpAndOpenSheet(tester: tester);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/unit_of_measurement_field/${openedSize.width}x${openedSize.height}/bottom_sheet_open_light.png',
          ),
        );
      });

      testWidgets('bottom sheet open in manually mode light theme', (
        tester,
      ) async {
        await pumpAndOpenSheetInManuallyMode(tester: tester);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/unit_of_measurement_field/${openedSize.width}x${openedSize.height}/bottom_sheet_open_manually_light.png',
          ),
        );
      });

      testWidgets('bottom sheet open in manually mode dark theme', (
        tester,
      ) async {
        await pumpAndOpenSheetInManuallyMode(
          tester: tester,
          theme: createTestThemeDark(),
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/unit_of_measurement_field/${openedSize.width}x${openedSize.height}/bottom_sheet_open_manually_dark.png',
          ),
        );
      });
    });

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

    testWidgets('error state in light theme', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(
        tester: tester,
        errorText: 'Please select or enter a unit of measurement.',
      );
      await expectLater(
        find.byType(UnitOfMeasurementField),
        matchesGoldenFile(
          'goldens/unit_of_measurement_field/${size.width}x${size.height}/manual_error_light.png',
        ),
      );
    });

  });
}

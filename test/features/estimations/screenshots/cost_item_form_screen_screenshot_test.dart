import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_item_form_screen.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 844);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpScreen({
    required WidgetTester tester,
    required CostItemType type,
    bool fromCostFile = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CostItemFormScreen(
          type: type,
          estimationId: 'test-estimation-id',
          router: FakeAppRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (fromCostFile) {
      await tester.tap(find.byKey(const Key('from_cost_file_pill')));
      await tester.pumpAndSettle();
    }
  }

  group('CostItemFormScreen Screenshot Tests', () {
    testWidgets('renders material cost screen in manually mode', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpScreen(tester: tester, type: CostItemType.material);

      await expectLater(
        find.byType(CostItemFormScreen),
        matchesGoldenFile(
          'goldens/cost_item_form_screen/${size.width}x${size.height}/material_manually.png',
        ),
      );
    });

    testWidgets('renders material cost screen in from cost file mode', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpScreen(
        tester: tester,
        type: CostItemType.material,
        fromCostFile: true,
      );

      await expectLater(
        find.byType(CostItemFormScreen),
        matchesGoldenFile(
          'goldens/cost_item_form_screen/${size.width}x${size.height}/material_from_cost_file.png',
        ),
      );
    });

  });
}

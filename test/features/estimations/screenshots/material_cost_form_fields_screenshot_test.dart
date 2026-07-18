import 'package:construculator/features/estimation/presentation/widgets/material_cost_form_fields.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390.0, 600.0);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpWidget({
    required WidgetTester tester,
    bool fromCostFile = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MaterialCostFormFields(fromCostFile: fromCostFile),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MaterialCostFormFields Screenshot Tests', () {
    testWidgets('renders manually mode in light theme', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester);
      await expectLater(
        find.byType(MaterialCostFormFields),
        matchesGoldenFile(
          'goldens/material_cost_form_fields/${size.width}x${size.height}/manually_light.png',
        ),
      );
    });

    testWidgets('renders from cost file mode in light theme', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await pumpWidget(tester: tester, fromCostFile: true);
      await expectLater(
        find.byType(MaterialCostFormFields),
        matchesGoldenFile(
          'goldens/material_cost_form_fields/${size.width}x${size.height}/from_cost_file_light.png',
        ),
      );
    });

  });
}

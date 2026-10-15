import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_pill.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(160, 64);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  screenshotThemeGroups('UnitPill Screenshot Tests', (theme, suffix) {
    Future<void> pumpPill(WidgetTester tester, {Unit? unit}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: UnitPill(unit: unit, onUnitSelected: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders the empty pill', (tester) async {
      await pumpPill(tester);

      await expectLater(
        find.byType(UnitPill),
        matchesGoldenFile('goldens/unit_pill/unit_pill_empty$suffix.png'),
      );
    });

    testWidgets('renders the pill with a unit', (tester) async {
      await pumpPill(tester, unit: Unit.liters);

      await expectLater(
        find.byType(UnitPill),
        matchesGoldenFile('goldens/unit_pill/unit_pill_liters$suffix.png'),
      );
    });
  });
}

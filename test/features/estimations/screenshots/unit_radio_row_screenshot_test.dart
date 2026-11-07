import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_radio_row.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(412, 56);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  screenshotThemeGroups('UnitRadioRow Screenshot Tests', (theme, suffix) {
    Future<void> pumpRow(WidgetTester tester, {bool isSelected = false}) async {
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
            builder: (context) => Scaffold(
              backgroundColor: sheetSurface(context),
              body: UnitRadioRow(
                unit: Unit.gallons,
                isSelected: isSelected,
                onSelected: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> expectRowGolden(WidgetTester tester, String name) async {
      await expectLater(
        find.byType(UnitRadioRow),
        matchesGoldenFile('goldens/unit_radio_row/$name$suffix.png'),
      );
    }

    testWidgets('at rest', (tester) async {
      await pumpRow(tester);
      await expectRowGolden(tester, 'rest');
    });

    testWidgets('selected', (tester) async {
      await pumpRow(tester, isSelected: true);
      await expectRowGolden(tester, 'selected');
    });

    testWidgets('pressed', (tester) async {
      await pumpRow(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(UnitRadioRow)),
      );
      await tester.pumpAndSettle();
      await expectRowGolden(tester, 'pressed');
      await gesture.up();
    });

    testWidgets('focused from the keyboard', (tester) async {
      await pumpRow(tester);
      Focus.of(
        tester.element(find.byKey(const Key('unit_focus_ring_gallons'))),
      ).requestFocus();
      await tester.pumpAndSettle();
      await expectRowGolden(tester, 'focused');
    });
  });
}

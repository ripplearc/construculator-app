import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_section_header.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async => loadAppFontsAll());

  Future<void> pumpHeader(
    WidgetTester tester, {
    required CostItemType type,
    required double subtotal,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CostSectionHeader(type: type, subtotal: subtotal),
        ),
      ),
    );
  }

  final l10n = lookupAppLocalizations(const Locale('en'));
  final names = {
    CostItemType.material: l10n.costSectionMaterials.toUpperCase(),
    CostItemType.labor: l10n.costSectionLabor.toUpperCase(),
    CostItemType.equipment: l10n.costSectionEquipment.toUpperCase(),
  };

  for (final entry in names.entries) {
    testWidgets('names the ${entry.key.name} section', (tester) async {
      await pumpHeader(tester, type: entry.key, subtotal: 0);

      expect(
        tester
            .widget<Text>(
              find.byKey(Key('cost_section_name_${entry.key.name}')),
            )
            .data,
        entry.value,
      );
    });
  }

  testWidgets('spaces the letters of the name as the design does', (
    tester,
  ) async {
    await pumpHeader(tester, type: CostItemType.material, subtotal: 0);

    expect(
      tester
          .widget<Text>(find.byKey(const Key('cost_section_name_material')))
          .style,
      isA<TextStyle>().having(
        (style) => style.letterSpacing,
        'letterSpacing',
        0.84,
      ),
    );
  });

  testWidgets('shows the subtotal in dollars and cents with commas', (
    tester,
  ) async {
    await pumpHeader(tester, type: CostItemType.material, subtotal: 1265.02);

    expect(
      tester
          .widget<Text>(find.byKey(const Key('cost_section_subtotal_material')))
          .data,
      r'$1,265.02',
    );
  });

  testWidgets('shows an empty section as zero dollars rather than hiding it', (
    tester,
  ) async {
    await pumpHeader(tester, type: CostItemType.equipment, subtotal: 0);

    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('cost_section_subtotal_equipment')),
          )
          .data,
      r'$0.00',
    );
  });

  testWidgets('puts the name on the left and the subtotal on the right', (
    tester,
  ) async {
    await pumpHeader(tester, type: CostItemType.labor, subtotal: 480);

    final name = tester.getTopLeft(
      find.byKey(const Key('cost_section_name_labor')),
    );
    final subtotal = tester.getTopRight(
      find.byKey(const Key('cost_section_subtotal_labor')),
    );
    final band = tester.getRect(
      find.byKey(const Key('cost_section_header_labor')),
    );
    expect(name.dx, band.left + CoreSpacing.space4);
    expect(subtotal.dx, band.right - CoreSpacing.space4);
  });

  testWidgets('draws a grey band with a light line above and below it', (
    tester,
  ) async {
    await pumpHeader(tester, type: CostItemType.material, subtotal: 10);
    final band = find.byKey(const Key('cost_section_header_material'));
    final colors = AppColorsExtension.of(tester.element(band));

    expect(
      tester.getSize(band).width,
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
    );
    final decoration =
        tester.widget<DecoratedBox>(band).decoration as BoxDecoration;
    final border = BorderSide(color: colors.lineLight);
    expect(decoration.color, colors.backgroundGrayLight);
    expect(decoration.border, Border(top: border, bottom: border));
  });

  testWidgets('is 44 dp high at the normal text size', (tester) async {
    await pumpHeader(tester, type: CostItemType.material, subtotal: 10);

    expect(
      tester
          .getSize(find.byKey(const Key('cost_section_header_material')))
          .height,
      44,
    );
  });

  testWidgets('is announced to a screen reader as one heading', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHeader(tester, type: CostItemType.material, subtotal: 1265.02);

    final node = tester.getSemantics(
      find.byKey(const Key('cost_section_header_material')),
    );
    expect(node.label, contains(l10n.costSectionMaterials.toUpperCase()));
    expect(node.label, contains(r'$1,265.02'));
    expect(node.getSemanticsData().flagsCollection.isHeader, isTrue);
    handle.dispose();
  });

  testWidgets(
    'does not overflow at double text size with a six-figure subtotal',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: CoreTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: CostSectionHeader(
              type: CostItemType.equipment,
              subtotal: 497311.09,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );
}

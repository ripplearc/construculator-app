import 'package:construculator/features/estimation/presentation/widgets/cost_line_row.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../helpers/cost_line_test_items.dart';

void main() {
  var taps = 0;

  setUp(() => taps = 0);

  Future<void> pumpRow(WidgetTester tester, CostLineRow row) =>
      tester.pumpWidget(
        MaterialApp(
          theme: CoreTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: row),
        ),
      );

  testWidgets(
    'shows the name, the meta row and the total of an equipment line',
    (tester) async {
      await pumpRow(
        tester,
        CostLineRow(item: equipmentLine(), isHighlighted: false),
      );

      expect(find.text('Scissor lift — 19ft'), findsOneWidget);
      expect(
        find.textContaining(r'4 days · $145.00/day + $85.00 delivery'),
        findsOneWidget,
      );
      expect(find.text(r'$665.00'), findsOneWidget);
    },
  );

  testWidgets('shows a material line with its quantity and price', (
    tester,
  ) async {
    await pumpRow(
      tester,
      CostLineRow(item: materialLine(), isHighlighted: false),
    );

    expect(find.text('Drywall sheets'), findsOneWidget);
    expect(find.textContaining(r'13.25 sheets · $14.50/sheet'), findsOneWidget);
    expect(find.text(r'$211.34'), findsOneWidget);
  });

  testWidgets('shows a labor line with its hours and rate', (tester) async {
    await pumpRow(
      tester,
      CostLineRow(
        item: laborLine(calculation: const {'laborRate': 48}),
        isHighlighted: false,
      ),
    );

    expect(find.text('Framing crew'), findsOneWidget);
    expect(find.textContaining(r'10 h · $48.00/h'), findsOneWidget);
    expect(find.text(r'$480.00'), findsOneWidget);
  });

  testWidgets('keeps the amount on the first line of a wrapped name', (
    tester,
  ) async {
    const longName =
        'Type-X fire-rated gypsum board, 5/8" × 4′ × 12′, '
        'moisture & mould resistant';
    await pumpRow(
      tester,
      CostLineRow(
        item: materialLine(name: longName, total: 104318.6),
        isHighlighted: false,
      ),
    );

    final nameTop = tester.getTopLeft(find.text(longName)).dy;
    final amountTop = tester.getTopLeft(find.text(r'$104,318.60')).dy;
    expect(tester.getSize(find.text(longName)).height, greaterThan(40));
    expect(amountTop, nameTop);
  });

  testWidgets('reports a tap anywhere on the card', (tester) async {
    await pumpRow(
      tester,
      CostLineRow(
        item: materialLine(id: 'm9'),
        isHighlighted: false,
        onTap: () => taps++,
      ),
    );

    await tester.tap(find.byKey(const Key('cost_line_frame_m9')));

    expect(taps, 1);
  });

  testWidgets('reports a tap on the padding of the card, not only the row', (
    tester,
  ) async {
    await pumpRow(
      tester,
      CostLineRow(
        item: materialLine(id: 'm9'),
        isHighlighted: false,
        onTap: () => taps++,
      ),
    );
    final corner = tester.getTopLeft(
      find.byKey(const Key('cost_line_frame_m9')),
    );

    await tester.tapAt(corner + const Offset(2, 2));

    expect(taps, 1);
  });

  testWidgets('highlights the card of the line just added', (tester) async {
    await pumpRow(
      tester,
      CostLineRow(item: materialLine(id: 'm9'), isHighlighted: true),
    );
    final frame = find.byKey(const Key('cost_line_frame_m9'));
    final colors = AppColorsExtension.of(tester.element(frame));

    final box = tester.widget<DecoratedBox>(
      find.descendant(of: frame, matching: find.byType(DecoratedBox)),
    );
    expect((box.decoration as BoxDecoration).color, colors.backgroundBlueLight);
  });
}

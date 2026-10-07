import 'package:construculator/features/estimation/presentation/widgets/cost_line_card_frame.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  var taps = 0;

  setUp(() => taps = 0);

  Future<void> pumpFrame(
    WidgetTester tester, {
    required bool isHighlighted,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CostLineCardFrame(
            key: const Key('line_frame'),
            isHighlighted: isHighlighted,
            onTap: () => taps++,
            child: const Text('Interior paint · ProClassic'),
          ),
        ),
      ),
    );
  }

  BoxDecoration decoration(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key('line_frame')),
        matching: find.byType(DecoratedBox),
      ),
    );
    return box.decoration as BoxDecoration;
  }

  testWidgets('draws a blue border and blue fill when highlighted', (
    tester,
  ) async {
    await pumpFrame(tester, isHighlighted: true);
    final colors = AppColorsExtension.of(
      tester.element(find.byKey(const Key('line_frame'))),
    );

    final box = decoration(tester);
    expect(box.color, colors.backgroundBlueLight);
    expect((box.border! as Border).top.color, colors.lineHighlight);
  });

  testWidgets('draws a grey border and no fill otherwise', (tester) async {
    await pumpFrame(tester, isHighlighted: false);
    final colors = AppColorsExtension.of(
      tester.element(find.byKey(const Key('line_frame'))),
    );

    final box = decoration(tester);
    expect(box.color, colors.transparent);
    expect((box.border! as Border).top.color, colors.lineLight);
  });

  testWidgets('keeps the same corners and padding when highlighted', (
    tester,
  ) async {
    await pumpFrame(tester, isHighlighted: false);
    final plain = decoration(tester).borderRadius;
    final plainSize = tester.getSize(find.byKey(const Key('line_frame')));

    await pumpFrame(tester, isHighlighted: true);

    expect(decoration(tester).borderRadius, plain);
    expect(tester.getSize(find.byKey(const Key('line_frame'))), plainSize);
  });

  testWidgets('has no shadow and no animation when highlighted', (
    tester,
  ) async {
    await pumpFrame(tester, isHighlighted: true);

    expect(decoration(tester).boxShadow, isNull);
    expect(find.byType(AnimatedContainer), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reports a tap on the line', (tester) async {
    await pumpFrame(tester, isHighlighted: true);

    await tester.tap(find.text('Interior paint · ProClassic'));

    expect(taps, 1);
  });
}

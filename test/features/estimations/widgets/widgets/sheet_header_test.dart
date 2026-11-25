import 'package:construculator/features/estimation/presentation/widgets/sheet_header.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  final longName = ('Type-X fire-rated gypsum board ' * 4).substring(0, 120);

  Future<void> pumpHeader(
    WidgetTester tester,
    String title, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: Scaffold(
            body: SheetHeader(title: title, subtitle: r'$14.75 / sheet'),
          ),
        ),
      ),
    );
  }

  RenderParagraph paragraphOf(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text));

  for (final textScale in [1.0, 2.0]) {
    testWidgets('a 120 character material name shows on one line ending in '
        '"…" at text size $textScale', (tester) async {
      await pumpHeader(tester, longName, textScale: textScale);

      final title = paragraphOf(tester, longName);
      final oneLine = TextPainter(
        text: title.text,
        textDirection: TextDirection.ltr,
        textScaler: title.textScaler,
        maxLines: 1,
      )..layout();
      addTearDown(oneLine.dispose);
      expect(longName.length, 120);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(title.didExceedMaxLines, isTrue);
      expect(title.size.height, oneLine.height);
      expect(title.textScaler, TextScaler.linear(textScale));
    });
  }

  testWidgets('a name that fits is shown whole, with no "…"', (tester) async {
    await pumpHeader(tester, 'Drywall sheets');

    expect(paragraphOf(tester, 'Drywall sheets').didExceedMaxLines, isFalse);
  });
}

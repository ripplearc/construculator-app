import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Future<Color> surfaceIn(WidgetTester tester, ThemeData theme) async {
    late Color result;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            result = sheetSurface(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('is white in the light theme', (tester) async {
    expect((await surfaceIn(tester, CoreTheme.light())).toARGB32(), 0xFFFFFFFF);
  });

  testWidgets('is the page background in the dark theme', (tester) async {
    final dark = CoreTheme.dark();
    final expected = dark.extension<AppColorsExtension>()!.pageBackground;

    expect(await surfaceIn(tester, dark), expected);
  });
}

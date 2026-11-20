import 'package:construculator/features/estimation/presentation/widgets/number_pad_sheet_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const headerKey = Key('header');
  const formKey = Key('form');
  const panelKey = Key('panel');
  const controlsKey = Key('controls');
  const scrollKey = Key('form_scroll');

  Widget box(Key key, double height) => SizedBox(key: key, height: height);

  // Header 50, panel 130, pad 400. The header, like the sheet's title row,
  // holds a Column that fills any bounded height.
  Future<void> pumpLayout(WidgetTester tester, double sheetHeight) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: sheetHeight,
            child: NumberPadSheetLayout(
              header: Column(
                key: headerKey,
                children: [box(const Key('title'), 50)],
              ),
              form: SingleChildScrollView(
                key: scrollKey,
                child: box(formKey, 300),
              ),
              panel: box(panelKey, 130),
              controls: box(controlsKey, 400),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect rectOf(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

  testWidgets('pins the header, the panel on top of the pad, and the pad, '
      'with the form scrolling between', (tester) async {
    await pumpLayout(tester, 700);

    expect(rectOf(tester, headerKey), const Rect.fromLTWH(0, 0, 400, 50));
    expect(rectOf(tester, controlsKey).bottom, 700);
    expect(rectOf(tester, panelKey).bottom, rectOf(tester, controlsKey).top);
    final scroll = rectOf(tester, scrollKey);
    expect(scroll.top, 50);
    expect(scroll.height, 700 - 50 - 130 - 400);
  });

  testWidgets('gives the form the height left when the sheet changes', (
    tester,
  ) async {
    await pumpLayout(tester, 700);
    await pumpLayout(tester, 650);

    expect(rectOf(tester, scrollKey).height, 650 - 50 - 130 - 400);
    expect(rectOf(tester, panelKey).bottom, rectOf(tester, controlsKey).top);
  });

  testWidgets('a sheet shorter than the header, panel and pad shows no form '
      'and keeps the pad at the bottom', (tester) async {
    await pumpLayout(tester, 420);

    expect(rectOf(tester, scrollKey).height, 0);
    expect(rectOf(tester, controlsKey).bottom, 420);
    expect(tester.takeException(), isNull);
  });
}

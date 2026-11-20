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

  // Header 50, panel 130, pad 400, one field row 70. The header, like the
  // sheet's title row, holds a Column that fills any bounded height.
  Future<void> pumpLayout(
    WidgetTester tester,
    double sheetHeight, {
    double controlsHeight = 400,
    double panelHeight = 130,
    double minFormHeight = 70,
    bool settle = true,
  }) async {
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
              form: (scrollingPanel) => SingleChildScrollView(
                key: scrollKey,
                child: Column(children: [box(formKey, 300), ?scrollingPanel]),
              ),
              panel: box(panelKey, panelHeight),
              controls: box(controlsKey, controlsHeight),
              minFormHeight: minFormHeight,
            ),
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  Rect rectOf(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

  Finder panelInScroll() => find.descendant(
    of: find.byKey(scrollKey),
    matching: find.byKey(panelKey),
  );

  testWidgets('pins the header, the panel on top of the pad, and the pad, '
      'with the form scrolling between', (tester) async {
    await pumpLayout(tester, 700);

    expect(rectOf(tester, headerKey), const Rect.fromLTWH(0, 0, 400, 50));
    expect(rectOf(tester, controlsKey).bottom, 700);
    expect(rectOf(tester, panelKey).bottom, rectOf(tester, controlsKey).top);
    final scroll = rectOf(tester, scrollKey);
    expect(scroll.top, 50);
    expect(scroll.height, 700 - 50 - 130 - 400);
    expect(panelInScroll(), findsNothing);
  });

  testWidgets('keeps the panel pinned with exactly one field row of form', (
    tester,
  ) async {
    await pumpLayout(tester, 50 + 70 + 130 + 400);

    expect(rectOf(tester, scrollKey).height, 70);
    expect(panelInScroll(), findsNothing);
  });

  testWidgets('scrolls the panel with the form when less than one field row '
      'would show, and nothing overflows', (tester) async {
    await pumpLayout(tester, 50 + 69 + 130 + 400);

    expect(panelInScroll(), findsOneWidget);
    final scroll = rectOf(tester, scrollKey);
    expect(scroll.top, 50);
    expect(scroll.bottom, rectOf(tester, controlsKey).top);
    expect(rectOf(tester, controlsKey).bottom, 50 + 69 + 130 + 400);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pins the panel again once the sheet grows', (tester) async {
    await pumpLayout(tester, 600);
    expect(panelInScroll(), findsOneWidget);

    await pumpLayout(tester, 700);

    expect(panelInScroll(), findsNothing);
    expect(rectOf(tester, panelKey).bottom, rectOf(tester, controlsKey).top);
  });

  testWidgets('pins the panel again once the pad area shrinks back, as when '
      'the save-error line goes', (tester) async {
    const sheetHeight = 50.0 + 70 + 130 + 400;
    await pumpLayout(tester, sheetHeight, controlsHeight: 428);
    expect(panelInScroll(), findsOneWidget);

    await pumpLayout(tester, sheetHeight);

    expect(panelInScroll(), findsNothing);
    expect(rectOf(tester, panelKey).bottom, rectOf(tester, controlsKey).top);
    expect(rectOf(tester, scrollKey).height, 70);
  });

  testWidgets('pins the panel again once the card gets shorter while it '
      'scrolls', (tester) async {
    const sheetHeight = 650.0;
    await pumpLayout(tester, sheetHeight, panelHeight: 160);
    expect(panelInScroll(), findsOneWidget);

    await pumpLayout(tester, sheetHeight, panelHeight: 130);

    expect(panelInScroll(), findsNothing);
    expect(rectOf(tester, panelKey).bottom, rectOf(tester, controlsKey).top);
    expect(rectOf(tester, scrollKey).height, 70);
  });

  testWidgets('keeps the panel in the form, with no jump, when the sheet '
      'grows but the card grows more', (tester) async {
    await pumpLayout(tester, 600, panelHeight: 100);
    expect(panelInScroll(), findsOneWidget);

    await pumpLayout(tester, 630, panelHeight: 160, settle: false);

    // 630 - 50 - 160 - 400 = 20, under one field row: the panel never pins,
    // not even for one frame.
    for (var frame = 0; frame < 3; frame++) {
      expect(panelInScroll(), findsOneWidget);
      expect(rectOf(tester, scrollKey).bottom, rectOf(tester, controlsKey).top);
      await tester.pump();
    }
  });

  testWidgets('scrolls the panel when only minFormHeight grows', (
    tester,
  ) async {
    const sheetHeight = 50.0 + 70 + 130 + 400;
    await pumpLayout(tester, sheetHeight);
    expect(panelInScroll(), findsNothing);

    await pumpLayout(tester, sheetHeight, minFormHeight: 90);

    expect(panelInScroll(), findsOneWidget);
  });

  testWidgets('a sheet shorter than the header and pad shows no form and '
      'keeps the pad at the bottom', (tester) async {
    await pumpLayout(tester, 420);

    expect(rectOf(tester, scrollKey).height, 0);
    expect(rectOf(tester, controlsKey).bottom, 420);
    expect(tester.takeException(), isNull);
  });
}

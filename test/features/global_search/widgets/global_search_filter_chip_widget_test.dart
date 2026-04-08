import 'package:construculator/features/global_search/presentation/widgets/global_search_filter_chip_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  Widget makeTestableWidget({required Widget child}) {
    return MaterialApp(
      theme: createTestTheme(),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('GlobalSearchFilterChipWidget', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          child: const GlobalSearchFilterChipWidget(label: 'Tags'),
        ),
      );

      expect(find.text('Tags'), findsOneWidget);
    });

    testWidgets('does not expose as button when onTap is null', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          child: const GlobalSearchFilterChipWidget(label: 'Tags'),
        ),
      );

      final handle = tester.ensureSemantics();
      // Use .first to target the outermost Semantics owned by this widget.
      // CoreIconWidget adds its own Semantics node internally, so the
      // descendant finder returns more than one match without the guard.
      final node = tester.getSemantics(
        find.descendant(
          of: find.byType(GlobalSearchFilterChipWidget),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(node.label, contains('Tags'));
      expect(node.hasFlag(SemanticsFlag.isButton), isFalse);
      handle.dispose();
    });

    testWidgets('invokes onTap when tapped and exposes semantics as button', (
      tester,
    ) async {
      var tapCount = 0;

      await tester.pumpWidget(
        makeTestableWidget(
          child: GlobalSearchFilterChipWidget(
            label: 'Tags',
            onTap: () => tapCount++,
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      // Use .first to target the outermost Semantics owned by this widget.
      // CoreIconWidget adds its own Semantics node internally, so the
      // descendant finder returns more than one match without the guard.
      final node = tester.getSemantics(
        find.descendant(
          of: find.byType(GlobalSearchFilterChipWidget),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(node.label, contains('Tags'));
      expect(node.hasFlag(SemanticsFlag.isButton), isTrue);

      await tester.tap(find.text('Tags'));
      await tester.pump();

      expect(tapCount, 1);
      handle.dispose();
    });
  });
}

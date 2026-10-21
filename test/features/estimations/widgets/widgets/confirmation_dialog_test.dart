import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  bool? answer;
  var hasAnswered = false;

  setUp(() {
    answer = null;
    hasAnswered = false;
  });

  Future<void> openDialog(
    WidgetTester tester, {
    double textScale = 1.0,
    String primaryLabel = 'Keep editing',
    double phoneWidth = 412,
  }) async {
    tester.view.physicalSize = Size(phoneWidth, 900);
    tester.view.devicePixelRatio = 1.0;
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
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_dialog'),
                onPressed: () async {
                  answer = await ConfirmationDialog.show(
                    context,
                    title: 'Discard this line?',
                    body: const TextSpan(
                      text: 'Interior paint has not been added.',
                    ),
                    secondaryLabel: 'Discard',
                    primaryLabel: primaryLabel,
                  );
                  hasAnswered = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_dialog')));
    await tester.pumpAndSettle();
  }

  group('what show returns', () {
    testWidgets('true for the primary button', (tester) async {
      await openDialog(tester);

      await tester.tap(find.byKey(ConfirmationDialog.primaryButtonKey));
      await tester.pumpAndSettle();

      expect(answer, isTrue);
    });

    testWidgets('false for the secondary button', (tester) async {
      await openDialog(tester);

      await tester.tap(find.byKey(ConfirmationDialog.secondaryButtonKey));
      await tester.pumpAndSettle();

      expect(answer, isFalse);
    });

    testWidgets('null for a tap outside the dialog', (tester) async {
      await openDialog(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(hasAnswered, isTrue);
      expect(answer, isNull);
    });

    testWidgets('null for the back gesture', (tester) async {
      await openDialog(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(hasAnswered, isTrue);
      expect(answer, isNull);
    });
  });

  group('layout', () {
    Rect rectOf(WidgetTester tester, Key key) =>
        tester.getRect(find.byKey(key));

    // The drawn button inside its tap area.
    Rect drawnRectOf(WidgetTester tester, Key key) => tester.getRect(
      find
          .descendant(of: find.byKey(key), matching: find.byType(DecoratedBox))
          .first,
    );

    Size labelSizeOf(WidgetTester tester, Key key) => tester.getSize(
      find.descendant(of: find.byKey(key), matching: find.byType(Text)),
    );

    for (final scale in [1.0, 1.12, 1.15, 1.3, 2.0]) {
      testWidgets(
        'stacks the answers at ${(scale * 100).round()} percent text, primary '
        'first, 8 dp apart',
        (tester) async {
          await openDialog(tester, textScale: scale);

          final primary = drawnRectOf(
            tester,
            ConfirmationDialog.primaryButtonKey,
          );
          final secondary = drawnRectOf(
            tester,
            ConfirmationDialog.secondaryButtonKey,
          );

          expect(secondary.top - primary.bottom, 8);
          expect(primary.width, secondary.width);
        },
      );

      testWidgets(
        'shows each label in full at ${(scale * 100).round()} percent text',
        (tester) async {
          await openDialog(tester, textScale: scale);

          for (final key in [
            ConfirmationDialog.primaryButtonKey,
            ConfirmationDialog.secondaryButtonKey,
          ]) {
            final button = drawnRectOf(tester, key);
            final label = labelSizeOf(tester, key);
            expect(label.width, lessThanOrEqualTo(button.width - 2 * 20));
            expect(label.height + 2 * 8, lessThanOrEqualTo(button.height));
          }
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('draws each answer 40 dp tall at the normal text size, in a '
        '48 dp tap area', (tester) async {
      await openDialog(tester);

      for (final key in [
        ConfirmationDialog.primaryButtonKey,
        ConfirmationDialog.secondaryButtonKey,
      ]) {
        expect(drawnRectOf(tester, key).height, 40);
        expect(rectOf(tester, key).height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('lets the answers grow past 40 dp at 200 percent text', (
      tester,
    ) async {
      await openDialog(tester, textScale: 2.0);

      for (final key in [
        ConfirmationDialog.primaryButtonKey,
        ConfirmationDialog.secondaryButtonKey,
      ]) {
        expect(drawnRectOf(tester, key).height, greaterThan(40));
      }
    });

    testWidgets('wraps a long label instead of cutting it at 200 percent', (
      tester,
    ) async {
      await openDialog(
        tester,
        textScale: 2.0,
        primaryLabel: 'Keep editing this material line',
      );

      final button = drawnRectOf(tester, ConfirmationDialog.primaryButtonKey);
      final label = labelSizeOf(tester, ConfirmationDialog.primaryButtonKey);
      expect(label.width, lessThanOrEqualTo(button.width - 2 * 20));
      expect(label.height, greaterThan(24 * 2));
    });

    testWidgets('is at most 340 dp wide and keeps 36 dp on each side of a '
        '412 dp phone', (tester) async {
      await openDialog(tester);

      // The dialog is the answer's width plus its 22 dp padding on each side.
      final answer = rectOf(tester, ConfirmationDialog.primaryButtonKey);
      final dialogWidth = answer.width + 2 * 22;
      final dialogLeft = answer.left - 22;
      expect(dialogWidth, lessThanOrEqualTo(340));
      expect(dialogLeft, greaterThanOrEqualTo(36));
      expect(412 - (dialogLeft + dialogWidth), greaterThanOrEqualTo(36));
    });

    testWidgets('keeps 36 dp on each side of a 360 dp phone', (tester) async {
      await openDialog(tester, phoneWidth: 360);

      final answer = rectOf(tester, ConfirmationDialog.primaryButtonKey);
      expect(answer.left - 22, greaterThanOrEqualTo(36));
      expect(360 - (answer.right + 22), greaterThanOrEqualTo(36));
    });

    testWidgets('writes the body in 16 dp text with 24 dp lines', (
      tester,
    ) async {
      await openDialog(tester);

      final style = tester
          .widget<Text>(find.byKey(ConfirmationDialog.bodyKey))
          .style!;
      expect(style.fontSize, 16);
      expect(style.fontSize! * style.height!, 24);
    });
  });
}

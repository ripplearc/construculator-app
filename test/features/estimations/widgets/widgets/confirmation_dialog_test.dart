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

  Future<void> openDialog(WidgetTester tester, {double textScale = 1.0}) async {
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
                    primaryLabel: 'Keep editing',
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
    testWidgets('puts the two answers side by side at the normal text size', (
      tester,
    ) async {
      await openDialog(tester);

      final secondary = tester.getRect(
        find.byKey(ConfirmationDialog.secondaryButtonKey),
      );
      final primary = tester.getRect(
        find.byKey(ConfirmationDialog.primaryButtonKey),
      );

      expect(primary.top, secondary.top);
      expect(primary.left, greaterThan(secondary.right));
    });

    testWidgets('stacks the answers, primary first, at a large text size', (
      tester,
    ) async {
      await openDialog(tester, textScale: 1.3);

      final secondary = tester.getRect(
        find.byKey(ConfirmationDialog.secondaryButtonKey),
      );
      final primary = tester.getRect(
        find.byKey(ConfirmationDialog.primaryButtonKey),
      );

      expect(primary.bottom, lessThan(secondary.top));
      expect(primary.width, secondary.width);
    });

    testWidgets('keeps both answers readable in full at a large text size', (
      tester,
    ) async {
      await openDialog(tester, textScale: 2.0);

      expect(find.text('Keep editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const width = 412.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  screenshotThemeGroups('ConfirmationDialog Screenshot Tests', (theme, suffix) {
    Future<void> pumpDialog(
      WidgetTester tester, {
      required double textScale,
      double height = 420,
    }) async {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const Scaffold(
            body: Center(
              child: ConfirmationDialog(
                title: 'Discard this line?',
                body: TextSpan(
                  text: 'Interior paint has not been added to the estimate.',
                ),
                secondaryLabel: 'Discard',
                primaryLabel: 'Keep editing',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders the two answers stacked at the normal text size', (
      tester,
    ) async {
      await pumpDialog(tester, textScale: 1.0);

      await expectLater(
        find.byType(ConfirmationDialog),
        matchesGoldenFile(
          'goldens/confirmation_dialog/confirmation_dialog$suffix.png',
        ),
      );
    });

    for (final entry in {
      '112': (1.12, 'confirmation_dialog_text_112', 420.0),
      '130': (1.3, 'confirmation_dialog_large_text', 420.0),
      '200': (2.0, 'confirmation_dialog_text_200', 560.0),
    }.entries) {
      testWidgets('renders the two answers stacked at ${entry.key} percent '
          'text', (tester) async {
        await pumpDialog(
          tester,
          textScale: entry.value.$1,
          height: entry.value.$3,
        );

        await expectLater(
          find.byType(ConfirmationDialog),
          matchesGoldenFile(
            'goldens/confirmation_dialog/${entry.value.$2}$suffix.png',
          ),
        );
      });
    }
  });
}

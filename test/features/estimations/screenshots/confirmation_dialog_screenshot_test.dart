import 'package:construculator/features/estimation/presentation/widgets/confirmation_dialog.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(412, 420);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  screenshotThemeGroups('ConfirmationDialog Screenshot Tests', (theme, suffix) {
    Future<void> pumpDialog(
      WidgetTester tester, {
      required double textScale,
    }) async {
      tester.view.physicalSize = size;
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

    testWidgets('renders the two answers side by side', (tester) async {
      await pumpDialog(tester, textScale: 1.0);

      await expectLater(
        find.byType(ConfirmationDialog),
        matchesGoldenFile(
          'goldens/confirmation_dialog/confirmation_dialog$suffix.png',
        ),
      );
    });

    testWidgets('renders the two answers stacked at 130 percent text', (
      tester,
    ) async {
      await pumpDialog(tester, textScale: 1.3);

      await expectLater(
        find.byType(ConfirmationDialog),
        matchesGoldenFile(
          'goldens/confirmation_dialog/confirmation_dialog_large_text$suffix.png',
        ),
      );
    });
  });
}

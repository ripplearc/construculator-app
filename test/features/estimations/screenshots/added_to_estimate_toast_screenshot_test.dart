import 'package:construculator/features/estimation/presentation/widgets/added_to_estimate_toast.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(384, 50);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  screenshotThemeGroups('AddedToEstimateToast Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders the estimate name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Material(
            child: AddedToEstimateToast(message: 'Added to Bedroom 2'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AddedToEstimateToast),
        matchesGoldenFile(
          'goldens/added_to_estimate_toast/added_to_estimate_toast$suffix.png',
        ),
      );
    });

    testWidgets('wraps a long estimate name without overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(384, 80);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Material(
            child: AddedToEstimateToast(
              message:
                  'Added to Master bedroom, flooring, drywall and trim package',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(AddedToEstimateToast),
        matchesGoldenFile(
          'goldens/added_to_estimate_toast/added_to_estimate_toast_long$suffix.png',
        ),
      );
    });
  });
}

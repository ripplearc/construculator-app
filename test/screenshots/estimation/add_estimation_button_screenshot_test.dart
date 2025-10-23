import 'package:construculator/features/estimation/presentation/widgets/add_estimation_button.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../font_loader.dart';

void main() {
  final size = const Size(390, 844);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  group('AddEstimationButton Screenshot Tests', () {
    Future<void> pumpAddEstimationButton({
      required WidgetTester tester,
      required VoidCallback onPressed,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: Text(
                      'Background content',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                Positioned(
                  bottom: size.height * 0.135, // 13.5% from bottom
                  right: size.width * 0.05, // 5% from right
                  child: AddEstimationButton(
                    onPressed: onPressed,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders add estimation button correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpAddEstimationButton(tester: tester, onPressed: () {});

      await expectLater(
        find.byType(AddEstimationButton),
        matchesGoldenFile(
          'goldens/add_estimation_button/${size.width}x${size.height}/add_estimation_button_default.png',
        ),
      );
    });

    testWidgets('renders add estimation button with different positioning', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: Text(
                      'Background content',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                Positioned(
                  bottom: size.height * 0.02, // 2% from bottom
                  right: size.width * 0.04, // 4% from right
                  child: AddEstimationButton(
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AddEstimationButton),
        matchesGoldenFile(
          'goldens/add_estimation_button/${size.width}x${size.height}/add_estimation_button_alternative_position.png',
        ),
      );
    });

    testWidgets('renders add estimation button in center position', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: Text(
                      'Background content',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                Center(
                  child: AddEstimationButton(
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AddEstimationButton),
        matchesGoldenFile(
          'goldens/add_estimation_button/${size.width}x${size.height}/add_estimation_button_center.png',
        ),
      );
    });
  });
}

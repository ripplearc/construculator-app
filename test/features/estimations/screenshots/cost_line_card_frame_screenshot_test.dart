import 'package:construculator/features/estimation/presentation/widgets/cost_line_card_frame.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(412, 460);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async => loadAppFontsAll());

  Widget line(
    BuildContext context, {
    required String name,
    required String total,
    required String detail,
    required bool isHighlighted,
  }) {
    final textTheme = context.textTheme;
    final colorTheme = context.colorTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CostLineCardFrame(
        isHighlighted: isHighlighted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: textTheme.bodyLargeSemiBold.copyWith(
                    color: colorTheme.textHeadline,
                  ),
                ),
                Text(
                  total,
                  style: textTheme.bodyLargeSemiBold.copyWith(
                    color: colorTheme.textHeadline,
                  ),
                ),
              ],
            ),
            Text(
              detail,
              style: textTheme.bodyMediumRegular.copyWith(
                color: colorTheme.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pumpLines(
    WidgetTester tester,
    ThemeData theme, {
    required bool highlightLast,
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
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                line(
                  context,
                  name: 'Flooring — floor area',
                  total: r'$1,026.68',
                  detail: r'410.67 ft² · $2.50/ft²',
                  isHighlighted: false,
                ),
                line(
                  context,
                  name: 'Drywall sheets ½"',
                  total: r'$211.34',
                  detail: r'13.25 sheets · $14.50/sheet',
                  isHighlighted: false,
                ),
                line(
                  context,
                  name: 'Interior paint · ProClassic',
                  total: r'$171.60',
                  detail: r'3 gal · $52.00/gal',
                  isHighlighted: highlightLast,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('Cost line card frame Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('the line just added is highlighted', (tester) async {
      await pumpLines(tester, theme, highlightLast: true);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/cost_line_card_frame/highlighted$suffix.png',
        ),
      );
    });

    testWidgets('no line is highlighted once it is cleared', (tester) async {
      await pumpLines(tester, theme, highlightLast: false);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/cost_line_card_frame/not_highlighted$suffix.png',
        ),
      );
    });
  });
}

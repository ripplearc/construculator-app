import 'package:construculator/features/dashboard/domain/entities/favorite_estimation_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorite_estimation_card.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  final _estimation = FavoriteEstimation(
    id: 'est-1',
    title: '2nd Wall cost',
    date: DateTime(2025, 5, 3, 14, 30),
    totalCost: 12343.88,
  );

  Widget makeTestableWidget({ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: FavoriteEstimationCard(
            estimation: _estimation,
            onTap: () {},
            onMoreOptions: () {},
          ),
        ),
      ),
    );
  }

  group('FavoriteEstimationCard – accessibility', () {
    testWidgets(
      'meets tap target and label guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(theme: theme),
          find.byKey(const Key('estimation_more_options')),
        );
      },
    );
  });
}

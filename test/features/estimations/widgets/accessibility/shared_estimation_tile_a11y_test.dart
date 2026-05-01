import 'package:construculator/features/estimation/presentation/widgets/shared_estimation_tile.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  group('SharedEstimationTile A11y Tests', () {
    final testDate = DateTime(2024, 3, 15, 14, 30);

    Widget createWidget({
      required EstimationTileData data,
      VoidCallback? onTap,
      VoidCallback? onMenuTap,
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SharedEstimationTile(
            data: data,
            onTap: onTap ?? () {},
            onMenuTap: onMenuTap,
          ),
        ),
      );
    }

    testWidgets('a11y: tile passes in both themes (with menu)', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(
          data: _FakeData(estimateName: 'Test Estimate', displayDate: testDate),
          onMenuTap: () {},
          theme: theme,
        ),
        find.byType(SharedEstimationTile),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });

    testWidgets('a11y: tile passes in both themes (without menu)', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(
          data: _FakeData(estimateName: 'Test Estimate', displayDate: testDate),
          onMenuTap: null,
          theme: theme,
        ),
        find.byType(SharedEstimationTile),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });
  });
}

class _FakeData implements EstimationTileData {
  @override
  final String estimateName;

  @override
  final double? totalCost;

  @override
  final DateTime displayDate;

  const _FakeData({
    required this.estimateName,
    required this.displayDate,
    this.totalCost = 15000.50,
  });
}

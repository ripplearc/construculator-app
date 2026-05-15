import 'package:construculator/features/dashboard/presentation/widgets/estimation_card.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/entities/enums.dart';
import 'package:construculator/libraries/estimation/domain/entities/lock_status_entity.dart';
import 'package:construculator/libraries/estimation/domain/entities/markup_configuration_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  final updatedAt = DateTime(2024, 3, 10, 16, 45);

  CostEstimate buildEstimation({
    String estimateName = 'Kitchen Remodel',
    DateTime? updatedAtOverride,
  }) {
    final at = updatedAtOverride ?? updatedAt;
    return CostEstimate(
      id: 'estimation-1',
      projectId: 'project-1',
      estimateName: estimateName,
      creatorUserId: 'user-1',
      markupConfiguration: MarkupConfiguration(
        overallType: MarkupType.overall,
        overallValue: const MarkupValue(
          type: MarkupValueType.percentage,
          value: 10,
        ),
      ),
      lockStatus: const UnlockedStatus(),
      createdAt: at,
      updatedAt: at,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required CostEstimate estimation,
    required VoidCallback onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: EstimationCard(estimation: estimation, onTap: onTap),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('displays estimate name and formatted date and time', (
    tester,
  ) async {
    final estimation = buildEstimation();

    await pumpCard(tester, estimation: estimation, onTap: () {});

    expect(find.text('Kitchen Remodel'), findsOneWidget);
    expect(find.text('Mar 10, 2024'), findsOneWidget);
    expect(find.text('4:45 pm'), findsOneWidget);
  });

  testWidgets('invokes onTap when the card is tapped', (tester) async {
    var tapped = false;
    final estimation = buildEstimation();

    await pumpCard(tester, estimation: estimation, onTap: () => tapped = true);

    await tester.tap(find.byType(EstimationCard));
    await tester.pump();

    expect(tapped, isTrue);
  });
}

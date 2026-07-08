import 'package:construculator/features/project_settings/presentation/widgets/project_header_card.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_stats_cards.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Future<void> pumpProjectHeaderCard(
    WidgetTester tester, {
    String projectName = 'Material of building',
    String? description,
    DateTime? lastUpdatedAt,
    int estimationCount = 0,
    int memberCount = 0,
    VoidCallback? onEstimationsTap,
    VoidCallback? onMembersTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProjectHeaderCard(
            projectName: projectName,
            description: description,
            lastUpdatedAt: lastUpdatedAt ?? DateTime(2024, 10, 12, 14, 30),
            estimationCount: estimationCount,
            memberCount: memberCount,
            onEstimationsTap: onEstimationsTap,
            onMembersTap: onMembersTap,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ProjectHeaderCard', () {
    testWidgets('displays the project name', (tester) async {
      await pumpProjectHeaderCard(tester, projectName: 'Material of building');

      expect(find.byKey(ProjectHeaderCard.projectNameKey), findsOneWidget);
      expect(find.text('Material of building'), findsOneWidget);
    });

    testWidgets('displays the description when provided', (tester) async {
      await pumpProjectHeaderCard(tester, description: 'A short description.');

      expect(find.byKey(ProjectHeaderCard.descriptionKey), findsOneWidget);
      expect(find.text('A short description.'), findsOneWidget);
    });

    testWidgets('omits the description when null', (tester) async {
      await pumpProjectHeaderCard(tester);

      expect(find.byKey(ProjectHeaderCard.descriptionKey), findsNothing);
    });

    testWidgets('omits the description when blank', (tester) async {
      await pumpProjectHeaderCard(tester, description: '   ');

      expect(find.byKey(ProjectHeaderCard.descriptionKey), findsNothing);
    });

    testWidgets('shows the formatted last-updated date and time', (
      tester,
    ) async {
      await pumpProjectHeaderCard(
        tester,
        lastUpdatedAt: DateTime(2024, 10, 12, 14, 30),
      );

      expect(find.byKey(ProjectHeaderCard.lastUpdatedKey), findsOneWidget);
      expect(find.textContaining('Last updated: Oct 12, 2024'), findsOneWidget);
      expect(find.textContaining('2:30 PM'), findsOneWidget);
    });

    testWidgets('embeds ProjectStatsCards with the given counts', (
      tester,
    ) async {
      await pumpProjectHeaderCard(tester, estimationCount: 34, memberCount: 12);

      expect(find.byType(ProjectStatsCards), findsOneWidget);
      expect(find.text('34'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('forwards stat card taps to the callbacks', (tester) async {
      var estimationsTapped = false;
      var membersTapped = false;
      await pumpProjectHeaderCard(
        tester,
        onEstimationsTap: () => estimationsTapped = true,
        onMembersTap: () => membersTapped = true,
      );

      await tester.tap(find.byKey(const Key('project_stats_estimations_card')));
      await tester.tap(find.byKey(const Key('project_stats_members_card')));

      expect(estimationsTapped, isTrue);
      expect(membersTapped, isTrue);
    });
  });
}

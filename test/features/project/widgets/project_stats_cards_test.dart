import 'package:construculator/features/project/presentation/widgets/project_stats_cards.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Future<void> pumpProjectStatsCards(
    WidgetTester tester, {
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
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ProjectStatsCards(
              estimationCount: estimationCount,
              memberCount: memberCount,
              onEstimationsTap: onEstimationsTap,
              onMembersTap: onMembersTap,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ProjectStatsCards', () {
    testWidgets('renders both stat cards', (tester) async {
      await pumpProjectStatsCards(
        tester,
        estimationCount: 34,
        memberCount: 12,
      );

      expect(
        find.byKey(const Key('project_stats_estimations_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('project_stats_members_card')),
        findsOneWidget,
      );
    });

    testWidgets('displays estimation count and label', (tester) async {
      await pumpProjectStatsCards(tester, estimationCount: 34);

      expect(find.text('34'), findsOneWidget);
      expect(find.text('No. of cost estimation'), findsOneWidget);
    });

    testWidgets('displays member count and label', (tester) async {
      await pumpProjectStatsCards(tester, memberCount: 12);

      expect(find.text('12'), findsOneWidget);
      expect(find.text('People invited'), findsOneWidget);
    });

    testWidgets('displays zero counts', (tester) async {
      await pumpProjectStatsCards(
        tester,
        estimationCount: 0,
        memberCount: 0,
      );

      expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('calls onEstimationsTap when estimations card is tapped', (
      tester,
    ) async {
      bool tapped = false;

      await pumpProjectStatsCards(
        tester,
        estimationCount: 5,
        onEstimationsTap: () => tapped = true,
      );

      await tester.tap(find.byKey(const Key('project_stats_estimations_card')));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('calls onMembersTap when members card is tapped', (
      tester,
    ) async {
      bool tapped = false;

      await pumpProjectStatsCards(
        tester,
        memberCount: 5,
        onMembersTap: () => tapped = true,
      );

      await tester.tap(find.byKey(const Key('project_stats_members_card')));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('handles null tap callbacks gracefully', (tester) async {
      await pumpProjectStatsCards(
        tester,
        estimationCount: 3,
        memberCount: 7,
        onEstimationsTap: null,
        onMembersTap: null,
      );

      await tester.tap(find.byKey(const Key('project_stats_estimations_card')));
      await tester.tap(find.byKey(const Key('project_stats_members_card')));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('does not overflow with very large counts', (tester) async {
      await pumpProjectStatsCards(
        tester,
        estimationCount: 999999999999999,
        memberCount: 999999999999999,
      );

      expect(find.byType(ProjectStatsCards), findsOneWidget);
    });

    testWidgets('stat cards have button semantics when tappable', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpProjectStatsCards(
        tester,
        estimationCount: 34,
        memberCount: 12,
        onEstimationsTap: () {},
        onMembersTap: () {},
      );

      expect(
        tester
            .getSemantics(find.byKey(const Key('project_stats_estimations_card')))
            .hasFlag(SemanticsFlag.isButton),
        isTrue,
      );
      expect(
        tester
            .getSemantics(find.byKey(const Key('project_stats_members_card')))
            .hasFlag(SemanticsFlag.isButton),
        isTrue,
      );

      handle.dispose();
    });
  });
}

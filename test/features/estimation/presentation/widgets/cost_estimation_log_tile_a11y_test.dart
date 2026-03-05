import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_log_tile.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  group('CostEstimationLogTile A11y Tests', () {
    late CostEstimationLog testLog;

    setUp(() {
      testLog = CostEstimationLog(
        id: 'log-123',
        estimateId: 'estimate-123',
        activity: CostEstimationActivityType.costEstimationCreated,
        user: UserProfile(
          id: 'user-123',
          credentialId: 'cred-123',
          firstName: 'John',
          lastName: 'Doe',
          professionalRole: 'Project Manager',
          profilePhotoUrl: null,
        ),
        activityDetails: {},
        loggedAt: DateTime(2025, 4, 22, 12, 30),
      );
    });

    Widget createWidget(CostEstimationLog log, {ThemeData? theme}) {
      return MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CostEstimationLogTile(log: log, onTap: () {}),
        ),
      );
    }

    testWidgets('meets tap target and label guidelines in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(testLog, theme: theme),
        find.byType(CostEstimationLogTile),
      );
    });

    testWidgets('meets tap target and label guidelines for created activity', (
      tester,
    ) async {
      await setupA11yTest(tester);

      final log = testLog.copyWith(
        activity: CostEstimationActivityType.costEstimationCreated,
      );

      await tester.pumpWidget(createWidget(log, theme: createTestTheme()));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationLogTile),
      );
    });

    testWidgets('meets tap target and label guidelines for renamed activity', (
      tester,
    ) async {
      await setupA11yTest(tester);

      final log = testLog.copyWith(
        activity: CostEstimationActivityType.costEstimationRenamed,
        activityDetails: {'oldName': 'Old Project', 'newName': 'New Project'},
      );

      await tester.pumpWidget(createWidget(log, theme: createTestTheme()));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationLogTile),
      );
    });

    testWidgets(
      'meets tap target and label guidelines for cost file uploaded activity',
      (tester) async {
        await setupA11yTest(tester);

        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costFileUploaded,
          activityDetails: {
            'fileName': 'materials.xlsx',
            'oldQuantity': 12,
            'newQuantity': 15,
          },
        );

        await tester.pumpWidget(createWidget(log, theme: createTestTheme()));
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelines(
          tester,
          find.byType(CostEstimationLogTile),
        );
      },
    );

    testWidgets('meets tap target and label guidelines for task assigned', (
      tester,
    ) async {
      await setupA11yTest(tester);

      final log = testLog.copyWith(
        activity: CostEstimationActivityType.taskAssigned,
        activityDetails: {
          'taskName': 'Review Budget',
          'assigneeName': 'Jane Smith',
        },
      );

      await tester.pumpWidget(createWidget(log, theme: createTestTheme()));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationLogTile),
      );
    });

    testWidgets('meets tap target and label guidelines for locked activity', (
      tester,
    ) async {
      await setupA11yTest(tester);

      final log = testLog.copyWith(
        activity: CostEstimationActivityType.costEstimationLocked,
      );

      await tester.pumpWidget(createWidget(log, theme: createTestTheme()));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationLogTile),
      );
    });

    testWidgets('meets tap target and label guidelines for exported activity', (
      tester,
    ) async {
      await setupA11yTest(tester);

      final log = testLog.copyWith(
        activity: CostEstimationActivityType.costEstimationExported,
      );

      await tester.pumpWidget(createWidget(log, theme: createTestTheme()));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationLogTile),
      );
    });

    testWidgets(
      'meets tap target and label guidelines for attachment added activity',
      (tester) async {
        await setupA11yTest(tester);

        final log = testLog.copyWith(
          activity: CostEstimationActivityType.attachmentAdded,
          activityDetails: {'fileName': 'blueprint.pdf'},
        );

        await tester.pumpWidget(createWidget(log, theme: createTestTheme()));
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelines(
          tester,
          find.byType(CostEstimationLogTile),
        );
      },
    );

    testWidgets('meets tap target and label guidelines with long user name', (
      tester,
    ) async {
      await setupA11yTest(tester);

      final log = testLog.copyWith(
        user: UserProfile(
          id: 'user-123',
          credentialId: 'cred-123',
          firstName: 'Christopher',
          lastName: 'Montgomery-Wellington',
          professionalRole: 'Project Manager',
          profilePhotoUrl: null,
        ),
      );

      await tester.pumpWidget(createWidget(log, theme: createTestTheme()));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationLogTile),
      );
    });
  });
}

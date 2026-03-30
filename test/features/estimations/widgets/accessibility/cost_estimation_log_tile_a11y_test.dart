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
        home: Scaffold(body: CostEstimationLogTile(log: log)),
      );
    }

    testWidgets('a11y: tile passes in both themes', (tester) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => createWidget(testLog, theme: theme),
        find.byType(CostEstimationLogTile),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });

    testWidgets('a11y: created activity passes', (tester) async {
      await setupA11yTest(tester);

      final log = testLog.copyWith(
        activity: CostEstimationActivityType.costEstimationCreated,
      );

      await tester.pumpWidget(createWidget(log, theme: createTestTheme()));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationLogTile),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });

    testWidgets('a11y: renamed activity passes', (tester) async {
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
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });

    testWidgets('a11y: cost file uploaded activity passes', (tester) async {
      await setupA11yTest(tester);

      final log = testLog.copyWith(
        activity: CostEstimationActivityType.costFileUploaded,
        activityDetails: {'fileName': 'materials.xlsx'},
      );

      await tester.pumpWidget(createWidget(log, theme: createTestTheme()));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationLogTile),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });

    testWidgets('a11y: task assigned activity passes', (tester) async {
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
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });

    testWidgets('a11y: locked activity passes', (tester) async {
      await setupA11yTest(tester);

      final log = testLog.copyWith(
        activity: CostEstimationActivityType.costEstimationLocked,
      );

      await tester.pumpWidget(createWidget(log, theme: createTestTheme()));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationLogTile),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });

    testWidgets('a11y: exported activity passes', (tester) async {
      await setupA11yTest(tester);

      final log = testLog.copyWith(
        activity: CostEstimationActivityType.costEstimationExported,
      );

      await tester.pumpWidget(createWidget(log, theme: createTestTheme()));
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelines(
        tester,
        find.byType(CostEstimationLogTile),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });

    testWidgets('a11y: attachment added activity passes', (tester) async {
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
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });

    testWidgets('a11y: long user name layout passes', (tester) async {
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
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });
  });
}

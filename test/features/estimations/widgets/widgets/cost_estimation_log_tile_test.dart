import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_log_tile.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  group('CostEstimationLogTile', () {
    late CostEstimationLog testLog;
    late UserProfile testUser;
    BuildContext? buildContext;

    setUp(() {
      testUser = UserProfile(
        id: 'user-123',
        credentialId: 'cred-123',
        firstName: 'John',
        lastName: 'Doe',
        professionalRole: 'Project Manager',
        profilePhotoUrl: null,
      );

      testLog = CostEstimationLog(
        id: 'log-123',
        estimateId: 'estimate-123',
        activity: CostEstimationActivityType.costEstimationCreated,
        user: testUser,
        activityDetails: {},
        loggedAt: DateTime(2025, 4, 22, 12, 30),
      );
    });

    Widget createWidget(CostEstimationLog log) {
      return MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              buildContext = context;
              return CostEstimationLogTile(log: log);
            },
          ),
        ),
      );
    }

    AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

    Finder richTextContaining(String value) {
      return find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains(value),
        description: 'RichText containing "$value"',
      );
    }

    group('Basic Rendering', () {
      testWidgets('renders user avatar with first initial', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        expect(find.byKey(const Key('avatar')), findsOneWidget);
        expect(find.text('J'), findsOneWidget);
      });

      testWidgets('renders activity title', (tester) async {
        await tester.pumpWidget(createWidget(testLog));
        final localization = l10n();

        expect(find.byKey(const Key('activityTitle')), findsOneWidget);
        expect(
          find.text(localization.activityCostEstimationCreated),
          findsOneWidget,
        );
      });

      testWidgets('renders date and time', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        expect(find.byKey(const Key('dateText')), findsOneWidget);
        expect(find.byKey(const Key('timeText')), findsOneWidget);
      });

      testWidgets('renders user first name only', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        expect(find.byKey(const Key('userName')), findsOneWidget);
        expect(find.text('John'), findsOneWidget);
      });

      testWidgets('renders activity icon', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        expect(find.byKey(const Key('activityIcon')), findsOneWidget);
      });

      testWidgets('renders calendar icon', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        expect(find.byKey(const Key('calendarIcon')), findsOneWidget);
      });
    });

    group('Activity Title Generation', () {
      testWidgets('displays created activity title', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationCreated,
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          find.text(localization.activityCostEstimationCreated),
          findsOneWidget,
        );
      });

      testWidgets('displays renamed activity title', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationRenamed,
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          find.text(localization.activityCostEstimationRenamed),
          findsOneWidget,
        );
      });

      testWidgets('displays cost item added with item name', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costItemAdded,
          activityDetails: {'itemName': 'Concrete Foundation'},
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          find.text(localization.activityCostItemAdded('Concrete Foundation')),
          findsOneWidget,
        );
      });

      testWidgets('displays cost item added without item name', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costItemAdded,
          activityDetails: {},
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          find.text(localization.activityCostItemAddedSimple),
          findsOneWidget,
        );
      });

      testWidgets('displays cost file uploaded with filename', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costFileUploaded,
          activityDetails: {'fileName': 'materials.xlsx'},
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          find.text(localization.activityCostFileUploaded('materials.xlsx')),
          findsOneWidget,
        );
      });

      testWidgets('displays task assigned with details', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.taskAssigned,
          activityDetails: {
            'taskName': 'Review Budget',
            'assigneeName': 'Jane Smith',
          },
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          find.text(
            localization.activityTaskAssigned('Review Budget', 'Jane Smith'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('displays locked activity', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationLocked,
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          find.text(localization.activityCostEstimationLocked),
          findsOneWidget,
        );
      });

      testWidgets('displays unlocked activity', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationUnlocked,
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          find.text(localization.activityCostEstimationUnlocked),
          findsOneWidget,
        );
      });

      testWidgets('displays exported activity', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationExported,
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          find.text(localization.activityCostEstimationExported),
          findsOneWidget,
        );
      });

      testWidgets('displays attachment added with file name', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.attachmentAdded,
          activityDetails: {'fileName': 'blueprint.pdf'},
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          find.text(localization.activityAttachmentAdded('blueprint.pdf')),
          findsOneWidget,
        );
      });
    });

    group('Subtitle Rendering', () {
      testWidgets('displays renamed subtitle with from/to values', (
        tester,
      ) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationRenamed,
          activityDetails: {'oldName': 'Old Project', 'newName': 'New Project'},
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(richTextContaining(localization.activityFrom), findsOneWidget);
        expect(richTextContaining(localization.activityTo), findsOneWidget);
        expect(richTextContaining('Old Project'), findsOneWidget);
        expect(richTextContaining('New Project'), findsOneWidget);
      });

      testWidgets('displays exported subtitle with format', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationExported,
          activityDetails: {'format': 'PDF'},
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          richTextContaining(localization.activityExportFormat),
          findsOneWidget,
        );
        expect(richTextContaining('PDF'), findsOneWidget);
      });

      testWidgets('displays cost item added subtitle with item type', (
        tester,
      ) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costItemAdded,
          activityDetails: {'itemType': 'Material'},
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          richTextContaining(localization.activityItemType),
          findsOneWidget,
        );
        expect(richTextContaining('Material'), findsOneWidget);
      });

      testWidgets('displays edited fields subtitle', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costItemEdited,
          activityDetails: {
            'editedFields': {
              'quantity': {'oldValue': 10, 'newValue': 15},
              'unit_price': {'oldValue': 20.0, 'newValue': 25.0},
            },
          },
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          richTextContaining(localization.activityEditedFieldQuantity),
          findsOneWidget,
        );
        expect(
          richTextContaining(localization.activityEditedFieldUnitPrice),
          findsOneWidget,
        );
        expect(richTextContaining('10'), findsOneWidget);
        expect(richTextContaining('15'), findsOneWidget);
      });

      testWidgets('displays task assigned subtitle with task and assignee', (
        tester,
      ) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.taskAssigned,
          activityDetails: {
            'taskName': 'Review Budget',
            'assigneeName': 'Jane Smith',
          },
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(richTextContaining(localization.activityFrom), findsOneWidget);
        expect(richTextContaining(localization.activityTo), findsOneWidget);
        expect(richTextContaining('Review Budget'), findsWidgets);
        expect(richTextContaining('Jane Smith'), findsWidgets);
      });

      testWidgets('displays task unassigned subtitle', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.taskUnassigned,
          activityDetails: {'taskName': 'Approval'},
        );

        await tester.pumpWidget(createWidget(log));

        expect(richTextContaining('Task: '), findsOneWidget);
        expect(richTextContaining('Approval'), findsWidgets);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles user with single character first name', (
        tester,
      ) async {
        final log = testLog.copyWith(
          user: testUser.copyWith(firstName: 'A', lastName: 'B'),
        );

        await tester.pumpWidget(createWidget(log));

        expect(
          find.descendant(
            of: find.byKey(const Key('avatar')),
            matching: find.text('A'),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('userName')), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('userName'))).data,
          'A',
        );
      });

      testWidgets('handles user with very long name', (tester) async {
        final log = testLog.copyWith(
          user: testUser.copyWith(
            firstName: 'Christopher',
            lastName: 'Montgomery-Wellington',
          ),
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.text('C'), findsOneWidget);
        expect(find.text('Christopher'), findsOneWidget);
      });

      testWidgets('handles empty firstName with fallback', (tester) async {
        final log = testLog.copyWith(
          user: testUser.copyWith(firstName: '', lastName: 'Doe'),
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.text('?'), findsOneWidget);
      });

      testWidgets('handles activity with missing subtitle details', (
        tester,
      ) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationRenamed,
          activityDetails: {},
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          find.text(localization.activityCostEstimationRenamed),
          findsOneWidget,
        );
      });

      testWidgets('handles task assigned with missing assignee', (
        tester,
      ) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.taskAssigned,
          activityDetails: {'taskName': 'Review Budget'},
        );

        await tester.pumpWidget(createWidget(log));
        final localization = l10n();

        expect(
          find.text(localization.activityTaskAssigned('Review Budget', '')),
          findsNothing,
        );
      });
    });
  });
}

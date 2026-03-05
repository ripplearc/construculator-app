import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_log_tile.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  group('CostEstimationLogTile', () {
    late CostEstimationLog testLog;
    late UserProfile testUser;

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

    Widget createWidget(CostEstimationLog log, {VoidCallback? onTap}) {
      return MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CostEstimationLogTile(log: log, onTap: onTap),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('renders user avatar with initials', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        expect(find.byKey(const Key('userAvatar')), findsOneWidget);
        expect(find.text('JD'), findsOneWidget);
      });

      testWidgets('renders avatar with profile photo when available', (
        tester,
      ) async {
        final logWithPhoto = testLog.copyWith(
          user: testUser.copyWith(
            profilePhotoUrl: 'https://example.com/photo.jpg',
          ),
        );

        await tester.pumpWidget(createWidget(logWithPhoto));

        final avatar = tester.widget<CoreAvatar>(
          find.byKey(const Key('userAvatar')),
        );
        expect(avatar.image, isNotNull);
        expect(avatar.image, isA<NetworkImage>());
      });

      testWidgets('renders activity title', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        expect(find.byKey(const Key('activityTitle')), findsOneWidget);
        expect(find.text('Cost Estimation Created'), findsOneWidget);
      });

      testWidgets('renders date and time', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        expect(find.byKey(const Key('dateText')), findsOneWidget);
        expect(find.byKey(const Key('timeText')), findsOneWidget);
      });

      testWidgets('renders user name', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        expect(find.byKey(const Key('userName')), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
      });

      testWidgets('renders chevron icon', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        expect(find.byKey(const Key('chevronIcon')), findsOneWidget);
        final icon = tester.widget<Icon>(find.byKey(const Key('chevronIcon')));
        expect(icon.icon, equals(Icons.chevron_right));
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

        expect(find.text('Cost Estimation Created'), findsOneWidget);
      });

      testWidgets('displays renamed activity with details', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationRenamed,
          activityDetails: {'oldName': 'Old Project', 'newName': 'New Project'},
        );

        await tester.pumpWidget(createWidget(log));

        expect(
          find.textContaining('Renamed from Old Project to New Project'),
          findsOneWidget,
        );
      });

      testWidgets('displays renamed activity without details', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationRenamed,
          activityDetails: {},
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.text('Cost Estimation Renamed'), findsOneWidget);
      });

      testWidgets('displays cost item added with item name', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costItemAdded,
          activityDetails: {'itemName': 'Concrete Foundation'},
        );

        await tester.pumpWidget(createWidget(log));

        expect(
          find.textContaining('Added cost item: Concrete Foundation'),
          findsOneWidget,
        );
      });

      testWidgets('displays cost item added without item name', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costItemAdded,
          activityDetails: {},
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.text('Cost Item Added'), findsOneWidget);
      });

      testWidgets('displays cost file uploaded with quantities', (
        tester,
      ) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costFileUploaded,
          activityDetails: {
            'fileName': 'materials.xlsx',
            'oldQuantity': 12,
            'newQuantity': 15,
          },
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.textContaining('Cost File Copied'), findsOneWidget);
        expect(find.textContaining('Qty 12'), findsOneWidget);
        expect(find.textContaining('Qty 15'), findsOneWidget);
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

        expect(
          find.textContaining('Task Review Budget assigned to Jane Smith'),
          findsOneWidget,
        );
      });

      testWidgets('displays locked activity', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationLocked,
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.text('Cost Estimation Locked'), findsOneWidget);
      });

      testWidgets('displays unlocked activity', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationUnlocked,
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.text('Cost Estimation Unlocked'), findsOneWidget);
      });

      testWidgets('displays exported activity', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costEstimationExported,
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.text('Cost Estimation Exported'), findsOneWidget);
      });

      testWidgets('displays attachment added with file name', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.attachmentAdded,
          activityDetails: {'fileName': 'blueprint.pdf'},
        );

        await tester.pumpWidget(createWidget(log));

        expect(
          find.textContaining('Attachment added: blueprint.pdf'),
          findsOneWidget,
        );
      });
    });

    group('Tap Callbacks', () {
      testWidgets('calls onTap when tile is tapped', (tester) async {
        var tapCount = 0;
        await tester.pumpWidget(createWidget(testLog, onTap: () => tapCount++));

        await tester.tap(find.byType(CostEstimationLogTile));
        expect(tapCount, equals(1));
      });

      testWidgets('does not throw when onTap is null', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        await tester.tap(find.byType(CostEstimationLogTile));
        // Should not throw
      });

      testWidgets('tap works on gesture detector', (tester) async {
        var tapCount = 0;
        await tester.pumpWidget(createWidget(testLog, onTap: () => tapCount++));

        await tester.tap(find.byKey(const Key('logTileGestureDetector')));
        expect(tapCount, equals(1));
      });
    });

    group('Edge Cases', () {
      testWidgets('handles user with single character names', (tester) async {
        final log = testLog.copyWith(
          user: testUser.copyWith(firstName: 'A', lastName: 'B'),
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.text('AB'), findsOneWidget);
        expect(find.text('A B'), findsOneWidget);
      });

      testWidgets('handles user with very long name', (tester) async {
        final log = testLog.copyWith(
          user: testUser.copyWith(
            firstName: 'Christopher',
            lastName: 'Montgomery-Wellington',
          ),
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.text('CM'), findsOneWidget);
        expect(find.text('Christopher Montgomery-Wellington'), findsOneWidget);

        final nameText = tester.widget<Text>(find.byKey(const Key('userName')));
        expect(nameText.maxLines, equals(1));
        expect(nameText.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('handles activity with missing details gracefully', (
        tester,
      ) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costFileUploaded,
          activityDetails: {},
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.text('Cost File Uploaded'), findsOneWidget);
      });

      testWidgets('handles activity with partial details', (tester) async {
        final log = testLog.copyWith(
          activity: CostEstimationActivityType.costFileUploaded,
          activityDetails: {
            'fileName': 'materials.xlsx',
            // missing oldQuantity and newQuantity
          },
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.text('Cost File Uploaded'), findsOneWidget);
      });

      testWidgets('handles different date times correctly', (tester) async {
        final log = testLog.copyWith(loggedAt: DateTime(2025, 12, 31, 23, 59));

        await tester.pumpWidget(createWidget(log));

        expect(find.byKey(const Key('dateText')), findsOneWidget);
        expect(find.byKey(const Key('timeText')), findsOneWidget);
      });

      testWidgets('handles user with empty profile photo URL', (tester) async {
        final log = testLog.copyWith(
          user: testUser.copyWith(profilePhotoUrl: ''),
        );

        await tester.pumpWidget(createWidget(log));

        expect(find.byKey(const Key('userAvatar')), findsOneWidget);
        expect(find.text('JD'), findsOneWidget);
      });
    });

    group('Layout and Styling', () {
      testWidgets('applies correct padding to container', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        final container = tester.widget<Container>(
          find
              .ancestor(
                of: find.byKey(const Key('userAvatar')),
                matching: find.byType(Container),
              )
              .first,
        );

        expect(
          container.padding,
          equals(
            EdgeInsets.symmetric(
              horizontal: CoreSpacing.space4,
              vertical: CoreSpacing.space4,
            ),
          ),
        );
      });

      testWidgets('uses correct cross-axis alignment', (tester) async {
        await tester.pumpWidget(createWidget(testLog));

        final row = tester.widget<Row>(
          find
              .descendant(
                of: find.byType(CostEstimationLogTile),
                matching: find.byType(Row),
              )
              .first,
        );

        expect(row.crossAxisAlignment, equals(CrossAxisAlignment.start));
      });

      testWidgets('renders subtitle row with correct alignment', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(testLog));

        expect(find.byKey(const Key('calendarIcon')), findsOneWidget);
        expect(find.byKey(const Key('dateText')), findsOneWidget);
        expect(find.byKey(const Key('timeText')), findsOneWidget);
        expect(find.byKey(const Key('userName')), findsOneWidget);

        final userName = tester.widget<Text>(find.byKey(const Key('userName')));
        expect(userName.textAlign, equals(TextAlign.right));
      });
    });
  });
}

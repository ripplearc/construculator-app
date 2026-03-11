import 'package:construculator/features/estimation/domain/entities/cost_estimation_activity_type.dart';
import 'package:construculator/features/estimation/domain/entities/cost_estimation_log_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_log_tile.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const Size size = Size(390.0, 100.0);
  const double ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  group('CostEstimationLogTile Screenshot Tests', () {
    Future<void> pumpLogTile({
      required WidgetTester tester,
      required CostEstimationLog log,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Material(
                color: context.colorTheme.pageBackground,
                child: CostEstimationLogTile(log: log),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    UserProfile createTestUser({
      required String firstName,
      required String lastName,
      String? profilePhotoUrl,
    }) {
      return UserProfile(
        id: 'user-123',
        credentialId: 'cred-123',
        firstName: firstName,
        lastName: lastName,
        professionalRole: 'Project Manager',
        profilePhotoUrl: profilePhotoUrl,
      );
    }

    CostEstimationLog createTestLog({
      required CostEstimationActivityType activity,
      required UserProfile user,
      required DateTime loggedAt,
      Map<String, dynamic> activityDetails = const {},
    }) {
      return CostEstimationLog(
        id: 'log-123',
        estimateId: 'estimate-123',
        activity: activity,
        user: user,
        activityDetails: activityDetails,
        loggedAt: loggedAt,
      );
    }

    testWidgets('renders estimation created activity correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      final user = createTestUser(firstName: 'Mahesh', lastName: 'Kumar');

      final log = createTestLog(
        activity: CostEstimationActivityType.costEstimationCreated,
        user: user,
        loggedAt: DateTime(2025, 4, 22, 12, 3),
      );

      await pumpLogTile(tester: tester, log: log);

      await expectLater(
        find.byType(CostEstimationLogTile),
        matchesGoldenFile(
          'goldens/cost_estimation_log_tile/${size.width}x${size.height}/log_tile_created.png',
        ),
      );
    });

    testWidgets('renders cost file uploaded activity correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      final user = createTestUser(firstName: 'Mahesh', lastName: 'Kumar');

      final log = createTestLog(
        activity: CostEstimationActivityType.costFileUploaded,
        user: user,
        loggedAt: DateTime(2025, 4, 22, 12, 3),
        activityDetails: {'fileName': 'materials.xlsx'},
      );

      await pumpLogTile(tester: tester, log: log);

      await expectLater(
        find.byType(CostEstimationLogTile),
        matchesGoldenFile(
          'goldens/cost_estimation_log_tile/${size.width}x${size.height}/log_tile_file_uploaded.png',
        ),
      );
    });

    testWidgets('renders renamed activity with details correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390.0, 120.0);
      tester.view.devicePixelRatio = ratio;

      final user = createTestUser(firstName: 'John', lastName: 'Smith');

      final log = createTestLog(
        activity: CostEstimationActivityType.costEstimationRenamed,
        user: user,
        loggedAt: DateTime(2025, 3, 15, 10, 30),
        activityDetails: {
          'oldName': 'Old Project',
          'newName': 'Renovated Building',
        },
      );

      await pumpLogTile(tester: tester, log: log);

      await expectLater(
        find.byType(CostEstimationLogTile),
        matchesGoldenFile(
          'goldens/cost_estimation_log_tile/390.0x120.0/log_tile_renamed.png',
        ),
      );
    });

    testWidgets('renders locked activity correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      final user = createTestUser(firstName: 'Alice', lastName: 'Johnson');

      final log = createTestLog(
        activity: CostEstimationActivityType.costEstimationLocked,
        user: user,
        loggedAt: DateTime(2025, 5, 1, 14, 20),
      );

      await pumpLogTile(tester: tester, log: log);

      await expectLater(
        find.byType(CostEstimationLogTile),
        matchesGoldenFile(
          'goldens/cost_estimation_log_tile/${size.width}x${size.height}/log_tile_locked.png',
        ),
      );
    });

    testWidgets('renders cost item added activity with details correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390.0, 120.0);
      tester.view.devicePixelRatio = ratio;

      final user = createTestUser(firstName: 'Bob', lastName: 'Williams');

      final log = createTestLog(
        activity: CostEstimationActivityType.costItemAdded,
        user: user,
        loggedAt: DateTime(2025, 2, 10, 9, 15),
        activityDetails: {
          'itemName': 'Concrete Foundation',
          'itemType': 'Material',
        },
      );

      await pumpLogTile(tester: tester, log: log);

      await expectLater(
        find.byType(CostEstimationLogTile),
        matchesGoldenFile(
          'goldens/cost_estimation_log_tile/390.0x120.0/log_tile_item_added.png',
        ),
      );
    });

    testWidgets('renders task assigned activity with details correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390.0, 120.0);
      tester.view.devicePixelRatio = ratio;

      final user = createTestUser(firstName: 'Sarah', lastName: 'Davis');

      final log = createTestLog(
        activity: CostEstimationActivityType.taskAssigned,
        user: user,
        loggedAt: DateTime(2025, 6, 5, 11, 45),
        activityDetails: {
          'taskName': 'Review Budget',
          'assigneeName': 'Mike Thompson',
        },
      );

      await pumpLogTile(tester: tester, log: log);

      await expectLater(
        find.byType(CostEstimationLogTile),
        matchesGoldenFile(
          'goldens/cost_estimation_log_tile/390.0x120.0/log_tile_task_assigned.png',
        ),
      );
    });

    testWidgets('renders exported activity with format correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390.0, 120.0);
      tester.view.devicePixelRatio = ratio;

      final user = createTestUser(firstName: 'Emma', lastName: 'Brown');

      final log = createTestLog(
        activity: CostEstimationActivityType.costEstimationExported,
        user: user,
        loggedAt: DateTime(2025, 7, 12, 16, 0),
        activityDetails: {'format': 'PDF'},
      );

      await pumpLogTile(tester: tester, log: log);

      await expectLater(
        find.byType(CostEstimationLogTile),
        matchesGoldenFile(
          'goldens/cost_estimation_log_tile/390.0x120.0/log_tile_exported.png',
        ),
      );
    });

    testWidgets('renders user with long name correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      final user = createTestUser(
        firstName: 'Christopher',
        lastName: 'Montgomery-Wellington',
      );

      final log = createTestLog(
        activity: CostEstimationActivityType.costEstimationUnlocked,
        user: user,
        loggedAt: DateTime(2025, 8, 18, 13, 30),
      );

      await pumpLogTile(tester: tester, log: log);

      await expectLater(
        find.byType(CostEstimationLogTile),
        matchesGoldenFile(
          'goldens/cost_estimation_log_tile/${size.width}x${size.height}/log_tile_long_name.png',
        ),
      );
    });

    testWidgets('renders attachment added activity correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      final user = createTestUser(firstName: 'David', lastName: 'Miller');

      final log = createTestLog(
        activity: CostEstimationActivityType.attachmentAdded,
        user: user,
        loggedAt: DateTime(2025, 9, 25, 15, 10),
        activityDetails: {'fileName': 'blueprint_v2.pdf'},
      );

      await pumpLogTile(tester: tester, log: log);

      await expectLater(
        find.byType(CostEstimationLogTile),
        matchesGoldenFile(
          'goldens/cost_estimation_log_tile/${size.width}x${size.height}/log_tile_attachment_added.png',
        ),
      );
    });

    testWidgets('renders cost item removed activity correctly', (tester) async {
      tester.view.physicalSize = const Size(390.0, 120.0);
      tester.view.devicePixelRatio = ratio;

      final user = createTestUser(firstName: 'Lisa', lastName: 'Anderson');

      final log = createTestLog(
        activity: CostEstimationActivityType.costItemRemoved,
        user: user,
        loggedAt: DateTime(2025, 10, 30, 10, 5),
        activityDetails: {
          'itemName': 'Temporary Scaffolding',
          'itemType': 'Equipment',
        },
      );

      await pumpLogTile(tester: tester, log: log);

      await expectLater(
        find.byType(CostEstimationLogTile),
        matchesGoldenFile(
          'goldens/cost_estimation_log_tile/390.0x120.0/log_tile_item_removed.png',
        ),
      );
    });

    testWidgets('renders cost item edited activity correctly', (tester) async {
      tester.view.physicalSize = const Size(390.0, 140.0);
      tester.view.devicePixelRatio = ratio;

      final user = createTestUser(firstName: 'Mike', lastName: 'Wilson');

      final log = createTestLog(
        activity: CostEstimationActivityType.costItemEdited,
        user: user,
        loggedAt: DateTime(2025, 11, 15, 14, 25),
        activityDetails: {
          'itemName': 'Steel Beams',
          'editedFields': {
            'quantity': {'oldValue': 10, 'newValue': 15},
            'unit_price': {'oldValue': 150.0, 'newValue': 175.0},
          },
        },
      );

      await pumpLogTile(tester: tester, log: log);

      await expectLater(
        find.byType(CostEstimationLogTile),
        matchesGoldenFile(
          'goldens/cost_estimation_log_tile/390.0x140.0/log_tile_item_edited.png',
        ),
      );
    });
  });
}

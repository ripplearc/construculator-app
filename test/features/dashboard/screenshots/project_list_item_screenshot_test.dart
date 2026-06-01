import 'package:construculator/features/dashboard/presentation/widgets/project_list_item.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 180);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  Project buildProject({
    String id = 'project-1',
    String projectName = 'My project',
  }) {
    return Project(
      id: id,
      projectName: projectName,
      creatorUserId: 'user-1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 4, 29, 18, 11),
      status: ProjectStatus.active,
    );
  }

  setUp(() async {
    await loadAppFontsAll();
  });

  group('ProjectListItem Screenshot Tests', () {
    Future<void> pumpProjectListItem({
      required WidgetTester tester,
      required Project project,
      bool isSelected = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Material(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ProjectListItem(
                  project: project,
                  isSelected: isSelected,
                  onTap: () {},
                  onSettingsTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders base project list item correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpProjectListItem(tester: tester, project: buildProject());

      await expectLater(
        find.byType(ProjectListItem),
        matchesGoldenFile(
          'goldens/project_list_item/${size.width}x${size.height}/project_list_item_base.png',
        ),
      );
    });

    testWidgets('renders selected project list item correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpProjectListItem(
        tester: tester,
        project: buildProject(),
        isSelected: true,
      );

      await expectLater(
        find.byType(ProjectListItem),
        matchesGoldenFile(
          'goldens/project_list_item/${size.width}x${size.height}/project_list_item_selected.png',
        ),
      );
    });

    testWidgets('renders project list item with long name correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpProjectListItem(
        tester: tester,
        project: buildProject(
          projectName: 'Complete Home Renovation and Extension Project Phase 2',
        ),
      );

      await expectLater(
        find.byType(ProjectListItem),
        matchesGoldenFile(
          'goldens/project_list_item/${size.width}x${size.height}/project_list_item_long_name.png',
        ),
      );
    });
  });
}

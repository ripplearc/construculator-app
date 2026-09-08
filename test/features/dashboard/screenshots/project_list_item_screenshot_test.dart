import 'package:construculator/features/dashboard/presentation/widgets/project_list_item.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 180);
  const ratio = 1.0;
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

  setUpAll(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpProjectListItem({
    required WidgetTester tester,
    required Project project,
    required ThemeData theme,
    bool isSelected = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
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
                onSettingsTap: () async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('ProjectListItem Screenshot Tests', (theme, suffix) {
    testWidgets('renders base project list item correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectListItem(
        tester: tester,
        project: buildProject(),
        theme: theme,
      );

      await expectLater(
        find.byType(ProjectListItem),
        matchesGoldenFile(
          'goldens/project_list_item/${size.width}x${size.height}/project_list_item_base$suffix.png',
        ),
      );
    });

    testWidgets('renders selected project list item correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectListItem(
        tester: tester,
        project: buildProject(),
        isSelected: true,
        theme: theme,
      );

      await expectLater(
        find.byType(ProjectListItem),
        matchesGoldenFile(
          'goldens/project_list_item/${size.width}x${size.height}/project_list_item_selected$suffix.png',
        ),
      );
    });

    testWidgets('renders project list item with long name correctly', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectListItem(
        tester: tester,
        project: buildProject(
          projectName: 'Complete Home Renovation and Extension Project Phase 2',
        ),
        theme: theme,
      );

      await expectLater(
        find.byType(ProjectListItem),
        matchesGoldenFile(
          'goldens/project_list_item/${size.width}x${size.height}/project_list_item_long_name$suffix.png',
        ),
      );
    });
  });
}

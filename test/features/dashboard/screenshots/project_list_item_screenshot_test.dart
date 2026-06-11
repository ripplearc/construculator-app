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
    bool isSelected = false,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
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

  group('ProjectListItem Screenshot Tests - Light', () {
    testWidgets('renders base project list item correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

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
      addTearDown(tester.view.reset);

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
      addTearDown(tester.view.reset);

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

  group('ProjectListItem Screenshot Tests - Dark', () {
    testWidgets('renders base project list item correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpProjectListItem(
        tester: tester,
        project: buildProject(),
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(ProjectListItem),
        matchesGoldenFile(
          'goldens/project_list_item/${size.width}x${size.height}/project_list_item_base_dark.png',
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
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(ProjectListItem),
        matchesGoldenFile(
          'goldens/project_list_item/${size.width}x${size.height}/project_list_item_selected_dark.png',
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
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(ProjectListItem),
        matchesGoldenFile(
          'goldens/project_list_item/${size.width}x${size.height}/project_list_item_long_name_dark.png',
        ),
      );
    });
  });
}

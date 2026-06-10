import 'package:construculator/features/dashboard/presentation/widgets/projects_bottom_sheet.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../projects_bottom_sheet_test_harness.dart';

void main() {
  final size = const Size(390, 660);
  const ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  final harness = ProjectsBottomSheetTestHarness();

  Project buildProject({required String id, required String projectName}) {
    return Project(
      id: id,
      projectName: projectName,
      creatorUserId: ProjectsBottomSheetTestHarness.testUserId,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 4, 29, 18, 11),
      status: ProjectStatus.active,
    );
  }

  setUpAll(() async {
    await harness.setUpAll();
  });

  setUp(() {
    harness.setUp();
  });

  tearDown(() {
    harness.tearDown();
  });

  group('ProjectsBottomSheet Screenshot Tests', () {
    testWidgets('renders loaded project list', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      harness.fakeRepository.setAccessibleProjects([
        buildProject(id: 'project-1', projectName: 'My project'),
        buildProject(id: 'project-2', projectName: 'Material of building'),
        buildProject(id: 'project-3', projectName: 'MD bungalow'),
      ]);

      // Extra 100ms pump lets the golden render stabilise before capture.
      await harness.pumpSheet(
        tester,
        extraPump: const Duration(milliseconds: 100),
      );

      await expectLater(
        find.byType(ProjectsBottomSheet),
        matchesGoldenFile(
          'goldens/projects_bottom_sheet/${size.width}x${size.height}/projects_bottom_sheet_loaded.png',
        ),
      );
    });

    testWidgets('renders empty state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      harness.fakeRepository.setAccessibleProjects([]);

      await harness.pumpSheet(
        tester,
        extraPump: const Duration(milliseconds: 100),
      );

      await expectLater(
        find.byType(ProjectsBottomSheet),
        matchesGoldenFile(
          'goldens/projects_bottom_sheet/${size.width}x${size.height}/projects_bottom_sheet_empty.png',
        ),
      );
    });
  });
}

import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/project_settings/domain/entities/project_entity.dart';
import 'package:construculator/features/project_settings/domain/entities/enums.dart';
import 'package:construculator/features/project_settings/testing/fake_project_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../font_loader.dart';
import '../await_images_extension.dart';

ImageProvider _createTestAvatarImage() {
  return const AssetImage('assets/icons/app_icon.png');
}

void main() {
  final size = const Size(390, 56);
  final ratio = 1.0;
  final testName = 'project_header_app_bar';
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeProjectRepository fakeProjectRepository;

  setUp(() async {
    await loadAppFonts();
    fakeProjectRepository = FakeProjectRepository();
  });

  group('ProjectHeaderAppBar Screenshot Tests', () {
    Future<void> pumpProjectHeaderAppBar({
      required WidgetTester tester,
      required String projectId,
      required String projectName,
      VoidCallback? onProjectTap,
      VoidCallback? onSearchTap,
      VoidCallback? onNotificationTap,
      ImageProvider? avatarImage,
    }) async {
      // Create and configure the project
      final project = Project(
        id: projectId,
        projectName: projectName,
        creatorUserId: 'user-id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ProjectStatus.active,
      );

      // Configure the repository before creating the widget
      fakeProjectRepository.addProject(projectId, project);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ProjectHeaderAppBar(
              projectId: projectId,
              onProjectTap: onProjectTap,
              onSearchTap: onSearchTap,
              onNotificationTap: onNotificationTap,
              avatarImage: avatarImage,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      await tester.awaitImages();
    }

    testWidgets('renders project header app bar with normal name correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      
      await pumpProjectHeaderAppBar(
        tester: tester,
        projectId: 'project-id',
        projectName: 'Kitchen Renovation',
        onProjectTap: () {},
        onSearchTap: () {},
        onNotificationTap: () {},
        avatarImage: _createTestAvatarImage(),
      );

      await expectLater(
        find.byType(ProjectHeaderAppBar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_normal.png',
        ),
      );
    });

    testWidgets('renders project header app bar with long name correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      
      await pumpProjectHeaderAppBar(
        tester: tester,
        projectId: 'project-id-2',
        projectName: 'Complete Home Renovation and Extension Project',
        onProjectTap: () {},
        onSearchTap: () {},
        onNotificationTap: () {},
        avatarImage: _createTestAvatarImage(),
      );

      await expectLater(
        find.byType(ProjectHeaderAppBar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_long_name.png',
        ),
      );
    });

    testWidgets('renders project header app bar without avatar correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      
      await pumpProjectHeaderAppBar(
        tester: tester,
        projectId: 'project-id-3',
        projectName: 'Bathroom Remodel',
        onProjectTap: () {},
        onSearchTap: () {},
        onNotificationTap: () {},
      );

      await expectLater(
        find.byType(ProjectHeaderAppBar),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_no_avatar.png',
        ),
      );
    });
  });
}

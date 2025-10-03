import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/project_settings/domain/entities/project_entity.dart';
import 'package:construculator/features/project_settings/domain/entities/enums.dart';
import 'package:construculator/features/project_settings/testing/fake_project_repository.dart';
import 'package:construculator/features/project_settings/testing/project_settings_test_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../font_loader.dart';
import '../await_images_extension.dart';

void main() {
  final size = const Size(390, 56);
  final ratio = 1.0;
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
      String? avatarUrl,
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
        ModularApp(
          module: ProjectSettingsTestModule(fakeProjectRepository),
          child: MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(
                projectId: projectId,
                onProjectTap: onProjectTap,
                onSearchTap: onSearchTap,
                onNotificationTap: onNotificationTap,
                avatarUrl: avatarUrl,
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // Wait for asset images to load
      await tester.awaitImages();
    }

    testWidgets('renders project header app bar with normal name correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      
      // Mock network images to avoid loading issues
      await mockNetworkImagesFor(() async {
        await pumpProjectHeaderAppBar(
          tester: tester,
          projectId: 'test-project-1',
          projectName: 'Kitchen Renovation',
          onProjectTap: () {},
          onSearchTap: () {},
          onNotificationTap: () {},
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        await expectLater(
          find.byType(ProjectHeaderAppBar),
          matchesGoldenFile(
            'goldens/project_header_app_bar/${size.width}x${size.height}/project_header_app_bar_normal.png',
          ),
        );
      });
    });

    testWidgets('renders project header app bar with long name correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      
      // Mock network images to avoid loading issues
      await mockNetworkImagesFor(() async {
        await pumpProjectHeaderAppBar(
          tester: tester,
          projectId: 'test-project-2',
          projectName: 'Complete Home Renovation and Extension Project',
          onProjectTap: () {},
          onSearchTap: () {},
          onNotificationTap: () {},
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        await expectLater(
          find.byType(ProjectHeaderAppBar),
          matchesGoldenFile(
            'goldens/project_header_app_bar/${size.width}x${size.height}/project_header_app_bar_long_name.png',
          ),
        );
      });
    });

    testWidgets('renders project header app bar without avatar correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      
      // Mock network images to avoid loading issues
      await mockNetworkImagesFor(() async {
        await pumpProjectHeaderAppBar(
          tester: tester,
          projectId: 'test-project-3',
          projectName: 'Bathroom Remodel',
          onProjectTap: () {},
          onSearchTap: () {},
          onNotificationTap: () {},
          avatarUrl: null,
        );

        await expectLater(
          find.byType(ProjectHeaderAppBar),
          matchesGoldenFile(
            'goldens/project_header_app_bar/${size.width}x${size.height}/project_header_app_bar_no_avatar.png',
          ),
        );
      });
    });
  });
}

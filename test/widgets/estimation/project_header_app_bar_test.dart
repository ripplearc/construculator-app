import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/project_settings/domain/entities/project_entity.dart';
import 'package:construculator/features/project_settings/domain/entities/enums.dart';
import 'package:construculator/features/project_settings/testing/fake_project_repository.dart';
import 'package:construculator/features/project_settings/testing/project_settings_test_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:flutter_modular/flutter_modular.dart';


void main() {
  group('ProjectHeaderAppBar', () {
    late FakeProjectRepository fakeProjectRepository;

    setUp(() {
      fakeProjectRepository = FakeProjectRepository();
    });

    testWidgets('renders with project data loaded successfully', (WidgetTester tester) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      
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

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(projectId: projectId),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(projectName), findsOneWidget);
        expect(find.byType(ProjectHeaderAppBar), findsOneWidget);
      });
    });

    testWidgets('displays project name with dropdown arrow', (WidgetTester tester) async {
      const projectId = 'test-project-id';
      const projectName = 'My Construction Project';
      
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

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(projectId: projectId),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(projectName), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      });
    });

    testWidgets('calls onProjectTap when project name is tapped', (WidgetTester tester) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      bool onProjectTapCalled = false;
      
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

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(
                  projectId: projectId,
                  onProjectTap: () => onProjectTapCalled = true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.text(projectName));
        await tester.pumpAndSettle();

        expect(onProjectTapCalled, isTrue);
      });
    });

    testWidgets('calls onSearchTap when search icon is tapped', (WidgetTester tester) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      bool onSearchTapCalled = false;
      
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

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(
                  projectId: projectId,
                  onSearchTap: () => onSearchTapCalled = true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final searchIcon = find.byType(IconButton).first;
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();

        expect(onSearchTapCalled, isTrue);
      });
    });

    testWidgets('calls onNotificationTap when notification icon is tapped', (WidgetTester tester) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      bool onNotificationTapCalled = false;
      
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

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(
                  projectId: projectId,
                  onNotificationTap: () => onNotificationTapCalled = true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final notificationIcon = find.byType(IconButton).at(1);
        await tester.tap(notificationIcon);
        await tester.pumpAndSettle();

        expect(onNotificationTapCalled, isTrue);
      });
    });

    testWidgets('displays network avatar when avatarUrl is provided', (WidgetTester tester) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      const avatarUrl = 'https://example.com/avatar.jpg';
      
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

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(
                  projectId: projectId,
                  avatarUrl: avatarUrl,
                ),
              ),
            ),
          ),
        );

        // Repository is already configured before widget creation

        await tester.pumpAndSettle();
        expect(find.byType(CircleAvatar), findsOneWidget);
        final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
        expect(circleAvatar.backgroundImage, isA<NetworkImage>());
      });
    });

    testWidgets('has correct preferred size', (WidgetTester tester) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      
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

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(projectId: projectId),
              ),
            ),
          ),
        );

        // Repository is already configured before widget creation

        await tester.pumpAndSettle();
        final appBar = tester.widget<ProjectHeaderAppBar>(find.byType(ProjectHeaderAppBar));
        expect(appBar.preferredSize, equals(const Size.fromHeight(kToolbarHeight)));
      });
    });

    testWidgets('renders search and notification icons', (WidgetTester tester) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      
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

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(projectId: projectId),
              ),
            ),
          ),
        );

        // Repository is already configured before widget creation

        await tester.pumpAndSettle();
        expect(find.byType(IconButton), findsNWidgets(2));
        expect(find.byType(Image), findsNWidgets(2));
      });
    });

    testWidgets('handles null callbacks gracefully', (WidgetTester tester) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      
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

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(
                  projectId: projectId,
                  onProjectTap: null,
                  onSearchTap: null,
                  onNotificationTap: null,
                ),
              ),
            ),
          ),
        );

        // Repository is already configured before widget creation

        await tester.pumpAndSettle();
        // Should not throw when tapping with null callbacks
        await tester.tap(find.text(projectName));
        await tester.pumpAndSettle();

        final searchIcon = find.byType(IconButton).first;
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();

        final notificationIcon = find.byType(IconButton).at(1);
        await tester.tap(notificationIcon);
        await tester.pumpAndSettle();

        // Widget should still render correctly
        expect(find.text(projectName), findsOneWidget);
      });
    });

    testWidgets('displays correct icon assets', (WidgetTester tester) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      
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

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(projectId: projectId),
              ),
            ),
          ),
        );

        // Repository is already configured before widget creation

        await tester.pumpAndSettle();
        // Check that Image widgets are present for icons
        final images = find.byType(Image);
        expect(images, findsNWidgets(2));

        // Verify the image assets are loaded
        for (int i = 0; i < 2; i++) {
          final image = tester.widget<Image>(images.at(i));
          expect(image.image, isA<AssetImage>());
        }
      });
    });

    testWidgets('has proper spacing and margins', (WidgetTester tester) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      
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

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(projectId: projectId),
              ),
            ),
          ),
        );

        // Repository is already configured before widget creation

        await tester.pumpAndSettle();
        // Check for SizedBox between project name and arrow
        expect(find.byType(SizedBox), findsWidgets);

        // Check for Container with margin around avatar
        final containers = find.byType(Container);
        expect(containers, findsWidgets);
      });
    });

    testWidgets('shows loading indicator while fetching project data', (WidgetTester tester) async {
      const projectId = 'test-project-id';
      
      final project = Project(
        id: projectId,
        projectName: 'Test Project',
        creatorUserId: 'user-id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: ProjectStatus.active,
      );

      // Configure the repository before creating the widget
      fakeProjectRepository.addProject(projectId, project);

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(projectId: projectId),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        await tester.pumpAndSettle();
        
        // Should show project name after loading
        expect(find.text('Test Project'), findsOneWidget);
      });
    });

    testWidgets('shows error message when project fetch fails', (WidgetTester tester) async {
      const projectId = 'test-project-id';

      // Configure the repository to throw an error before creating the widget
      fakeProjectRepository.shouldThrowOnGetProject = true;
      fakeProjectRepository.getProjectErrorMessage = 'Project not found';

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ModularApp(
            module: ProjectSettingsTestModule(fakeProjectRepository),
            child: MaterialApp(
              home: Scaffold(
                appBar: ProjectHeaderAppBar(projectId: projectId),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        
        // Should show error message
        expect(find.text('Error loading project'), findsOneWidget);
      });
    });
  });
}

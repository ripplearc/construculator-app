import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/project_settings/domain/entities/project_entity.dart';
import 'package:construculator/features/project_settings/domain/entities/enums.dart';
import 'package:construculator/features/project_settings/testing/fake_project_repository.dart';
import 'package:construculator/features/project_settings/testing/project_settings_test_module.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late FakeProjectRepository fakeProjectRepository;
  late Clock clock;

  setUp(() {
    fakeProjectRepository = FakeProjectRepository();
    Modular.init(_TestModule(fakeProjectRepository));
    clock = Modular.get<Clock>();
  });

  tearDown(() {
    Modular.destroy();
  });

  group('ProjectHeaderAppBar', () {
    Future<void> pumpProjectHeaderAppBar(
      WidgetTester tester, {
      required String projectId,
      required String projectName,
      ImageProvider? avatarImage,
      VoidCallback? onProjectTap,
      VoidCallback? onSearchTap,
      VoidCallback? onNotificationTap,
    }) async {
      final project = Project(
        id: projectId,
        projectName: projectName,
        creatorUserId: 'user-id',
        createdAt: clock.now(),
        updatedAt: clock.now(),
        status: ProjectStatus.active,
      );

      fakeProjectRepository.addProject(projectId, project);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ProjectHeaderAppBar(
              projectId: projectId,
              avatarImage: avatarImage,
              onProjectTap: onProjectTap,
              onSearchTap: onSearchTap,
              onNotificationTap: onNotificationTap,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders with required project name', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
      );

      await tester.pumpAndSettle();
      expect(find.text(projectName), findsOneWidget);
      expect(find.byType(ProjectHeaderAppBar), findsOneWidget);
    });

    testWidgets('calls onProjectTap when project name is tapped', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      bool onProjectTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
        onProjectTap: () => onProjectTapCalled = true,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(projectName));
      await tester.pumpAndSettle();

      expect(onProjectTapCalled, isTrue);
    });

    testWidgets('calls onSearchTap when search icon is tapped', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      bool onSearchTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
        onSearchTap: () => onSearchTapCalled = true,
      );
      await tester.pumpAndSettle();

      final searchIcon = find.byKey(const Key('project_header_search_button'));
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      expect(onSearchTapCalled, isTrue);
    });

    testWidgets('calls onNotificationTap when notification icon is tapped', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';
      bool onNotificationTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
        onNotificationTap: () => onNotificationTapCalled = true,
      );
      await tester.pumpAndSettle();

      final notificationIcon = find.byKey(
        const Key('project_header_notification_button'),
      );
      await tester.tap(notificationIcon);
      await tester.pumpAndSettle();

      expect(onNotificationTapCalled, isTrue);
    });

    testWidgets('renders search and notification icons', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
      );

      expect(find.byType(IconButton), findsNWidgets(2));
      expect(find.byType(CoreIconWidget), findsNWidgets(3));
    });

    testWidgets('handles null callbacks gracefully', (
      WidgetTester tester,
    ) async {
      const projectId = 'test-project-id';
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(
        tester,
        projectId: projectId,
        projectName: projectName,
        onProjectTap: null,
        onSearchTap: null,
        onNotificationTap: null,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(projectName));
      await tester.pumpAndSettle();

      final searchIcon = find.byKey(const Key('project_header_search_button'));
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      final notificationIcon = find.byKey(
        const Key('project_header_notification_button'),
      );
      await tester.tap(notificationIcon);
      await tester.pumpAndSettle();

      expect(find.text(projectName), findsOneWidget);
    });
  });
}

class _TestModule extends Module {
  final FakeProjectRepository fakeProjectRepository;

  _TestModule(this.fakeProjectRepository);

  @override
  List<Module> get imports => [
    ProjectSettingsTestModule(fakeProjectRepository),
    ClockTestModule(),
  ];
}

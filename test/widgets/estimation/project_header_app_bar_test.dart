import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectHeaderAppBar', () {
    /// Helper method to pump the ProjectHeaderAppBar widget
    Future<void> pumpProjectHeaderAppBar(
      WidgetTester tester, {
      required String projectName,
      ImageProvider? avatarImage,
      VoidCallback? onProjectTap,
      VoidCallback? onSearchTap,
      VoidCallback? onNotificationTap,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ProjectHeaderAppBar(
              projectName: projectName,
              avatarImage: avatarImage,
              onProjectTap: onProjectTap,
              onSearchTap: onSearchTap,
              onNotificationTap: onNotificationTap,
            ),
          ),
        ),
      );
    }

    testWidgets('renders with required project name', (
      WidgetTester tester,
    ) async {
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(tester, projectName: projectName);

      expect(find.text(projectName), findsOneWidget);
      expect(find.byType(ProjectHeaderAppBar), findsOneWidget);
    });

    testWidgets('calls onProjectTap when project name is tapped', (
      WidgetTester tester,
    ) async {
      const projectName = 'Test Project';
      bool onProjectTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectName: projectName,
        onProjectTap: () => onProjectTapCalled = true,
      );

      await tester.tap(find.text(projectName));
      await tester.pumpAndSettle();

      expect(onProjectTapCalled, isTrue);
    });

    testWidgets('calls onSearchTap when search icon is tapped', (
      WidgetTester tester,
    ) async {
      const projectName = 'Test Project';
      bool onSearchTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectName: projectName,
        onSearchTap: () => onSearchTapCalled = true,
      );

      final searchIcon = find.byKey(const Key('project_header_search_button'));
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      expect(onSearchTapCalled, isTrue);
    });

    testWidgets('calls onNotificationTap when notification icon is tapped', (
      WidgetTester tester,
    ) async {
      const projectName = 'Test Project';
      bool onNotificationTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectName: projectName,
        onNotificationTap: () => onNotificationTapCalled = true,
      );

      final notificationIcon = find.byKey(
        const Key('project_header_notification_button'),
      );
      await tester.tap(notificationIcon);
      await tester.pumpAndSettle();

      expect(onNotificationTapCalled, isTrue);
    });

    testWidgets('handles null callbacks gracefully', (
      WidgetTester tester,
    ) async {
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(
        tester,
        projectName: projectName,
        onProjectTap: null,
        onSearchTap: null,
        onNotificationTap: null,
      );

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

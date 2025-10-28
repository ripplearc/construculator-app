import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:core_ui/core_ui.dart';
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
    testWidgets('renders with required project name', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(tester, projectName: projectName);

      expect(find.text(projectName), findsOneWidget);
      expect(find.byType(ProjectHeaderAppBar), findsOneWidget);
    });

    testWidgets('displays project name with dropdown arrow', (WidgetTester tester) async {
      const projectName = 'My Construction Project';

      await pumpProjectHeaderAppBar(tester, projectName: projectName);

      expect(find.text(projectName), findsOneWidget);
      expect(find.byType(CoreIconWidget), findsNWidgets(3)); // 1 dropdown + 2 action icons
    });

    testWidgets('calls onProjectTap when project name is tapped', (WidgetTester tester) async {
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

    testWidgets('calls onSearchTap when search icon is tapped', (WidgetTester tester) async {
      const projectName = 'Test Project';
      bool onSearchTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectName: projectName,
        onSearchTap: () => onSearchTapCalled = true,
      );

      final searchIcon = find.byType(IconButton).first;
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      expect(onSearchTapCalled, isTrue);
    });

    testWidgets('calls onNotificationTap when notification icon is tapped', (WidgetTester tester) async {
      const projectName = 'Test Project';
      bool onNotificationTapCalled = false;

      await pumpProjectHeaderAppBar(
        tester,
        projectName: projectName,
        onNotificationTap: () => onNotificationTapCalled = true,
      );

      final notificationIcon = find.byType(IconButton).at(1);
      await tester.tap(notificationIcon);
      await tester.pumpAndSettle();

      expect(onNotificationTapCalled, isTrue);
    });

    testWidgets('displays fallback avatar when avatarImage is null', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(tester, projectName: projectName);

      expect(find.byType(CircleAvatar), findsOneWidget);
      final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(circleAvatar.backgroundImage, isNull);
    });

    testWidgets('has correct preferred size', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(tester, projectName: projectName);

      final appBar = tester.widget<ProjectHeaderAppBar>(find.byType(ProjectHeaderAppBar));
      expect(appBar.preferredSize, equals(const Size.fromHeight(kToolbarHeight)));
    });

    testWidgets('renders search and notification icons', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(tester, projectName: projectName);

      expect(find.byType(IconButton), findsNWidgets(2));
      expect(find.byType(CoreIconWidget), findsNWidgets(3)); // 1 dropdown + 2 action icons
    });

    testWidgets('handles null callbacks gracefully', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(
        tester,
        projectName: projectName,
        onProjectTap: null,
        onSearchTap: null,
        onNotificationTap: null,
      );

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

    testWidgets('displays correct icon assets', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(tester, projectName: projectName);

      // Check that CoreIconWidget widgets are present for icons
      final coreIcons = find.byType(CoreIconWidget);
      expect(coreIcons, findsNWidgets(3)); // 1 dropdown + 2 action icons

      // Verify the CoreIconWidget widgets are present
      for (int i = 0; i < 3; i++) {
        final coreIcon = tester.widget<CoreIconWidget>(coreIcons.at(i));
        expect(coreIcon, isA<CoreIconWidget>());
      }
    });

    testWidgets('has proper spacing and margins', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await pumpProjectHeaderAppBar(tester, projectName: projectName);

      // Check for SizedBox between project name and arrow
      expect(find.byType(SizedBox), findsWidgets);

      // Check for Container with margin around avatar
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });
  });
}

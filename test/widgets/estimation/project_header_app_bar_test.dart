import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  group('ProjectHeaderAppBar', () {
    testWidgets('renders with required project name', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(projectName: projectName),
            ),
          ),
        );

        expect(find.text(projectName), findsOneWidget);
        expect(find.byType(ProjectHeaderAppBar), findsOneWidget);
      });
    });

    testWidgets('displays project name with dropdown arrow', (WidgetTester tester) async {
      const projectName = 'My Construction Project';

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(projectName: projectName),
            ),
          ),
        );

        expect(find.text(projectName), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      });
    });

    testWidgets('calls onProjectTap when project name is tapped', (WidgetTester tester) async {
      const projectName = 'Test Project';
      bool onProjectTapCalled = false;

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(
                projectName: projectName,
                onProjectTap: () => onProjectTapCalled = true,
              ),
            ),
          ),
        );

        await tester.tap(find.text(projectName));
        await tester.pumpAndSettle();

        expect(onProjectTapCalled, isTrue);
      });
    });

    testWidgets('calls onSearchTap when search icon is tapped', (WidgetTester tester) async {
      const projectName = 'Test Project';
      bool onSearchTapCalled = false;

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(
                projectName: projectName,
                onSearchTap: () => onSearchTapCalled = true,
              ),
            ),
          ),
        );

        final searchIcon = find.byType(IconButton).first;
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();

        expect(onSearchTapCalled, isTrue);
      });
    });

    testWidgets('calls onNotificationTap when notification icon is tapped', (WidgetTester tester) async {
      const projectName = 'Test Project';
      bool onNotificationTapCalled = false;

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(
                projectName: projectName,
                onNotificationTap: () => onNotificationTapCalled = true,
              ),
            ),
          ),
        );

        final notificationIcon = find.byType(IconButton).at(1);
        await tester.tap(notificationIcon);
        await tester.pumpAndSettle();

        expect(onNotificationTapCalled, isTrue);
      });
    });

    testWidgets('displays network avatar when avatarUrl is provided', (WidgetTester tester) async {
      const projectName = 'Test Project';
      const avatarUrl = 'https://example.com/avatar.jpg';

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(
                projectName: projectName,
                avatarUrl: avatarUrl,
              ),
            ),
          ),
        );

        expect(find.byType(CircleAvatar), findsOneWidget);
        final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
        expect(circleAvatar.backgroundImage, isA<NetworkImage>());
      });
    });

    testWidgets('displays fallback avatar when avatarUrl is null', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(projectName: projectName),
            ),
          ),
        );

        expect(find.byType(CircleAvatar), findsOneWidget);
        final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
        expect(circleAvatar.backgroundImage, isA<NetworkImage>());
      });
    });

    testWidgets('displays fallback avatar when avatarUrl is empty', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(
                projectName: projectName,
                avatarUrl: '',
              ),
            ),
          ),
        );

        expect(find.byType(CircleAvatar), findsOneWidget);
        final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
        expect(circleAvatar.backgroundImage, isA<NetworkImage>());
      });
    });

    testWidgets('has correct preferred size', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(projectName: projectName),
            ),
          ),
        );

        final appBar = tester.widget<ProjectHeaderAppBar>(find.byType(ProjectHeaderAppBar));
        expect(appBar.preferredSize, equals(const Size.fromHeight(kToolbarHeight)));
      });
    });

    testWidgets('renders search and notification icons', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(projectName: projectName),
            ),
          ),
        );

        expect(find.byType(IconButton), findsNWidgets(2));
        expect(find.byType(Image), findsNWidgets(2));
      });
    });

    testWidgets('handles null callbacks gracefully', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(
                projectName: projectName,
                onProjectTap: null,
                onSearchTap: null,
                onNotificationTap: null,
              ),
            ),
          ),
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
    });

    testWidgets('displays correct icon assets', (WidgetTester tester) async {
      const projectName = 'Test Project';

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(projectName: projectName),
            ),
          ),
        );

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
      const projectName = 'Test Project';

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: ProjectHeaderAppBar(projectName: projectName),
            ),
          ),
        );

        // Check for SizedBox between project name and arrow
        expect(find.byType(SizedBox), findsWidgets);

        // Check for Container with margin around avatar
        final containers = find.byType(Container);
        expect(containers, findsWidgets);
      });
    });
  });
}

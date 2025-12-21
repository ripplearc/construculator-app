import 'package:construculator/features/project/presentation/project_ui_provider_impl.dart';
import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectUIProviderImpl', () {
    late ProjectUIProviderImpl provider;

    setUp(() {
      provider = ProjectUIProviderImpl();
    });

    group('buildProjectHeaderAppbar', () {
      test('should return ProjectHeaderAppBar', () {
        final projectAppbarHeader = provider.buildProjectHeaderAppbar(
          projectId: '',
        );

        expect(projectAppbarHeader, isA<ProjectHeaderAppBar>());
      });

      test('should pass correct arguments to ProjectHeaderAppBar', () {
        final projectAppbarHeader =
            provider.buildProjectHeaderAppbar(
                  projectId: 'my-project-123',
                  onProjectTap: () {},
                  onSearchTap: () {},
                  onNotificationTap: () {},
                  avatarImage: const AssetImage('assets/images/avatar.png'),
                )
                as ProjectHeaderAppBar;

        expect(projectAppbarHeader.projectName, equals('my-project-123'));
        expect(projectAppbarHeader.onProjectTap, isNotNull);
        expect(projectAppbarHeader.onSearchTap, isNotNull);
        expect(projectAppbarHeader.onNotificationTap, isNotNull);
        expect(projectAppbarHeader.avatarImage, isA<ImageProvider>());
      });

      testWidgets('renders inside Scaffold and is discoverable', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: provider.buildProjectHeaderAppbar(
                projectId: 'my-project-123',
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        );

        expect(find.byType(ProjectHeaderAppBar), findsOneWidget);
        expect(
          find.byKey(const Key('project_header_search_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('project_header_notification_button')),
          findsOneWidget,
        );
      });
    });
  });
}

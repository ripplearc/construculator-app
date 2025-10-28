import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../font_loader.dart';
import '../await_images_extension.dart';

void main() {
  final size = const Size(390, 56);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  group('ProjectHeaderAppBar Screenshot Tests', () {
    Future<void> pumpProjectHeaderAppBar({
      required WidgetTester tester,
      required String projectName,
      VoidCallback? onProjectTap,
      VoidCallback? onSearchTap,
      VoidCallback? onNotificationTap,
      String? avatarUrl,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ProjectHeaderAppBar(
              projectName: projectName,
              onProjectTap: onProjectTap,
              onSearchTap: onSearchTap,
              onNotificationTap: onNotificationTap,
              avatarUrl: avatarUrl,
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
      
      await mockNetworkImagesFor(() async {
        await pumpProjectHeaderAppBar(
          tester: tester,
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
      
      await mockNetworkImagesFor(() async {
        await pumpProjectHeaderAppBar(
          tester: tester,
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
      
      await mockNetworkImagesFor(() async {
        await pumpProjectHeaderAppBar(
          tester: tester,
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

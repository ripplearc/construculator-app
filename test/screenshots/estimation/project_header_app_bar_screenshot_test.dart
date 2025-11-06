import 'package:construculator/features/estimation/presentation/widgets/project_header_app_bar.dart';
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
      ImageProvider? avatarImage,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ProjectHeaderAppBar(
              projectName: projectName,
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

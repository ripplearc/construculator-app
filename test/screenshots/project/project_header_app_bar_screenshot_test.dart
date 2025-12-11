import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';

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
  late Clock clock;

  setUpAll(() async {
    final appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
    );
    Modular.init(_TestModule(appBootstrap));
    fakeProjectRepository =
        Modular.get<ProjectRepository>(key: 'fakeProjectRepository')
            as FakeProjectRepository;
    clock = Modular.get<Clock>();
    await loadAppFontsAll();
  });

  tearDownAll(() {
    Modular.destroy();
    fakeProjectRepository.clearAllData();
  });

  setUp(() {
    fakeProjectRepository.clearAllData();
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
          theme: createTestTheme(),
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

    testWidgets('renders project header app bar with normal name correctly', (
      tester,
    ) async {
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

    testWidgets('renders project header app bar with long name correctly', (
      tester,
    ) async {
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

    testWidgets('renders project header app bar without avatar correctly', (
      tester,
    ) async {
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

class _TestModule extends Module {
  final AppBootstrap appBootstrap;

  _TestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    ProjectLibraryModule(appBootstrap),
    ClockTestModule(),
  ];
}

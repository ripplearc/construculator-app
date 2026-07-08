import 'package:construculator/features/project_settings/presentation/bloc/project_details_bloc/project_details_bloc.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_detail_screen.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

/// Test module providing [ProjectDetailsBloc] as a factory backed by a shared
/// [FakeProjectRepository], resolved via `Modular.get` to satisfy the
/// dependency-injection lint.
class _ProjectDetailScreenScreenshotTestModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<ProjectRepository>(FakeProjectRepository.new);
    i.add<ProjectDetailsBloc>(() => ProjectDetailsBloc(projectRepository: i()));
  }
}

void main() {
  const projectId = 'project-1';
  const size = Size(390, 844);
  const ratio = 1.0;

  late FakeProjectRepository fakeProjectRepository;

  setUpAll(() {
    Modular.init(_ProjectDetailScreenScreenshotTestModule());
    fakeProjectRepository =
        Modular.get<ProjectRepository>() as FakeProjectRepository;
  });

  tearDownAll(() {
    Modular.dispose();
  });

  setUp(() async {
    await loadAppFontsAll();
  });

  Project buildProject() {
    return Project(
      id: projectId,
      projectName: 'Material of building',
      description:
          'Lorem Ipsum is simply dummy text of the printing and '
          'typesetting industry. Lorem Ipsum has been the',
      creatorUserId: 'user-1',
      createdAt: DateTime(2024, 10, 12, 14, 30),
      updatedAt: DateTime(2024, 10, 12, 14, 30),
      status: ProjectStatus.active,
      exportStorageProvider: StorageProvider.googleDrive,
      exportFolderLink: 'Cost estimation',
    );
  }

  Future<void> pumpScreen({
    required WidgetTester tester,
    required ThemeData theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);

    fakeProjectRepository
      ..reset()
      ..addProject(projectId, buildProject());

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProjectDetailScreen(
          projectId: projectId,
          blocFactory: () => Modular.get<ProjectDetailsBloc>(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ProjectDetailScreen Screenshot Tests', () {
    testWidgets('renders loaded content (light)', (tester) async {
      await pumpScreen(tester: tester, theme: createTestTheme());

      await expectLater(
        find.byType(ProjectDetailScreen),
        matchesGoldenFile(
          'goldens/project_detail_screen/${size.width}x${size.height}/loaded.png',
        ),
      );
    });

    testWidgets('renders loaded content (dark)', (tester) async {
      await pumpScreen(tester: tester, theme: createTestThemeDark());

      await expectLater(
        find.byType(ProjectDetailScreen),
        matchesGoldenFile(
          'goldens/project_detail_screen/${size.width}x${size.height}/loaded_dark.png',
        ),
      );
    });
  });
}

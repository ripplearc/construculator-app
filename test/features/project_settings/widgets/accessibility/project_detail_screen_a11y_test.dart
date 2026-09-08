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

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

/// Test module providing [ProjectDetailsBloc] as a factory backed by a shared
/// [FakeProjectRepository], resolved via `Modular.get` to satisfy the
/// dependency-injection lint.
class _ProjectDetailScreenA11yTestModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<ProjectRepository>(FakeProjectRepository.new);
    i.add<ProjectDetailsBloc>(() => ProjectDetailsBloc(projectRepository: i()));
  }
}

void main() {
  const projectId = 'project-1';

  late FakeProjectRepository fakeProjectRepository;

  setUpAll(() async {
    await loadAppFontsAll();
    Modular.init(_ProjectDetailScreenA11yTestModule());
    fakeProjectRepository =
        Modular.get<ProjectRepository>() as FakeProjectRepository;
  });

  tearDownAll(() {
    Modular.dispose();
  });

  Project buildProject() {
    return Project(
      id: projectId,
      projectName: 'Material of building',
      description: 'A short description.',
      creatorUserId: 'user-1',
      createdAt: DateTime(2024, 10, 12, 14, 30),
      updatedAt: DateTime(2024, 10, 12, 14, 30),
      status: ProjectStatus.active,
      exportStorageProvider: StorageProvider.googleDrive,
      exportFolderLink: 'Cost estimation',
    );
  }

  Widget makeTestableWidget({required ThemeData theme}) {
    fakeProjectRepository
      ..reset()
      ..addProject(projectId, buildProject());
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProjectDetailScreen(
        projectId: projectId,
        blocFactory: () => Modular.get<ProjectDetailsBloc>(),
      ),
    );
  }

  group('ProjectDetailScreen - accessibility', () {
    testWidgets('loaded content meets guidelines in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(theme: theme),
        find.byKey(ProjectDetailScreen.contentKey),
        checkTapTargetSize: false,
        checkLabeledTapTarget: false,
      );
    });
  });
}

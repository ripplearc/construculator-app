import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  late FakeProjectRepository fakeProjectRepository;
  late Clock clock;

  setUpAll(() async {
    CoreToast.disableTimers();
    final appBootstrap = FakeAppBootstrapFactory.create();
    Modular.init(ProjectModule(appBootstrap));
    Modular.replaceInstance<ProjectRepository>(FakeProjectRepository());
    fakeProjectRepository =
        Modular.get<ProjectRepository>() as FakeProjectRepository;
    clock = Modular.get<Clock>();
  });

  tearDownAll(() {
    CoreToast.enableTimers();
    Modular.destroy();
  });

  Widget makeAppBar({
    String projectId = 'proj-1',
    String projectName = 'My Project',
    VoidCallback? onProjectTap,
    VoidCallback? onSearchTap,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: ProjectHeaderAppBar(
          projectId: projectId,
          onProjectTap: onProjectTap ?? () {},
          onSearchTap: onSearchTap ?? () {},
        ),
        body: const SizedBox.shrink(),
      ),
    );
  }

  group('ProjectHeaderAppBar a11y', () {
    setUp(() {
      fakeProjectRepository.reset();
      fakeProjectRepository.addProject(
        'proj-1',
        Project(
          id: 'proj-1',
          projectName: 'My Project',
          creatorUserId: 'user-id',
          createdAt: clock.now(),
          updatedAt: clock.now(),
          status: ProjectStatus.active,
        ),
      );
    });

    testWidgets(
      'search button meets tap target and label guidelines in light and dark themes',
      (tester) async {
        await setupA11yTest(tester);
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeAppBar(theme: theme),
          find.byKey(const Key('project_header_search_button')),
          setupAfterPump: (tester) async {
            await tester.pump();
          },
        );
      },
    );
  });
}

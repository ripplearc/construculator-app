import 'package:construculator/features/project/presentation/bloc/get_project_bloc/get_project_bloc.dart';
import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  late FakeProjectRepository fakeProjectRepository;
  late FakeCurrentProjectNotifier fakeCurrentProjectNotifier;
  late Clock clock;

  const testProjectId = 'a11y-project-id';
  const testProjectName = 'Kitchen Renovation';

  setUpAll(() async {
    final appBootstrap = FakeAppBootstrapFactory.create();
    Modular.init(ProjectModule(appBootstrap));
    Modular.replaceInstance<ProjectRepository>(FakeProjectRepository());
    Modular.replaceInstance<CurrentProjectNotifier>(
      FakeCurrentProjectNotifier(),
    );
    fakeProjectRepository =
        Modular.get<ProjectRepository>() as FakeProjectRepository;
    fakeCurrentProjectNotifier =
        Modular.get<CurrentProjectNotifier>() as FakeCurrentProjectNotifier;
    clock = Modular.get<Clock>();
    await loadAppFontsAll();
  });

  tearDownAll(() {
    Modular.destroy();
  });

  setUp(() {
    fakeProjectRepository.clearAllData();
    fakeCurrentProjectNotifier.reset();

    final project = Project(
      id: testProjectId,
      projectName: testProjectName,
      creatorUserId: 'user-id',
      createdAt: clock.now(),
      updatedAt: clock.now(),
      status: ProjectStatus.active,
    );
    fakeProjectRepository.addProject(testProjectId, project);
    fakeCurrentProjectNotifier.setCurrentProjectId(testProjectId);
  });

  Widget buildWidget(ThemeData theme) {
    return MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: ProjectHeaderAppBar(
          getProjectBlocFactory: () => Modular.get<GetProjectBloc>(),
          onProjectTap: () {},
          onSearchTap: () {},
          onNotificationTap: () {},
        ),
        body: const SizedBox.shrink(),
      ),
    );
  }

  group('ProjectHeaderAppBar A11y', () {
    testWidgets('search button meets all a11y guidelines in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildWidget,
        find.byKey(const Key('project_header_search_button')),
        setupAfterPump: (t) => t.pumpAndSettle(),
      );
    });

    testWidgets(
      'notification button meets all a11y guidelines in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          buildWidget,
          find.byKey(const Key('project_header_notification_button')),
          setupAfterPump: (t) => t.pumpAndSettle(),
        );
      },
    );

    testWidgets('project name text meets all a11y guidelines in both themes', (
      tester,
    ) async {
      await setupA11yTest(tester);
      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildWidget,
        find.text(testProjectName),
        setupAfterPump: (t) => t.pumpAndSettle(),
      );
    });
  });
}

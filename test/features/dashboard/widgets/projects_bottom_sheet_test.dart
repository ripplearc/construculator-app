import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_list_item.dart';
import 'package:construculator/features/dashboard/presentation/widgets/projects_bottom_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  late FakeClockImpl clock;
  late FakeSupabaseWrapper fakeSupabase;
  late FakeProjectRepository fakeRepository;
  late ProjectDropdownBloc bloc;

  const String testUserId = 'user-1';
  final l10n = lookupAppLocalizations(const Locale('en'));

  Project buildProject({
    required String id,
    required String projectName,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      projectName: projectName,
      creatorUserId: testUserId,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: updatedAt ?? DateTime(2025, 4, 29, 18, 11),
      status: ProjectStatus.active,
    );
  }

  Widget buildTestApp() {
    return MaterialApp(
      theme: createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: ProjectsBottomSheet()),
    );
  }

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.runAsync(() async {
      await bloc.stream.firstWhere(
        (state) =>
            state is ProjectDropdownLoadSuccess ||
            state is ProjectDropdownLoadFailure,
      );
    });
    await tester.pump();
  }

  setUpAll(() async {
    await loadAppFontsAll();
    clock = FakeClockImpl(DateTime(2025, 1, 1, 8, 0));
  });

  setUp(() {
    fakeSupabase = FakeSupabaseWrapper(clock: clock);
    fakeRepository = FakeProjectRepository();

    final bootstrap = FakeAppBootstrapFactory.create(
      supabaseWrapper: fakeSupabase,
    );
    Modular.init(DashboardModule(bootstrap));
    Modular.replaceInstance<SupabaseWrapper>(fakeSupabase);
    Modular.replaceInstance<ProjectRepository>(fakeRepository);

    fakeSupabase.setCurrentUser(
      FakeUser(
        id: testUserId,
        email: 'user-1@example.com',
        createdAt: clock.now().toIso8601String(),
        appMetadata: const {},
        userMetadata: const {},
      ),
    );

    bloc = Modular.get<ProjectDropdownBloc>();
    Modular.replaceInstance<ProjectDropdownBloc>(bloc);
  });

  tearDown(() {
    bloc.close();
    fakeRepository.dispose();
    Modular.destroy();
  });

  testWidgets('renders title, search field, and create button', (tester) async {
    fakeRepository.setAccessibleProjects([]);

    await pumpSheet(tester);

    expect(find.text(l10n.projectsSheetTitle), findsOneWidget);
    expect(find.text(l10n.searchProjectsHint), findsOneWidget);
    expect(find.text(l10n.createProjectButton), findsOneWidget);
  });

  testWidgets('renders a list item for each project', (tester) async {
    fakeRepository.setAccessibleProjects([
      buildProject(id: 'project-1', projectName: 'My project'),
      buildProject(id: 'project-2', projectName: 'Material of building'),
    ]);

    await pumpSheet(tester);

    expect(find.text('My project'), findsOneWidget);
    expect(find.text('Material of building'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no projects', (tester) async {
    fakeRepository.setAccessibleProjects([]);

    await pumpSheet(tester);

    expect(find.text(l10n.projectsEmptyState), findsOneWidget);
  });

  testWidgets('filters projects by search query', (tester) async {
    fakeRepository.setAccessibleProjects([
      buildProject(id: 'project-1', projectName: 'My project'),
      buildProject(id: 'project-2', projectName: 'Material of building'),
    ]);

    await pumpSheet(tester);

    await tester.enterText(
      find.byKey(const Key('projects_search_field')),
      'material',
    );
    await tester.pumpAndSettle();

    expect(find.text('Material of building'), findsOneWidget);
    expect(find.text('My project'), findsNothing);
  });

  testWidgets('selecting a project dispatches selection and pops the sheet', (
    tester,
  ) async {
    fakeRepository.setAccessibleProjects([
      buildProject(id: 'project-1', projectName: 'My project'),
      buildProject(id: 'project-2', projectName: 'Material of building'),
    ]);

    await pumpSheet(tester);

    await tester.tap(find.text('Material of building'));
    await tester.pump();

    expect(bloc.state, isA<ProjectDropdownLoadSuccess>());
    final state = bloc.state as ProjectDropdownLoadSuccess;
    final selected = state.selectedProject;
    expect(selected, isNotNull);
    expect(selected, isA<Project>());
    expect((selected as Project).id, 'project-2');
  });

  testWidgets('shows full error state when initial load fails with no cache', (
    tester,
  ) async {
    fakeRepository.shouldThrowOnWatchProjects = true;

    await pumpSheet(tester);

    expect(find.text(l10n.projectsLoadError), findsOneWidget);
    expect(find.byType(ProjectListItem), findsNothing);
    expect(find.text(l10n.projectsEmptyState), findsNothing);
  });

  testWidgets('keeps showing cached projects when a reload fails', (
    tester,
  ) async {
    fakeRepository.setAccessibleProjects([
      buildProject(id: 'project-1', projectName: 'My project'),
    ]);

    await pumpSheet(tester);
    expect(find.text('My project'), findsOneWidget);

    fakeRepository.emitProjectsError(Exception('network down'));
    await tester.pumpAndSettle();

    expect(find.text('My project'), findsOneWidget);
    expect(find.text(l10n.projectsLoadError), findsOneWidget);
  });

  testWidgets('search filtering is delegated to the bloc', (tester) async {
    fakeRepository.setAccessibleProjects([
      buildProject(id: 'project-1', projectName: 'My project'),
      buildProject(id: 'project-2', projectName: 'Material of building'),
    ]);

    await pumpSheet(tester);

    await tester.enterText(
      find.byKey(const Key('projects_search_field')),
      'material',
    );
    await tester.pumpAndSettle();

    final state = bloc.state;
    expect(state, isA<ProjectDropdownLoadSuccess>());
    final loaded = state as ProjectDropdownLoadSuccess;
    expect(loaded.searchQuery, 'material');
    expect(loaded.projects.length, 2);
    expect(loaded.visibleProjects.length, 1);
    expect(loaded.visibleProjects.first.id, 'project-2');
  });
}

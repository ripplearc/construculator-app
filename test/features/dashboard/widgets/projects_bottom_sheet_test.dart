import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_list_item.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../projects_bottom_sheet_test_harness.dart';

void main() {
  final harness = ProjectsBottomSheetTestHarness();
  final l10n = lookupAppLocalizations(const Locale('en'));

  Project buildProject({
    required String id,
    required String projectName,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id,
      projectName: projectName,
      creatorUserId: ProjectsBottomSheetTestHarness.testUserId,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: updatedAt ?? DateTime(2025, 4, 29, 18, 11),
      status: ProjectStatus.active,
    );
  }

  setUpAll(() async {
    await harness.setUpAll();
  });

  setUp(() {
    harness.setUp();
  });

  tearDown(() {
    harness.tearDown();
  });

  testWidgets('renders title, search field, and create button', (tester) async {
    harness.fakeRepository.setAccessibleProjects([]);

    await harness.pumpSheet(tester);

    expect(find.text(l10n.projectsSheetTitle), findsOneWidget);
    expect(find.text(l10n.searchProjectsHint), findsOneWidget);
    expect(find.text(l10n.createProjectButton), findsOneWidget);
  });

  testWidgets('renders a list item for each project', (tester) async {
    harness.fakeRepository.setAccessibleProjects([
      buildProject(id: 'project-1', projectName: 'My project'),
      buildProject(id: 'project-2', projectName: 'Material of building'),
    ]);

    await harness.pumpSheet(tester);

    expect(find.text('My project'), findsOneWidget);
    expect(find.text('Material of building'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no projects', (tester) async {
    harness.fakeRepository.setAccessibleProjects([]);

    await harness.pumpSheet(tester);

    expect(find.text(l10n.projectsEmptyState), findsOneWidget);
  });

  testWidgets('filters projects by search query', (tester) async {
    harness.fakeRepository.setAccessibleProjects([
      buildProject(id: 'project-1', projectName: 'My project'),
      buildProject(id: 'project-2', projectName: 'Material of building'),
    ]);

    await harness.pumpSheet(tester);

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
    harness.fakeRepository.setAccessibleProjects([
      buildProject(id: 'project-1', projectName: 'My project'),
      buildProject(id: 'project-2', projectName: 'Material of building'),
    ]);

    await harness.pumpSheet(tester);

    await tester.tap(find.text('Material of building'));
    await tester.pump();

    expect(harness.bloc.state, isA<ProjectDropdownLoadSuccess>());
    final state = harness.bloc.state as ProjectDropdownLoadSuccess;
    final selected = state.selectedProject;
    expect(selected, isNotNull);
    expect(selected, isA<Project>());
    expect((selected as Project).id, 'project-2');
  });

  testWidgets('shows full error state when initial load fails with no cache', (
    tester,
  ) async {
    harness.fakeRepository.shouldThrowOnWatchProjects = true;

    await harness.pumpSheet(tester);

    expect(find.text(l10n.projectsLoadError), findsOneWidget);
    expect(find.byType(ProjectListItem), findsNothing);
    expect(find.text(l10n.projectsEmptyState), findsNothing);
  });

  testWidgets('keeps showing cached projects when a reload fails', (
    tester,
  ) async {
    harness.fakeRepository.setAccessibleProjects([
      buildProject(id: 'project-1', projectName: 'My project'),
    ]);

    await harness.pumpSheet(tester);
    expect(find.text('My project'), findsOneWidget);

    harness.fakeRepository.emitProjectsError(Exception('network down'));
    await tester.pumpAndSettle();

    expect(find.text('My project'), findsOneWidget);
    expect(find.text(l10n.projectsLoadError), findsOneWidget);
  });

  testWidgets('search filtering is delegated to the bloc', (tester) async {
    harness.fakeRepository.setAccessibleProjects([
      buildProject(id: 'project-1', projectName: 'My project'),
      buildProject(id: 'project-2', projectName: 'Material of building'),
    ]);

    await harness.pumpSheet(tester);

    await tester.enterText(
      find.byKey(const Key('projects_search_field')),
      'material',
    );
    await tester.pumpAndSettle();

    final state = harness.bloc.state;
    expect(state, isA<ProjectDropdownLoadSuccess>());
    final loaded = state as ProjectDropdownLoadSuccess;
    expect(loaded.searchQuery, 'material');
    expect(loaded.projects.length, 2);
    expect(loaded.visibleProjects.length, 1);
    expect(loaded.visibleProjects.first.id, 'project-2');
  });
}

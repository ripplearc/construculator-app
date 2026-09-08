// ignore_for_file: no_direct_instantiation
import 'dart:async';

import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/widgets/project_list_item.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/permission_constants.dart';
import 'package:construculator/libraries/router/routes/project_search_routes.dart';
import 'package:construculator/libraries/router/routes/project_settings_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

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
    CoreToast.disableTimers();
  });

  tearDownAll(() {
    CoreToast.enableTimers();
  });

  setUp(() {
    harness.setUp();
  });

  tearDown(() {
    harness.router.reset();
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

  testWidgets('search field is read-only', (tester) async {
    harness.fakeRepository.setAccessibleProjects([]);

    await harness.pumpSheet(tester);

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('projects_search_field')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.readOnly, isTrue);
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

    await tester.runAsync(() async {
      harness.fakeRepository.emitProjectsError(Exception('network down'));
      await harness.bloc.stream.firstWhere(
        (s) => s is ProjectDropdownLoadFailure,
      );
    });
    await tester.pump();

    expect(find.text('My project'), findsOneWidget);
    expect(find.text(l10n.projectsLoadError), findsOneWidget);
  });

  testWidgets(
    'tapping the search field pops the sheet and navigates to project search',
    (tester) async {
      harness.fakeRepository.setAccessibleProjects([]);

      await harness.pumpSheet(tester);

      await tester.tap(find.byKey(const Key('projects_search_field')));
      await tester.pumpAndSettle();

      expect(
        harness.router.navigationHistory,
        contains(const RouteCall(projectSearchRoute, null)),
      );
    },
  );


  group('project settings navigation', () {
    Finder settingsGear() =>
        find.bySemanticsLabel(l10n.projectSettingsSemanticLabel);

    testWidgets(
      'tapping the settings gear with permission navigates to project settings',
      (tester) async {
        harness.fakeRepository.setAccessibleProjects([
          buildProject(id: 'project-1', projectName: 'My project'),
        ]);
        harness.fakeRepository.setProjectPermissions('project-1', [
          PermissionConstants.viewProject,
        ]);

        await harness.pumpSheet(tester);

        await tester.tap(settingsGear());
        await tester.pump();

        expect(
          harness.router.navigationHistory,
          contains(const RouteCall(fullViewProjectRoute, 'project-1')),
        );
      },
    );

    testWidgets(
      'tapping the settings gear without permission shows a toast and does not navigate',
      (tester) async {
        harness.fakeRepository.setAccessibleProjects([
          buildProject(id: 'project-1', projectName: 'My project'),
        ]);

        await harness.pumpSheet(tester);

        await tester.tap(settingsGear());
        await tester.pump();

        expect(find.text(l10n.projectSettingsPermissionError), findsOneWidget);
        expect(harness.router.navigationHistory, isEmpty);
      },
    );

    testWidgets('settings gear is disabled while navigation is in flight', (
      tester,
    ) async {
      harness.fakeRepository.setAccessibleProjects([
        buildProject(id: 'project-1', projectName: 'My project'),
      ]);
      harness.fakeRepository.setProjectPermissions('project-1', [
        PermissionConstants.viewProject,
      ]);
      final completer = Completer<void>();
      harness.router.pushNamedCompleter = completer;

      await harness.pumpSheet(tester);

      await tester.tap(settingsGear());
      await tester.pump();

      // While the pushNamed future is pending, the gear's callback is null,
      // so its semantics (and tappability) are removed.
      expect(settingsGear(), findsNothing);

      completer.complete();
      // One pump to flush the resumed future's setState, one to rebuild.
      await tester.pump();
      await tester.pump();

      expect(settingsGear(), findsOneWidget);
    });

    testWidgets(
      'settings gear for one project stays enabled while another project '
      'navigation is in flight',
      (tester) async {
        harness.fakeRepository.setAccessibleProjects([
          buildProject(id: 'project-1', projectName: 'First project'),
          buildProject(id: 'project-2', projectName: 'Second project'),
        ]);
        harness.fakeRepository.setProjectPermissions('project-1', [
          PermissionConstants.viewProject,
        ]);
        harness.fakeRepository.setProjectPermissions('project-2', [
          PermissionConstants.viewProject,
        ]);
        final completer = Completer<void>();
        harness.router.pushNamedCompleter = completer;

        await harness.pumpSheet(tester);

        final project1Gear = find.descendant(
          of: find.byKey(const ValueKey<String>('project-1')),
          matching: settingsGear(),
        );
        final project2Gear = find.descendant(
          of: find.byKey(const ValueKey<String>('project-2')),
          matching: settingsGear(),
        );

        await tester.tap(project1Gear);
        await tester.pump();

        // project-1's gear is disabled while its navigation is in flight,
        // but project-2's gear must remain enabled and tappable.
        expect(project1Gear, findsNothing);
        expect(project2Gear, findsOneWidget);

        completer.complete();
        await tester.pump();
        await tester.pump();
      },
    );

    testWidgets(
      'shows an error toast and re-enables the gear when navigation fails',
      (tester) async {
        harness.fakeRepository.setAccessibleProjects([
          buildProject(id: 'project-1', projectName: 'My project'),
        ]);
        harness.fakeRepository.setProjectPermissions('project-1', [
          PermissionConstants.viewProject,
        ]);
        harness.router.shouldThrowOnPushNamed = true;

        await harness.pumpSheet(tester);

        await tester.tap(settingsGear());
        await tester.pump();

        expect(find.text(l10n.projectSettingsNavigationError), findsOneWidget);
        expect(settingsGear(), findsOneWidget);
      },
    );
  });
}

import 'dart:async';

import 'package:construculator/features/project_settings/presentation/bloc/project_details_bloc/project_details_bloc.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_detail_screen.dart';
import 'package:construculator/features/project_settings/presentation/widgets/cost_files_section.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_header_card.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Test module providing [ProjectDetailsBloc] as a factory backed by a shared
/// [FakeProjectRepository], resolved via `Modular.get` to satisfy the
/// dependency-injection lint.
class _ProjectDetailScreenTestModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton<ProjectRepository>(FakeProjectRepository.new);
    i.add<ProjectDetailsBloc>(() => ProjectDetailsBloc(projectRepository: i()));
  }
}

void main() {
  const projectId = 'project-1';

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

  late FakeProjectRepository fakeProjectRepository;
  BuildContext? buildContext;

  setUpAll(() {
    Modular.init(_ProjectDetailScreenTestModule());
    fakeProjectRepository =
        Modular.get<ProjectRepository>() as FakeProjectRepository;
  });

  tearDownAll(() {
    Modular.dispose();
  });

  tearDown(() {
    fakeProjectRepository.reset();
    buildContext = null;
  });

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            buildContext = context;
            return ProjectDetailScreen(
              projectId: projectId,
              blocFactory: () => Modular.get<ProjectDetailsBloc>(),
            );
          },
        ),
      ),
    );
  }

  group('ProjectDetailScreen', () {
    testWidgets('shows the app bar title', (tester) async {
      fakeProjectRepository.addProject(projectId, buildProject());
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text(l10n().projectDetailScreenTitle), findsOneWidget);
    });

    testWidgets('shows a loading indicator while the project loads', (
      tester,
    ) async {
      final completer = Completer<void>();
      fakeProjectRepository
        ..shouldDelayOperations = true
        ..completer = completer
        ..addProject(projectId, buildProject());
      await pumpScreen(tester);
      await tester.pump();

      expect(find.byKey(ProjectDetailScreen.loadingKey), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('renders the project sections once loaded', (tester) async {
      fakeProjectRepository.addProject(projectId, buildProject());
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(ProjectDetailScreen.contentKey), findsOneWidget);
      expect(find.byType(ProjectHeaderCard), findsOneWidget);
      expect(find.byType(CostFilesSection), findsOneWidget);
      expect(find.text('Material of building'), findsOneWidget);
    });

    testWidgets('shows the error view with a retry button on failure', (
      tester,
    ) async {
      fakeProjectRepository.shouldThrowOnGetProject = true;
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(ProjectDetailScreen.errorKey), findsOneWidget);
      expect(find.byKey(ProjectDetailScreen.retryButtonKey), findsOneWidget);
    });

    testWidgets('retry refetches and renders the project', (tester) async {
      fakeProjectRepository.shouldThrowOnGetProject = true;
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(ProjectDetailScreen.errorKey), findsOneWidget);

      fakeProjectRepository
        ..shouldThrowOnGetProject = false
        ..addProject(projectId, buildProject());
      await tester.tap(find.byKey(ProjectDetailScreen.retryButtonKey));
      await tester.pumpAndSettle();

      expect(find.byKey(ProjectDetailScreen.contentKey), findsOneWidget);
      expect(find.byKey(ProjectDetailScreen.errorKey), findsNothing);
    });
  });
}

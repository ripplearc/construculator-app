import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
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
  final size = const Size(390, 600);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeClockImpl clock;
  late FakeSupabaseWrapper fakeSupabase;
  late FakeProjectRepository fakeRepository;
  late ProjectDropdownBloc bloc;

  const String testUserId = 'user-1';

  Project buildProject({required String id, required String projectName}) {
    return Project(
      id: id,
      projectName: projectName,
      creatorUserId: testUserId,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 4, 29, 18, 11),
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
    await tester.pump(const Duration(milliseconds: 100));
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

  group('ProjectsBottomSheet Screenshot Tests', () {
    testWidgets('renders loaded project list', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      fakeRepository.setAccessibleProjects([
        buildProject(id: 'project-1', projectName: 'My project'),
        buildProject(id: 'project-2', projectName: 'Material of building'),
        buildProject(id: 'project-3', projectName: 'MD bungalow'),
      ]);

      await pumpSheet(tester);

      await expectLater(
        find.byType(ProjectsBottomSheet),
        matchesGoldenFile(
          'goldens/projects_bottom_sheet/${size.width}x${size.height}/projects_bottom_sheet_loaded.png',
        ),
      );
    });

    testWidgets('renders empty state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      fakeRepository.setAccessibleProjects([]);

      await pumpSheet(tester);

      await expectLater(
        find.byType(ProjectsBottomSheet),
        matchesGoldenFile(
          'goldens/projects_bottom_sheet/${size.width}x${size.height}/projects_bottom_sheet_empty.png',
        ),
      );
    });
  });
}

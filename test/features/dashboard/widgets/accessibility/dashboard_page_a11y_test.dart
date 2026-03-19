import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/project/domain/usecases/get_project_header_usecase.dart';
import 'package:construculator/features/project/presentation/bloc/get_project_bloc/get_project_bloc.dart';
import 'package:construculator/features/project/presentation/project_ui_provider_impl.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';

class _DashboardPageA11yTestModule extends Module {
  final FakeAuthManager authManager;
  final FakeAuthNotifier authNotifier;
  final FakeAppRouter appRouter;
  final FakeAuthRepository authRepository;
  final FakeCurrentProjectNotifier currentProjectNotifier;
  final FakeProjectRepository projectRepository;

  _DashboardPageA11yTestModule({
    required this.authManager,
    required this.authNotifier,
    required this.appRouter,
    required this.authRepository,
    required this.currentProjectNotifier,
    required this.projectRepository,
  });

  @override
  void binds(Injector i) {
    i.addLazySingleton<AuthManager>(() => authManager);
    i.addLazySingleton<AuthNotifier>(() => authNotifier);
    i.addLazySingleton<AuthRepository>(() => authRepository);
    i.addLazySingleton<AppRouter>(() => appRouter);
    i.addLazySingleton<CurrentProjectNotifier>(() => currentProjectNotifier);
    i.addLazySingleton<ProjectRepository>(() => projectRepository);
    i.addLazySingleton<GetProjectHeaderUseCase>(
      () => GetProjectHeaderUseCase(
        i.get<ProjectRepository>(),
        i.get<AuthRepository>(),
      ),
    );
    i.add<GetProjectBloc>(() => GetProjectBloc(getProjectHeaderUseCase: i()));
    i.addLazySingleton<ProjectUIProvider>(() => ProjectUIProviderImpl());
  }
}

void main() {
  const initialProjectId = 'project-1';
  const initialProjectName = 'Dashboard Project';
  const missingProjectId = 'project-missing';

  late FakeClockImpl clock;
  late FakeAuthRepository authRepository;
  late FakeAuthManager authManager;
  late FakeAuthNotifier authNotifier;
  late FakeAppRouter router;
  late FakeCurrentProjectNotifier currentProjectNotifier;
  late FakeProjectRepository projectRepository;
  BuildContext? buildContext;

  setUpAll(() {
    CoreToast.disableTimers();
  });

  tearDownAll(() {
    CoreToast.enableTimers();
  });

  setUp(() {
    clock = FakeClockImpl();
    authNotifier = FakeAuthNotifier();
    authRepository = FakeAuthRepository(clock: clock);
    authManager = FakeAuthManager(
      authNotifier: authNotifier,
      authRepository: authRepository,
      wrapper: FakeSupabaseWrapper(clock: clock),
      clock: clock,
    );
    router = FakeAppRouter();
    currentProjectNotifier = FakeCurrentProjectNotifier(
      initialProjectId: initialProjectId,
    );
    projectRepository = FakeProjectRepository();
    projectRepository.addProject(
      initialProjectId,
      _createProject(id: initialProjectId, projectName: initialProjectName),
    );

    Modular.init(
      _DashboardPageA11yTestModule(
        authManager: authManager,
        authNotifier: authNotifier,
        appRouter: router,
        authRepository: authRepository,
        currentProjectNotifier: currentProjectNotifier,
        projectRepository: projectRepository,
      ),
    );
  });

  tearDown(() {
    Modular.destroy();
  });

  Widget makeApp({ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          buildContext = context;
          return const DashboardPage();
        },
      ),
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> pumpDashboardPage(WidgetTester tester) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();
  }

  void setUpAuthenticatedUser({String email = 'test@example.com'}) {
    final credential = _createCredential(email: email, clock: clock);
    authManager.setCurrentCredential(credential);
    authRepository.setCurrentCredentials(credential);
    authRepository.setUserProfile(
      _createUser(
        credentialId: credential.id,
        email: email,
        clock: clock,
      ),
    );
  }

  group('DashboardPage – accessibility', () {
    testWidgets(
      'meets a11y text contrast for dashboard empty-state message in both themes',
      (tester) async {
        setUpAuthenticatedUser();
        await setupA11yTest(tester);
        await pumpDashboardPage(tester);

        final message = l10n().dashboardQuickAccessMessage;
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeApp(theme: theme),
          find.text(message),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      },
    );

    testWidgets(
      'meets a11y text contrast for project title in both themes',
      (tester) async {
        setUpAuthenticatedUser();
        await setupA11yTest(tester);
        await pumpDashboardPage(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeApp(theme: theme),
          find.text(initialProjectName),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      },
    );

    testWidgets(
      'meets a11y text contrast for project load error title in both themes',
      (tester) async {
        setUpAuthenticatedUser();
        currentProjectNotifier.setCurrentProjectId(missingProjectId);

        await setupA11yTest(tester);
        await pumpDashboardPage(tester);

        final errorText = l10n().projectLoadError;
        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeApp(theme: theme),
          find.text(errorText),
          checkTapTargetSize: false,
          checkLabeledTapTarget: false,
        );
      },
    );
  });
}

UserCredential _createCredential({
  required FakeClockImpl clock,
  String id = 'test-id',
  String email = 'test@example.com',
}) {
  return UserCredential(
    id: id,
    email: email,
    metadata: {},
    createdAt: clock.now(),
  );
}

User _createUser({
  required FakeClockImpl clock,
  required String credentialId,
  String id = 'user-1',
  String email = 'test@example.com',
  String firstName = 'John',
  String lastName = 'Doe',
}) {
  return User(
    id: id,
    credentialId: credentialId,
    email: email,
    firstName: firstName,
    lastName: lastName,
    professionalRole: 'Engineer',
    createdAt: clock.now(),
    updatedAt: clock.now(),
    userStatus: UserProfileStatus.active,
    userPreferences: {},
  );
}

Project _createProject({required String id, required String projectName}) {
  return Project(
    id: id,
    projectName: projectName,
    creatorUserId: 'user-1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 2),
    status: ProjectStatus.active,
  );
}

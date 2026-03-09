import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/project/domain/usecases/get_project_header_usecase.dart';
import 'package:construculator/features/project/presentation/bloc/get_project_bloc/get_project_bloc.dart';
import 'package:construculator/features/project/presentation/project_ui_provider_impl.dart';
import 'package:construculator/features/project/presentation/widgets/project_header_app_bar.dart';
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
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../utils/screenshot/font_loader.dart';

class _DashboardPageTestModule extends Module {
  final FakeAuthManager authManager;
  final FakeAuthNotifier authNotifier;
  final FakeAppRouter appRouter;
  final FakeAuthRepository authRepository;
  final FakeCurrentProjectNotifier currentProjectNotifier;
  final FakeProjectRepository projectRepository;

  _DashboardPageTestModule({
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
      () => GetProjectHeaderUseCase(i.get<ProjectRepository>(), i.get<AuthRepository>()),
    );
    i.add<GetProjectBloc>(() => GetProjectBloc(getProjectHeaderUseCase: i()));
    i.addLazySingleton<ProjectUIProvider>(() => ProjectUIProviderImpl());
  }
}

void main() {
  const initialProjectId = 'project-1';
  const firstName = 'John';
  const lastName = 'Doe';
  const dashboardQuickAccessMessage =
      'Add your favorite calculations and cost estimation for a quick access....';

  late FakeClockImpl clock;
  late FakeAuthRepository authRepository;
  late FakeAuthManager authManager;
  late FakeAuthNotifier authNotifier;
  late FakeAppRouter router;
  late FakeCurrentProjectNotifier currentProjectNotifier;
  late FakeProjectRepository projectRepository;

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
      createProject(
        id: initialProjectId,
        projectName: 'Dashboard Project',
      ),
    );

    Modular.init(
      _DashboardPageTestModule(
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

  Widget makeApp() {
    return MaterialApp(
      theme: createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DashboardPage(),
    );
  }

  UserCredential createCredential({
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

  User createUser({
    String id = 'user-1',
    String credentialId = 'test-id',
    String email = 'test@example.com',
    String firstName = firstName,
    String lastName = lastName,
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

  testWidgets('navigates to login when credentials id is null', (tester) async {
    await tester.pumpWidget(makeApp());

    expect(router.navigationHistory.length, 1);
    expect(router.navigationHistory.first.route, fullLoginRoute);
  });

  testWidgets('renders project header app bar and empty state message', (
    tester,
  ) async {
    final credential = createCredential();
    final user = createUser();
    authManager.setCurrentCredential(credential);
    authRepository.setUserProfile(user);

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.byType(ProjectHeaderAppBar), findsOneWidget);
    expect(find.text('Dashboard Project'), findsOneWidget);
    expect(find.text(dashboardQuickAccessMessage), findsOneWidget);
  });

  testWidgets('uses current project notifier id to load header project', (
    tester,
  ) async {
    final credential = createCredential();
    final user = createUser();
    authManager.setCurrentCredential(credential);
    authRepository.setUserProfile(user);

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    final getProjectCalls = projectRepository.getMethodCallsFor('getProject');
    expect(
      getProjectCalls.any((call) => call['id'] == currentProjectNotifier.currentProjectId),
      isTrue,
    );
  });

  testWidgets('navigates to create account when user profile stream emits null', (
    tester,
  ) async {
    const testEmail = 'stream-test@example.com';
    final credential = createCredential(email: testEmail);
    final user = createUser(email: testEmail);
    authManager.setCurrentCredential(credential);
    authRepository.setUserProfile(user);

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    authNotifier.emitUserProfileChanged(null);
    await tester.pumpAndSettle();

    expect(router.navigationHistory.length, 1);
    expect(router.navigationHistory.first.route, fullCreateAccountRoute);
    expect(router.navigationHistory.first.arguments, testEmail);
  });
}

Project createProject({required String id, required String projectName}) {
  return Project(
    id: id,
    projectName: projectName,
    creatorUserId: 'user-1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 2),
    status: ProjectStatus.active,
  );
}

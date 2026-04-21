import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/enums/estimation_sort_option.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import '../../../../utils/screenshot/font_loader.dart';

class _DashboardPageTestModule extends Module {
  final FakeAuthManager authManager;
  final FakeAuthNotifier authNotifier;
  final FakeAppRouter appRouter;
  final FakeCurrentProjectNotifier projectNotifier;

  _DashboardPageTestModule({
    required this.authManager,
    required this.authNotifier,
    required this.appRouter,
    required this.projectNotifier,
  });

  @override
  void binds(Injector i) {
    i.addLazySingleton<AuthManager>(() => authManager);
    i.addLazySingleton<AuthNotifier>(() => authNotifier);
    i.addLazySingleton<AppRouter>(() => appRouter);
    i.addLazySingleton<CurrentProjectNotifier>(() => projectNotifier);
    // Provide a stub use-case that emits an empty stream so the bloc never
    // triggers a real network call during widget tests.
    i.addLazySingleton<WatchRecentEstimationsUseCase>(
      () => WatchRecentEstimationsUseCase(_NeverEstimationRepository()),
    );
    i.addLazySingleton<RecentEstimationsBloc>(
      () => RecentEstimationsBloc(
        watchRecentEstimationsUseCase:
            Modular.get<WatchRecentEstimationsUseCase>(),
      ),
    );
  }
}

/// A stub [CostEstimationRepository] that never emits any data.
/// Used in widget tests so the [RecentEstimationsSection] can resolve its
/// dependencies without hitting a real network or database.
class _NeverEstimationRepository implements CostEstimationRepository {
  @override
  Stream<Either<Failure, List<CostEstimate>>> watchEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) => const Stream.empty();

  @override
  Future<Either<Failure, List<CostEstimate>>> fetchInitialEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) async => Right([]);

  @override
  Future<Either<Failure, List<CostEstimate>>> loadMoreEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) async => Right([]);

  @override
  bool hasMoreEstimations(
    String projectId, {
    EstimationSortOption sortBy = EstimationSortOption.createdAt,
    bool ascending = false,
    int? limit,
  }) => false;

  @override
  Future<Either<Failure, CostEstimate>> createEstimation(
    CostEstimate estimation,
  ) async => Left(UnexpectedFailure());

  @override
  Future<Either<Failure, void>> deleteEstimation(
    String estimationId,
    String projectId,
  ) async => Left(UnexpectedFailure());

  @override
  Future<Either<Failure, CostEstimate>> changeLockStatus({
    required String estimationId,
    required bool isLocked,
    required String projectId,
  }) async => Left(UnexpectedFailure());

  @override
  Future<Either<Failure, CostEstimate>> renameEstimation({
    required String estimationId,
    required String newName,
    required String projectId,
  }) async => Left(UnexpectedFailure());

  @override
  void dispose() {}
}

void main() {
  late FakeClockImpl clock;
  late FakeAuthRepository authRepository;
  late FakeAuthManager authManager;
  late FakeAuthNotifier authNotifier;
  late FakeAppRouter router;
  late FakeCurrentProjectNotifier projectNotifier;

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
    projectNotifier = FakeCurrentProjectNotifier();

    Modular.init(
      _DashboardPageTestModule(
        authManager: authManager,
        authNotifier: authNotifier,
        appRouter: router,
        projectNotifier: projectNotifier,
      ),
    );
  });

  tearDown(() {
    Modular.destroy();
  });

  Widget makeApp() {
    return MaterialApp(theme: createTestTheme(), home: const DashboardPage());
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

  const String firstName = 'John';
  const String lastName = 'Doe';

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

  testWidgets('renders welcome text with user full name', (tester) async {
    final credential = createCredential();
    final user = createUser();

    authManager.setCurrentCredential(credential);
    authRepository.setUserProfile(user);

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, $firstName $lastName!'), findsOneWidget);
    expect(find.text('You are now logged in to your account'), findsOneWidget);
  });

  testWidgets('logout navigates to login', (tester) async {
    final credential = createCredential();
    final user = createUser();

    authManager.setCurrentCredential(credential);
    authRepository.setUserProfile(user);

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(CoreButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(router.navigationHistory.isNotEmpty, isTrue);
    expect(router.navigationHistory.last.route, fullLoginRoute);
  });

  testWidgets('navigates to create account when user profile event is null', (
    tester,
  ) async {
    const testEmail = 'test@example.com';
    final credential = createCredential(email: testEmail);

    authManager.setCurrentCredential(credential);
    authRepository.returnNullUserProfile = true;

    await tester.pumpWidget(makeApp());
    await tester.pump();

    expect(router.navigationHistory.length, 1);
    expect(router.navigationHistory.first.route, fullCreateAccountRoute);
    expect(router.navigationHistory.first.arguments, testEmail);
  });

  testWidgets('shows placeholder when getUserProfile returns null', (
    tester,
  ) async {
    final credential = createCredential();

    authManager.setCurrentCredential(credential);
    authRepository.returnNullUserProfile = true;

    await tester.pumpWidget(makeApp());
    await tester.pump();

    expect(find.text('Welcome back, ...'), findsOneWidget);
  });

  testWidgets(
    'navigates to create account when user profile stream emits null',
    (tester) async {
      const testEmail = 'stream-test@example.com';
      final credential = createCredential(email: testEmail);
      final user = createUser(email: testEmail);

      authManager.setCurrentCredential(credential);
      authRepository.setUserProfile(user);

      await tester.pumpWidget(makeApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome back, $firstName $lastName!'), findsOneWidget);

      authNotifier.emitUserProfileChanged(null);
      await tester.pumpAndSettle();

      expect(router.navigationHistory.length, 1);
      expect(router.navigationHistory.first.route, fullCreateAccountRoute);
      expect(router.navigationHistory.first.arguments, testEmail);
    },
  );
}

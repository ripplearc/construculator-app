import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/per_user_registrations.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/session/interfaces/session_service.dart';
import 'package:construculator/libraries/session/session_service_impl.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/fake_app_bootstrap_factory.dart';

class _TestModule extends Module {
  final AppBootstrap bootstrap;
  _TestModule(this.bootstrap);

  @override
  List<Module> get imports => [
    AuthLibraryModule(bootstrap),
    DashboardModule(bootstrap),
    ProjectModule(bootstrap),
    EstimationModule(bootstrap),
  ];
}

void main() {
  late FakeSupabaseWrapper supabase;
  late AuthManager authManager;
  late SessionService sessionService;
  late AuthNotifier authNotifier;

  FakeUser user(String id) =>
      FakeUser(id: id, email: '$id@example.com', createdAt: '2026-11-01');

  Future<void> signIn(String id) async {
    final signedIn = expectLater(
      authNotifier.onAuthStateChanged,
      emits(predicate<AuthState>((s) => s.status == AuthStatus.authenticated)),
    );
    supabase.setCurrentUser(user(id));
    await signedIn;
  }

  Future<void> signOutInTheBackground() async {
    final signedOut = expectLater(
      authNotifier.onAuthStateChanged,
      emits(
        predicate<AuthState>((s) => s.status == AuthStatus.unauthenticated),
      ),
    );
    supabase.setCurrentUser(null);
    await signedOut;
  }

  // One Modular.init for the file: modular_core keeps an imported module's
  // injector across Modular.destroy, so a fresh setup per test would leave
  // the auth manager listening to the first test's Supabase.
  setUpAll(() {
    // ignore: no_direct_instantiation
    sessionService = SessionServiceImpl(registrations: perUserRegistrations);
    final bootstrap = FakeAppBootstrapFactory.create(
      sessionService: sessionService,
    );
    supabase = bootstrap.supabaseWrapper as FakeSupabaseWrapper;
    Modular.init(_TestModule(bootstrap));
    authNotifier = Modular.get<AuthNotifier>();
    authManager = Modular.get<AuthManager>();
  });

  tearDownAll(Modular.destroy);

  tearDown(() {
    sessionService.endSession();
    supabase.setCurrentUser(null);
  });

  group('a sign-out that Supabase sends in the background', () {
    test('leaves the open screens their per-user objects, so a project can '
        'still be selected and the Estimates tab still opens', () async {
      await signIn('user-1');
      final dropdown = Modular.get<ProjectDropdownBloc>();

      await signOutInTheBackground();

      expect(dropdown.isClosed, isFalse);
      expect(
        () => dropdown.add(const ProjectDropdownSelected('project-1')),
        returnsNormally,
      );
      expect(Modular.tryGet<ProjectRepository>(), isNotNull);
      expect(Modular.get<CostEstimationListBloc>, returnsNormally);
    });

    test('gives a different user who signs in next new objects', () async {
      await signIn('user-1');
      final firstDropdown = Modular.get<ProjectDropdownBloc>();
      await signOutInTheBackground();

      await signIn('user-2');

      expect(firstDropdown.isClosed, isTrue);
      expect(Modular.get<ProjectDropdownBloc>(), isNot(same(firstDropdown)));
    });
  });

  group('a logout the user asked for', () {
    test('removes the per-user objects', () async {
      await signIn('user-1');
      final dropdown = Modular.get<ProjectDropdownBloc>();

      await authManager.logout();

      expect(dropdown.isClosed, isTrue);
      expect(Modular.tryGet<ProjectRepository>(), isNull);
    });
  });
}

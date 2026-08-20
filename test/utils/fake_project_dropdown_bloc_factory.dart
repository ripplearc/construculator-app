import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/project/testing/fake_project_repository.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';

/// Builds a [ProjectDropdownBloc] backed entirely by fakes for widget and
/// screenshot harnesses that need a bloc instance but do not exercise
/// project selection themselves.
class FakeProjectDropdownBlocFactory {
  FakeProjectDropdownBlocFactory._();

  /// Creates a fake-backed [ProjectDropdownBloc].
  ///
  /// Pass [projectRepository] to seed or fail the projects the bloc watches.
  /// Pass [authenticatedUserId] so [ProjectDropdownStarted] watches that
  /// user's projects instead of short-circuiting as unauthenticated.
  static ProjectDropdownBloc create({
    FakeProjectRepository? projectRepository,
    String? authenticatedUserId,
  }) {
    final clock = FakeClockImpl();
    final authManager = FakeAuthManager(
      authNotifier: FakeAuthNotifier(),
      authRepository: FakeAuthRepository(clock: clock),
      wrapper: FakeSupabaseWrapper(clock: clock),
      clock: clock,
    );
    if (authenticatedUserId != null) {
      authManager.setCurrentCredential(
        UserCredential(
          id: authenticatedUserId,
          email: '$authenticatedUserId@test.com',
          metadata: const {},
          createdAt: clock.now(),
        ),
      );
    }
    return ProjectDropdownBloc(
      projectRepository: projectRepository ?? FakeProjectRepository(),
      authManager: authManager,
    );
  }
}

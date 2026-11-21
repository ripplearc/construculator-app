import 'package:construculator/features/calculator/data/repositories/calculator_preferences_repository_impl.dart';
import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

/// The calculator's real chain over the auth fakes, for the page and bloc
/// tests: the settings repository reads the signed-in profile from
/// [authRepository] and [authManager], exactly as the module wires it, and
/// [createBloc] builds the bloc the page owns.
///
/// Nothing is signed in until [signIn] is called, so the repository emits
/// the defaults and a save answers with an auth failure, as it does for a
/// signed-out user.
class CalculatorTestHarness {
  CalculatorTestHarness();

  /// A harness the current test disposes when it ends.
  factory CalculatorTestHarness.disposedAfterTest() {
    final harness = CalculatorTestHarness();
    addTearDown(harness.dispose);
    return harness;
  }

  final FakeClockImpl clock = FakeClockImpl();
  late final FakeAuthNotifier authNotifier = FakeAuthNotifier();
  late final FakeAuthRepository authRepository = FakeAuthRepository(
    clock: clock,
  );
  late final FakeAuthManager authManager = FakeAuthManager(
    authNotifier: authNotifier,
    authRepository: authRepository,
    wrapper: FakeSupabaseWrapper(clock: clock),
    clock: clock,
  );

  /// The real repository over the fakes.
  // ignore: no_direct_instantiation
  late final CalculatorPreferencesRepositoryImpl repository =
      CalculatorPreferencesRepositoryImpl(
        authNotifier: authNotifier,
        authManager: authManager,
      );

  /// A bloc over [repository], as the page's factory builds one.
  CalculatorBloc createBloc() =>
      CalculatorBloc(preferencesRepository: repository);

  /// A signed-in profile whose calculator settings are [preferences], as
  /// the profile's `user_preferences` holds them.
  User userWith(Map<String, dynamic> preferences) => User(
    id: 'user-1',
    credentialId: 'cred-1',
    email: 'cred-1@example.com',
    firstName: 'Jane',
    lastName: 'Smith',
    professionalRole: 'Estimator',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    userStatus: UserProfileStatus.active,
    userPreferences: preferences,
  );

  /// Signs [user] in before the repository looks, as it is when the
  /// calculator opens after login: the notifier announces nothing.
  void signIn(User user) {
    authRepository.setUserProfile(user);
    authManager.setCurrentCredential(
      UserCredential(
        id: user.credentialId ?? '',
        email: user.email,
        metadata: {},
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }

  /// Announces a profile change, as a sync from another device arrives:
  /// the profile [user] now holds, or a sign-out for `null`.
  void announce(User? user) {
    if (user != null) authRepository.setUserProfile(user);
    authNotifier.emitUserProfileChanged(user);
  }

  /// Ends the repository and the notifier.
  void dispose() {
    repository.dispose();
    authNotifier.dispose();
  }
}

/// A bloc over a fresh harness with nothing signed in, for tests that only
/// need the calculator to render. The harness is disposed when the test ends.
CalculatorBloc calculatorBlocForTests() =>
    CalculatorTestHarness.disposedAfterTest().createBloc();

import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/enter_password_bloc/enter_password_bloc.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:construculator/libraries/analytics/testing/fake_analytics_repository.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the SignUp/SignIn/logout analytics event catalog (event name +
/// sorted property keys) against every real trigger path, so a typo'd
/// event name or a property rename shows up as an explicit, reviewable
/// diff here instead of shipping silently. See the analytics event
/// catalog doc linked on PR #508 for the source-of-truth property list.
void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAnalyticsRepository fakeAnalytics;
  late Clock clock;

  FakeUser createFakeUser(String email) {
    return FakeUser(
      id: 'fake-user-${email.hashCode}',
      email: email,
      createdAt: clock.now().toIso8601String(),
    );
  }

  String catalogEntry(AnalyticsEvent event) {
    final sortedKeys = event.properties.keys.toList()..sort();
    return '${event.name}: $sortedKeys';
  }

  setUp(() {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    fakeAnalytics =
        Modular.get<AnalyticsRepository>() as FakeAnalyticsRepository;
    clock = Modular.get<Clock>();
  });

  tearDown(() {
    fakeSupabase.reset();
    fakeAnalytics.resetFake();
    Modular.destroy();
  });

  test('SignUp/SignIn/logout analytics event catalog is unchanged', () async {
    final catalog = <String>[];

    // user_registered
    final createAccountBloc = Modular.get<CreateAccountBloc>();
    fakeSupabase.setCurrentUser(
      createFakeUser('catalog-register@example.com'),
    );
    createAccountBloc.add(
      const CreateAccountSubmitted(
        email: 'catalog-register@example.com',
        firstName: 'Cat',
        lastName: 'Alog',
        mobileNumber: '1234567890',
        password: 'securePassword',
        confirmPassword: 'securePassword',
        role: 'engineer',
        phonePrefix: '+1',
      ),
    );
    await createAccountBloc.stream.firstWhere(
      (s) => s is CreateAccountSuccess || s is CreateAccountFailure,
    );
    catalog.addAll(fakeAnalytics.trackedEvents.map(catalogEntry));
    fakeAnalytics.resetFake();

    // user_registration_failed
    fakeSupabase.shouldThrowOnUpdate = true;
    createAccountBloc.add(
      const CreateAccountSubmitted(
        email: 'catalog-register-fail@example.com',
        firstName: 'Cat',
        lastName: 'Alog',
        mobileNumber: '1234567890',
        password: 'securePassword',
        confirmPassword: 'securePassword',
        role: 'engineer',
        phonePrefix: '+1',
      ),
    );
    await createAccountBloc.stream.firstWhere(
      (s) => s is CreateAccountSuccess || s is CreateAccountFailure,
    );
    catalog.addAll(fakeAnalytics.trackedEvents.map(catalogEntry));
    fakeAnalytics.resetFake();
    fakeSupabase.shouldThrowOnUpdate = false;

    // user_logged_in
    final enterPasswordBloc = Modular.get<EnterPasswordBloc>();
    fakeSupabase.setCurrentUser(createFakeUser('catalog-login@example.com'));
    enterPasswordBloc.add(
      const EnterPasswordSubmitted(
        email: 'catalog-login@example.com',
        password: '@Password123!',
      ),
    );
    await enterPasswordBloc.stream.firstWhere(
      (s) => s is EnterPasswordSubmitSuccess || s is EnterPasswordSubmitFailure,
    );
    catalog.addAll(fakeAnalytics.trackedEvents.map(catalogEntry));
    fakeAnalytics.resetFake();

    // user_login_failed
    fakeSupabase.shouldThrowOnSignIn = true;
    enterPasswordBloc.add(
      const EnterPasswordSubmitted(
        email: 'catalog-login-fail@example.com',
        password: '@Password123!',
      ),
    );
    await enterPasswordBloc.stream.firstWhere(
      (s) => s is EnterPasswordSubmitSuccess || s is EnterPasswordSubmitFailure,
    );
    catalog.addAll(fakeAnalytics.trackedEvents.map(catalogEntry));
    fakeAnalytics.resetFake();
    fakeSupabase.shouldThrowOnSignIn = false;

    // user_logged_out
    final authManager = Modular.get<AuthManager>();
    await authManager.loginWithEmail(
      'catalog-logout@example.com',
      '@Password123!',
    );
    fakeAnalytics.resetFake();
    await authManager.logout();
    catalog.addAll(fakeAnalytics.trackedEvents.map(catalogEntry));

    expect(catalog..sort(), [
      'user_logged_in: []',
      'user_logged_out: []',
      'user_login_failed: [reason]',
      'user_registered: []',
      'user_registration_failed: [reason]',
    ]);
  });
}

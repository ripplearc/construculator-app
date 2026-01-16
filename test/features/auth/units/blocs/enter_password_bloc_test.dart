import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/features/auth/presentation/bloc/enter_password_bloc/enter_password_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late Clock clock;
  late EnterPasswordBloc bloc;

  FakeUser createFakeUser(String email) {
    return FakeUser(
      id: 'fake-user-${email.hashCode}',
      email: email,
      createdAt: clock.now().toIso8601String(),
    );
  }

  setUp(() {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    clock = Modular.get<Clock>();
    bloc = Modular.get<EnterPasswordBloc>();
  });

  tearDown(() {
    fakeSupabase.reset();
    Modular.destroy();
  });

  group('EnterPasswordBloc Tests', () {
    group('EnterPasswordSubmitted', () {
      blocTest<EnterPasswordBloc, EnterPasswordState>(
        'emits [EnterPasswordSubmitLoading, EnterPasswordSubmitSuccess] when login succeeds',
        build: () {
          fakeSupabase.setCurrentUser(createFakeUser('test@example.com'));
          return bloc;
        },
        act: (bloc) => bloc.add(
          EnterPasswordSubmitted(
            email: 'test@example.com',
            password: '@Password123!',
          ),
        ),
        expect: () => [
          EnterPasswordSubmitLoading(),
          EnterPasswordSubmitSuccess(),
        ],
      );

      blocTest<EnterPasswordBloc, EnterPasswordState>(
        'emits [EnterPasswordSubmitLoading, EnterPasswordSubmitFailure] when invalid credentials',
        build: () {
          fakeSupabase.shouldThrowOnSignIn = true;
          return bloc;
        },
        act: (bloc) => bloc.add(
          EnterPasswordSubmitted(
            email: 'test@example.com',
            password: 'wrongpassword',
          ),
        ),
        expect: () => [
          EnterPasswordSubmitLoading(),
          isA<EnterPasswordSubmitFailure>(),
        ],
      );
    });
    group('Multiple Login Attempts', () {
      blocTest<EnterPasswordBloc, EnterPasswordState>(
        'handles multiple consecutive login attempts',
        build: () {
          fakeSupabase.addTableData('users', [
            {
              'id': '1',
              'email': 'test@example.com',
              'created_at': clock.now().toIso8601String(),
            },
          ]);
          fakeSupabase.shouldThrowOnSignIn = false;
          return bloc;
        },
        act: (bloc) {
          bloc.add(
            EnterPasswordSubmitted(
              email: 'test@example.com',
              password: '@Password123!',
            ),
          );
          bloc.add(
            EnterPasswordSubmitted(
              email: 'test@example.com',
              password: '@Password123!',
            ),
          );
        },
        expect: () => [
          EnterPasswordSubmitLoading(),
          EnterPasswordSubmitSuccess(),
          EnterPasswordSubmitLoading(),
          EnterPasswordSubmitSuccess(),
        ],
      );

      blocTest<EnterPasswordBloc, EnterPasswordState>(
        'handles failed attempts followed by success',
        build: () {
          fakeSupabase.addTableData('users', [
            {
              'id': '1',
              'email': 'test@example.com',
              'created_at': clock.now().toIso8601String(),
            },
          ]);
          // First call fails, second succeeds
          fakeSupabase.shouldThrowOnSignIn = true;
          fakeSupabase.signInErrorMessage = 'Invalid credentials';
          return bloc;
        },
        act: (bloc) {
          bloc.add(
            EnterPasswordSubmitted(
              email: 'test@example.com',
              password: 'wrongpassword',
            ),
          );
          // Reset for second attempt
          fakeSupabase.shouldThrowOnSignIn = false;
          bloc.add(
            EnterPasswordSubmitted(
              email: 'test@example.com',
              password: '@Password123!',
            ),
          );
        },
        expect: () => [
          EnterPasswordSubmitLoading(),
          isA<EnterPasswordSubmitFailure>(),
          EnterPasswordSubmitLoading(),
          EnterPasswordSubmitSuccess(),
        ],
      );
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

void main() {
  group('ForgotPasswordBloc Tests', () {
    late FakeSupabaseWrapper fakeSupabase;
    late ForgotPasswordBloc bloc;

    setUp(() {
      Modular.init(AuthTestModule());
      fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      bloc = Modular.get<ForgotPasswordBloc>();
    });

    tearDown(() {
      fakeSupabase.reset();
      Modular.destroy();
    });

    group('ForgotPasswordSubmitted', () {
      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        'emits [ForgotPasswordLoading, ForgotPasswordSuccess] when password reset email sent successfully',
        build: () {
          fakeSupabase.shouldThrowOnResetPassword = false;
          return bloc;
        },
        act: (bloc) => bloc.add(ForgotPasswordSubmitted('user@example.com')),
        expect: () => [ForgotPasswordLoading(), ForgotPasswordSuccess()],
      );

      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        'emits [ForgotPasswordLoading, ForgotPasswordFailure] when email does not exist',
        build: () {
          fakeSupabase.shouldThrowOnResetPassword = true;
          return bloc;
        },
        act:
            (bloc) =>
                bloc.add(ForgotPasswordSubmitted('nonexistent@example.com')),
        expect: () => [ForgotPasswordLoading(), isA<ForgotPasswordFailure>()],
      );
    });
    group('Multiple Password Reset Attempts', () {
      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        'handles multiple consecutive password reset attempts',
        build: () {
          fakeSupabase.shouldThrowOnResetPassword = false;
          return bloc;
        },
        act: (bloc) {
          bloc.add(ForgotPasswordSubmitted('user1@example.com'));
          bloc.add(ForgotPasswordSubmitted('user2@example.com'));
        },
        expect:
            () => [
              ForgotPasswordLoading(),
              ForgotPasswordSuccess(),
              ForgotPasswordLoading(),
              ForgotPasswordSuccess(),
            ],
      );
      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        'handles rapid successive attempts for same email',
        build: () {
          fakeSupabase.shouldThrowOnResetPassword = false;
          return bloc;
        },
        act: (bloc) {
          bloc.add(ForgotPasswordSubmitted('user@example.com'));
          bloc.add(ForgotPasswordSubmitted('user@example.com'));
          bloc.add(ForgotPasswordSubmitted('user@example.com'));
        },
        expect:
            () => [
              ForgotPasswordLoading(),
              ForgotPasswordSuccess(),
              ForgotPasswordLoading(),
              ForgotPasswordSuccess(),
              ForgotPasswordLoading(),
              ForgotPasswordSuccess(),
            ],
      );
    });
    group('ForgotPasswordEditEmail', () {
      blocTest<ForgotPasswordBloc, ForgotPasswordState>(
        'emits [ForgotPasswordInitial] when edit email is triggered',
        build: () {
          return bloc;
        },
        act: (bloc) => bloc.add(ForgotPasswordEditEmail()),
        expect: () => [ForgotPasswordEditEmailSuccess()],
      );
    });
  });
}

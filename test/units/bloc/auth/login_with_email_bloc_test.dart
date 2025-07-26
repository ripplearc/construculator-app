import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/features/auth/presentation/bloc/login_with_email_bloc/login_with_email_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

void main() {
  group('LoginWithEmailBloc Tests', () {
    late FakeSupabaseWrapper fakeSupabase;
    late LoginWithEmailBloc bloc;
    const testEmail = 'test@example.com';

    setUp(() {
      Modular.init(AuthTestModule());
      fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      bloc = Modular.get<LoginWithEmailBloc>();
    });

    tearDown(() {
      fakeSupabase.reset();
      Modular.destroy();
    });

    group('LoginEmailChanged', () {
      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailAvailabilityLoading, LoginWithEmailAvailabilitySuccess] when email is registered',
        build: () {
          fakeSupabase.addTableData('users', [
            {
              'id': '1',
              'email': testEmail,
              'created_at': DateTime.now().toIso8601String(),
            },
          ]);
          return bloc;
        },
        act: (bloc) => bloc.add(LoginEmailChanged(testEmail)),
        expect:
            () => [
              LoginWithEmailAvailabilityLoading(),
              LoginWithEmailAvailabilitySuccess(isEmailRegistered: true),
            ],
      );

      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailAvailabilityLoading, LoginWithEmailAvailabilitySuccess] when email is not registered',
        build: () {
          fakeSupabase.shouldThrowOnSignIn = true;
          return bloc;
        },
        act: (bloc) => bloc.add(LoginEmailChanged(testEmail)),
        expect:
            () => [
              LoginWithEmailAvailabilityLoading(),
              LoginWithEmailAvailabilitySuccess(isEmailRegistered: false),
            ],
      );

      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailAvailabilityLoading, LoginWithEmailAvailabilityFailure] when backend error occurs',
        build: () {
          fakeSupabase.shouldThrowOnSelect = true;
          return bloc;
        },
        act: (bloc) => bloc.add(LoginEmailChanged(testEmail)),
        expect:
            () => [
              LoginWithEmailAvailabilityLoading(),
              isA<LoginWithEmailAvailabilityFailure>(),
            ],
      );
    });

    group('LoginEmailSubmitted', () {
      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailLoading, LoginWithEmailSuccess] when email submission succeeds',
        build: () {
          return bloc;
        },
        act: (bloc) => bloc.add(LoginEmailSubmitted(testEmail)),
        expect: () => [LoginWithEmailLoading(), LoginWithEmailSuccess()],
      );

      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailLoading, LoginWithEmailFailure] when email submission fails',
        build: () {
          fakeSupabase.shouldThrowOnSelect = true;
          return bloc;
        },
        act: (bloc) => bloc.add(LoginEmailSubmitted(testEmail)),
        expect: () => [LoginWithEmailLoading(), isA<LoginWithEmailFailure>()],
      );
    });
    group('Email Registration Status', () {
      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'correctly identifies unregistered email',
        build: () {
          return bloc;
        },
        act: (bloc) => bloc.add(LoginEmailChanged(testEmail)),
        expect:
            () => [
              LoginWithEmailAvailabilityLoading(),
              LoginWithEmailAvailabilitySuccess(isEmailRegistered: false),
            ],
      );
    });
  });
}

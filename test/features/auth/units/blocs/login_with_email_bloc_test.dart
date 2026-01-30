import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/features/auth/presentation/bloc/login_with_email_bloc/login_with_email_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

void main() {
  group('LoginWithEmailBloc Tests', () {
    late FakeSupabaseWrapper fakeSupabase;
    late LoginWithEmailBloc bloc;
    const testEmail = 'test@example.com';

    setUp(() {
      Modular.init(
        AuthModule(
          AppBootstrap(
            envLoader: FakeEnvLoader(),
            config: FakeAppConfig(),
            supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
          ),
        ),
      );
      fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      bloc = Modular.get<LoginWithEmailBloc>();
    });

    tearDown(() {
      fakeSupabase.reset();
      Modular.destroy();
    });

    group('LoginWithEmailFormFieldChanged', () {
      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailFormFieldValidated] with isValid=false when email is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const LoginWithEmailFormFieldChanged(
            field: LoginWithEmailFormField.email,
            value: '',
          ),
        ),
        expect: () => [
          isA<LoginWithEmailFormFieldValidated>()
              .having(
                (state) => state.field,
                'field',
                LoginWithEmailFormField.email,
              )
              .having((state) => state.isValid, 'isValid', false)
              .having((state) => state.validator, 'validator', isNotNull),
        ],
      );

      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailFormFieldValidated] with isValid=false when email is invalid',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const LoginWithEmailFormFieldChanged(
            field: LoginWithEmailFormField.email,
            value: 'invalid-email',
          ),
        ),
        expect: () => [
          isA<LoginWithEmailFormFieldValidated>()
              .having(
                (state) => state.field,
                'field',
                LoginWithEmailFormField.email,
              )
              .having((state) => state.isValid, 'isValid', false)
              .having((state) => state.validator, 'validator', isNotNull),
        ],
      );

      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailFormFieldValidated, LoginWithEmailAvailabilityLoading, LoginWithEmailAvailabilityCheckSuccess] when email is valid and triggers availability check',
        build: () {
          fakeSupabase.setRpcResponse('check_email_exists', false);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const LoginWithEmailFormFieldChanged(
            field: LoginWithEmailFormField.email,
            value: testEmail,
          ),
        ),
        expect: () => [
          isA<LoginWithEmailFormFieldValidated>()
              .having(
                (state) => state.field,
                'field',
                LoginWithEmailFormField.email,
              )
              .having((state) => state.isValid, 'isValid', true)
              .having((state) => state.validator, 'validator', null),
          LoginWithEmailAvailabilityLoading(),
          LoginWithEmailAvailabilityCheckSuccess(isEmailRegistered: false),
        ],
      );

      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailFormFieldValidated, LoginWithEmailAvailabilityLoading, LoginWithEmailAvailabilityCheckSuccess] when valid email is not registered',
        build: () {
          fakeSupabase.setRpcResponse('check_email_exists', false);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const LoginWithEmailFormFieldChanged(
            field: LoginWithEmailFormField.email,
            value: testEmail,
          ),
        ),
        expect: () => [
          isA<LoginWithEmailFormFieldValidated>()
              .having(
                (state) => state.field,
                'field',
                LoginWithEmailFormField.email,
              )
              .having((state) => state.isValid, 'isValid', true),
          LoginWithEmailAvailabilityLoading(),
          LoginWithEmailAvailabilityCheckSuccess(isEmailRegistered: false),
        ],
      );

      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailFormFieldValidated, LoginWithEmailAvailabilityLoading, LoginWithEmailAvailabilityCheckFailure] when availability check fails',
        build: () {
          fakeSupabase.shouldThrowOnSelect = true;
          return bloc;
        },
        act: (bloc) => bloc.add(
          const LoginWithEmailFormFieldChanged(
            field: LoginWithEmailFormField.email,
            value: testEmail,
          ),
        ),
        expect: () => [
          isA<LoginWithEmailFormFieldValidated>()
              .having(
                (state) => state.field,
                'field',
                LoginWithEmailFormField.email,
              )
              .having((state) => state.isValid, 'isValid', true),
          LoginWithEmailAvailabilityLoading(),
          isA<LoginWithEmailAvailabilityCheckFailure>(),
        ],
      );
    });

    group('LoginEmailAvailabilityCheckRequested', () {
      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailAvailabilityLoading, LoginWithEmailAvailabilityCheckSuccess] when email is registered',
        build: () {
          fakeSupabase.setRpcResponse('check_email_exists', true);
          return bloc;
        },
        act: (bloc) =>
            bloc.add(LoginEmailAvailabilityCheckRequested(testEmail)),
        expect: () => [
          LoginWithEmailAvailabilityLoading(),
          LoginWithEmailAvailabilityCheckSuccess(isEmailRegistered: true),
        ],
      );

      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailAvailabilityLoading, LoginWithEmailAvailabilityCheckSuccess] when email is not registered',
        build: () {
          fakeSupabase.setRpcResponse('check_email_exists', false);
          return bloc;
        },
        act: (bloc) =>
            bloc.add(LoginEmailAvailabilityCheckRequested(testEmail)),
        expect: () => [
          LoginWithEmailAvailabilityLoading(),
          LoginWithEmailAvailabilityCheckSuccess(isEmailRegistered: false),
        ],
      );

      blocTest<LoginWithEmailBloc, LoginWithEmailState>(
        'emits [LoginWithEmailAvailabilityLoading, LoginWithEmailAvailabilityCheckFailure] when backend error occurs',
        build: () {
          fakeSupabase.shouldThrowOnRpc = true;
          return bloc;
        },
        act: (bloc) =>
            bloc.add(LoginEmailAvailabilityCheckRequested(testEmail)),
        expect: () => [
          LoginWithEmailAvailabilityLoading(),
          isA<LoginWithEmailAvailabilityCheckFailure>(),
        ],
      );
    });
  });
}

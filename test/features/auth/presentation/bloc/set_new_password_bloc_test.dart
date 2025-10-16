import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/features/auth/presentation/bloc/set_new_password_bloc/set_new_password_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

void main() {
  group('SetNewPasswordBloc Tests', () {
    late FakeSupabaseWrapper fakeSupabase;
    late Clock clock;
    late SetNewPasswordBloc bloc;
    const testEmail = 'test@example.com';

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
      bloc = Modular.get<SetNewPasswordBloc>();
    });

    tearDown(() {
      fakeSupabase.reset();
      Modular.destroy();
    });

    group('SetNewPasswordPasswordValidationRequested', () {
      group('Password field validation', () {
        blocTest<SetNewPasswordBloc, SetNewPasswordState>(
          'emits [SetNewPasswordPasswordSuccess] with isValid=true when password is valid',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const SetNewPasswordPasswordValidationRequested(
              field: SetNewPasswordFormField.password,
              value: '@Password123!',
            ),
          ),
          expect: () => [
            const SetNewPasswordPasswordValidationSuccess(
              field: SetNewPasswordFormField.password,
              isValid: true,
              validator: null,
            ),
          ],
        );

        blocTest<SetNewPasswordBloc, SetNewPasswordState>(
          'emits [SetNewPasswordPasswordSuccess] with isValid=false when password is too short',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const SetNewPasswordPasswordValidationRequested(
              field: SetNewPasswordFormField.password,
              value: 'short',
            ),
          ),
          expect: () => [
            const SetNewPasswordPasswordValidationSuccess(
              field: SetNewPasswordFormField.password,
              isValid: false,
              validator: AuthErrorType.passwordTooShort,
            ),
          ],
        );

        blocTest<SetNewPasswordBloc, SetNewPasswordState>(
          'emits [SetNewPasswordPasswordSuccess] with isValid=false when password is empty',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const SetNewPasswordPasswordValidationRequested(
              field: SetNewPasswordFormField.password,
              value: '',
            ),
          ),
          expect: () => [
            const SetNewPasswordPasswordValidationSuccess(
              field: SetNewPasswordFormField.password,
              isValid: false,
              validator: AuthErrorType.passwordRequired,
            ),
          ],
        );

        blocTest<SetNewPasswordBloc, SetNewPasswordState>(
          'emits [SetNewPasswordPasswordSuccess] with isValid=false when password missing uppercase',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const SetNewPasswordPasswordValidationRequested(
              field: SetNewPasswordFormField.password,
              value: 'password123!',
            ),
          ),
          expect: () => [
            const SetNewPasswordPasswordValidationSuccess(
              field: SetNewPasswordFormField.password,
              isValid: false,
              validator: AuthErrorType.passwordMissingUppercase,
            ),
          ],
        );

        blocTest<SetNewPasswordBloc, SetNewPasswordState>(
          'emits [SetNewPasswordPasswordSuccess] with isValid=false when password missing number',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const SetNewPasswordPasswordValidationRequested(
              field: SetNewPasswordFormField.password,
              value: 'Password!',
            ),
          ),
          expect: () => [
            const SetNewPasswordPasswordValidationSuccess(
              field: SetNewPasswordFormField.password,
              isValid: false,
              validator: AuthErrorType.passwordMissingNumber,
            ),
          ],
        );

        blocTest<SetNewPasswordBloc, SetNewPasswordState>(
          'emits [SetNewPasswordPasswordSuccess] with isValid=false when password missing special character',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const SetNewPasswordPasswordValidationRequested(
              field: SetNewPasswordFormField.password,
              value: 'Password123',
            ),
          ),
          expect: () => [
            const SetNewPasswordPasswordValidationSuccess(
              field: SetNewPasswordFormField.password,
              isValid: false,
              validator: AuthErrorType.passwordMissingSpecialChar,
            ),
          ],
        );
      });

      group('Password confirmation field validation', () {
        blocTest<SetNewPasswordBloc, SetNewPasswordState>(
          'emits [SetNewPasswordPasswordSuccess] with isValid=true when passwords match',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const SetNewPasswordPasswordValidationRequested(
              field: SetNewPasswordFormField.passwordConfirmation,
              value: '@Password123!',
              passwordValue: '@Password123!',
            ),
          ),
          expect: () => [
            const SetNewPasswordPasswordValidationSuccess(
              field: SetNewPasswordFormField.passwordConfirmation,
              isValid: true,
              validator: null,
            ),
          ],
        );

        blocTest<SetNewPasswordBloc, SetNewPasswordState>(
          'emits [SetNewPasswordPasswordSuccess] with isValid=false when passwords do not match',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const SetNewPasswordPasswordValidationRequested(
              field: SetNewPasswordFormField.passwordConfirmation,
              value: '@Password123!',
              passwordValue: 'DifferentPassword123!',
            ),
          ),
          expect: () => [
            const SetNewPasswordPasswordValidationSuccess(
              field: SetNewPasswordFormField.passwordConfirmation,
              isValid: false,
              validator: AuthErrorType.passwordsDoNotMatch,
            ),
          ],
        );

        blocTest<SetNewPasswordBloc, SetNewPasswordState>(
          'emits [SetNewPasswordPasswordSuccess] with isValid=false when confirm password is empty',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const SetNewPasswordPasswordValidationRequested(
              field: SetNewPasswordFormField.passwordConfirmation,
              value: '',
              passwordValue: '@Password123!',
            ),
          ),
          expect: () => [
            const SetNewPasswordPasswordValidationSuccess(
              field: SetNewPasswordFormField.passwordConfirmation,
              isValid: false,
              validator: AuthErrorType.passwordRequired,
            ),
          ],
        );

        blocTest<SetNewPasswordBloc, SetNewPasswordState>(
          'emits [SetNewPasswordPasswordSuccess] with isValid=false when passwordValue is null',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const SetNewPasswordPasswordValidationRequested(
              field: SetNewPasswordFormField.passwordConfirmation,
              value: '@Password123!',
              passwordValue: null,
            ),
          ),
          expect: () => [
            const SetNewPasswordPasswordValidationSuccess(
              field: SetNewPasswordFormField.passwordConfirmation,
              isValid: true,
              validator: null,
            ),
          ],
        );
      });
    });

    group('SetNewPasswordSubmitted', () {
      blocTest<SetNewPasswordBloc, SetNewPasswordState>(
        'emits [SetNewPasswordLoading, SetNewPasswordSuccess] when password update succeeds',
        build: () {
          fakeSupabase.setCurrentUser(createFakeUser(testEmail));
          return bloc;
        },
        act: (bloc) => bloc.add(
          SetNewPasswordSubmitted(email: testEmail, password: '@Password123!'),
        ),
        expect: () => [SetNewPasswordLoading(), SetNewPasswordSuccess()],
      );

      blocTest<SetNewPasswordBloc, SetNewPasswordState>(
        'emits [SetNewPasswordLoading, SetNewPasswordFailure] when password is invalid',
        build: () {
          fakeSupabase.shouldThrowOnUpdate = true;
          return bloc;
        },
        act: (bloc) => bloc.add(
          SetNewPasswordSubmitted(email: testEmail, password: 'invalidpass'),
        ),
        expect: () => [SetNewPasswordLoading(), isA<SetNewPasswordFailure>()],
      );
    });
  });
}

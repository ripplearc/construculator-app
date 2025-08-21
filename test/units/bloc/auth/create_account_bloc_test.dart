import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late Clock clock;
  late CreateAccountBloc bloc;
  const testPhone = '+12019292918';
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
    bloc = Modular.get<CreateAccountBloc>();
  });

  tearDown(() {
    fakeSupabase.reset();
    Modular.destroy();
  });

  group('CreateAccountBloc', () {
    group('CreateAccountFormFieldChanged', () {
      group('firstName field', () {
        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=true when firstName is not empty',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.firstName,
              value: 'John',
              isEmailRegistration: true,
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.firstName,
                )
                .having((s) => s.isValid, 'isValid', true)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.firstNameRequired,
                ),
          ],
        );

        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=false when firstName is empty',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.firstName,
              value: '',
              isEmailRegistration: true,
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.firstName,
                )
                .having((s) => s.isValid, 'isValid', false)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.firstNameRequired,
                ),
          ],
        );
      });

      group('lastName field', () {
        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=true when lastName is not empty',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.lastName,
              value: 'Doe',
              isEmailRegistration: true,
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.lastName,
                )
                .having((s) => s.isValid, 'isValid', true)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.lastNameRequired,
                ),
          ],
        );

        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=false when lastName is empty',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.lastName,
              value: '',
              isEmailRegistration: true,
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.lastName,
                )
                .having((s) => s.isValid, 'isValid', false)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.lastNameRequired,
                ),
          ],
        );
      });

      group('role field', () {
        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=true when role is not empty',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.role,
              value: 'engineer',
              isEmailRegistration: true,
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having((s) => s.field, 'field', CreateAccountFormField.role)
                .having((s) => s.isValid, 'isValid', true)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.roleRequired,
                ),
          ],
        );

        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=false when role is empty',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.role,
              value: '',
              isEmailRegistration: true,
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having((s) => s.field, 'field', CreateAccountFormField.role)
                .having((s) => s.isValid, 'isValid', false)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.roleRequired,
                ),
          ],
        );
      });

      group('email field', () {
        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=true when email is valid',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.email,
              value: 'test@example.com',
              isEmailRegistration: true,
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having((s) => s.field, 'field', CreateAccountFormField.email)
                .having((s) => s.isValid, 'isValid', true)
                .having((s) => s.validator, 'validator', null),
          ],
        );

        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=false when email is invalid',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.email,
              value: 'invalid-email',
              isEmailRegistration: true,
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having((s) => s.field, 'field', CreateAccountFormField.email)
                .having((s) => s.isValid, 'isValid', false)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.invalidEmail,
                ),
          ],
        );

        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=false when email is empty',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.email,
              value: '',
              isEmailRegistration: true,
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having((s) => s.field, 'field', CreateAccountFormField.email)
                .having((s) => s.isValid, 'isValid', false)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.emailRequired,
                ),
          ],
        );
      });

      group('mobileNumber field', () {
        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=true when phone number is valid',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.mobileNumber,
              value: '1234567890',
              isEmailRegistration: true,
              phonePrefix: '+1',
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.mobileNumber,
                )
                .having((s) => s.isValid, 'isValid', true)
                .having((s) => s.validator, 'validator', null),
          ],
        );

        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=false when phone number is invalid',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.mobileNumber,
              value: '123',
              isEmailRegistration: true,
              phonePrefix: '+1',
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.mobileNumber,
                )
                .having((s) => s.isValid, 'isValid', false)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.invalidPhone,
                ),
          ],
        );

        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=true when phone is empty for email registration',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.mobileNumber,
              value: '',
              isEmailRegistration: true,
              phonePrefix: '+1',
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.mobileNumber,
                )
                .having((s) => s.isValid, 'isValid', true)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.phoneRequired,
                ),
          ],
        );

        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=false when phone is empty for phone registration',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.mobileNumber,
              value: '',
              isEmailRegistration: false,
              phonePrefix: '+1',
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.mobileNumber,
                )
                .having((s) => s.isValid, 'isValid', false)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.invalidPhone,
                ),
          ],
        );
      });

      group('password field', () {
        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=true when password is valid',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.password,
              value: 'SecurePass123!',
              isEmailRegistration: true,
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.password,
                )
                .having((s) => s.isValid, 'isValid', true)
                .having((s) => s.validator, 'validator', null),
          ],
        );

        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=false when password is too short',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.password,
              value: '123',
              isEmailRegistration: true,
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.password,
                )
                .having((s) => s.isValid, 'isValid', false)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.passwordTooShort,
                ),
          ],
        );

        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=false when password is empty',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.password,
              value: '',
              isEmailRegistration: true,
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.password,
                )
                .having((s) => s.isValid, 'isValid', false)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.passwordRequired,
                ),
          ],
        );
      });

      group('confirmPassword field', () {
        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=true when confirm password matches',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.confirmPassword,
              value: 'SecurePass123!',
              isEmailRegistration: true,
              passwordValue: 'SecurePass123!',
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.confirmPassword,
                )
                .having((s) => s.isValid, 'isValid', true)
                .having((s) => s.validator, 'validator', null),
          ],
        );

        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=false when confirm password is empty',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.confirmPassword,
              value: '',
              isEmailRegistration: true,
              passwordValue: 'SecurePass123!',
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.confirmPassword,
                )
                .having((s) => s.isValid, 'isValid', false)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.passwordRequired,
                ),
          ],
        );

        blocTest<CreateAccountBloc, CreateAccountState>(
          'emits [CreateAccountFormFieldValidated] with isValid=false when confirm password does not match',
          build: () => bloc,
          act: (bloc) => bloc.add(
            const CreateAccountFormFieldChanged(
              field: CreateAccountFormField.confirmPassword,
              value: 'DifferentPass123!',
              isEmailRegistration: true,
              passwordValue: 'SecurePass123!',
            ),
          ),
          expect: () => [
            isA<CreateAccountFormFieldValidated>()
                .having(
                  (s) => s.field,
                  'field',
                  CreateAccountFormField.confirmPassword,
                )
                .having((s) => s.isValid, 'isValid', false)
                .having(
                  (s) => s.validator,
                  'validator',
                  AuthErrorType.passwordsDoNotMatch,
                ),
          ],
        );
      });
    });

    blocTest<CreateAccountBloc, CreateAccountState>(
      'emits [Loading, Success] when LoadProfessionalRoles succeeds',
      build: () {
        fakeSupabase.addTableData('professional_roles', [
          {'id': '1', 'name': 'Engineer'},
        ]);
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateAccountGetProfessionalRolesRequested()),
      expect:
          () => [
            isA<CreateAccountGetProfessionalRolesLoading>(),
            isA<CreateAccountGetProfessionalRolesSuccess>().having(
              (s) => s.professionalRolesList.first.name,
              'role',
              'Engineer',
            ),
          ],
    );

    blocTest<CreateAccountBloc, CreateAccountState>(
      'emits [OtpSending, OtpSendingSuccess] on successful OTP send',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const CreateAccountSendOtpRequested(
          address: testPhone,
          isEmailRegistration: true,
        ),
      ),
      expect: () => [
        isA<CreateAccountOtpSending>(),
        isA<CreateAccountOtpSendingSuccess>().having(
          (s) => s.contact,
          'contact',
          testPhone,
        ),
      ],
    );

    blocTest<CreateAccountBloc, CreateAccountState>(
      'emits [OtpSending, OtpSendingFailure] when OTP send fails',
      build: () {
        fakeSupabase.shouldThrowOnOtp = true;
        return bloc;
      },
      act: (bloc) => bloc.add(
        const CreateAccountSendOtpRequested(
          address: testEmail,
          isEmailRegistration: true,
        ),
      ),
      expect: () => [
        isA<CreateAccountOtpSending>(),
        isA<CreateAccountOtpSendingFailure>().having(
          (s) => s.failure,
          'failure',
          isA<AuthFailure>(),
        ),
      ],
    );

    blocTest<CreateAccountBloc, CreateAccountState>(
      'emits [CreateAccountContactVerified] on CreateAccountOtpVerified',
      build: () => bloc,
      act: (bloc) =>
          bloc.add(const CreateAccountOtpVerified(contact: testEmail)),
      expect: () => [isA<CreateAccountContactVerified>()],
    );

    blocTest<CreateAccountBloc, CreateAccountState>(
      'emits [CreateAccountEditContactTriggered] on CreateAccountEditContactPressed',
      build: () => bloc,
      act: (bloc) => bloc.add(CreateAccountEditContactPressed()),
      expect: () => [isA<CreateAccountEditContactSuccess>()],
    );

    blocTest<CreateAccountBloc, CreateAccountState>(
      'emits [Loading, Success] on CreateAccountSubmitted success',
      build: () {
        fakeSupabase.setCurrentUser(createFakeUser('john@example.com'));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const CreateAccountSubmitted(
          email: 'john@example.com',
          firstName: 'John',
          lastName: 'Doe',
          mobileNumber: '1234567890',
          password: 'securePassword',
          confirmPassword: 'securePassword',
          role: 'engineer',
          phonePrefix: '+1',
        ),
      ),
      expect: () => [isA<CreateAccountLoading>(), isA<CreateAccountSuccess>()],
    );

    blocTest<CreateAccountBloc, CreateAccountState>(
      'emits [Loading, Failure] when password update fails',
      build: () {
        fakeSupabase.shouldThrowOnUpdate = true;
        return bloc;
      },
      act: (bloc) => bloc.add(
        const CreateAccountSubmitted(
          email: 'fail-password@example.com',
          firstName: 'John',
          lastName: 'Doe',
          mobileNumber: '1234567890',
          password: 'badPassword',
          confirmPassword: 'badPassword',
          role: 'engineer',
          phonePrefix: '+1',
        ),
      ),
      expect: () => [
        isA<CreateAccountLoading>(),
        isA<CreateAccountFailure>().having(
          (s) => s.failure,
          'failure',
          isA<AuthFailure>(),
        ),
      ],
    );

    blocTest<CreateAccountBloc, CreateAccountState>(
      'emits [Loading, Failure] when user profile creation fails',
      build: () {
        fakeSupabase.shouldThrowOnInsert = true;
        return bloc;
      },
      act: (bloc) => bloc.add(
        const CreateAccountSubmitted(
          email: 'fail-insert@example.com',
          firstName: 'Jane',
          lastName: 'Smith',
          mobileNumber: '1234567890',
          password: 'securePassword',
          confirmPassword: 'securePassword',
          role: 'manager',
          phonePrefix: '+1',
        ),
      ),
      expect: () => [
        isA<CreateAccountLoading>(),
        isA<CreateAccountFailure>().having(
          (s) => s.failure,
          'failure',
          isA<AuthFailure>(),
        ),
      ],
    );
  });
}

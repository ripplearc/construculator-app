import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:construculator/libraries/analytics/testing/fake_analytics_repository.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAnalyticsRepository fakeAnalytics;
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
    fakeAnalytics =
        Modular.get<AnalyticsRepository>() as FakeAnalyticsRepository;
    clock = Modular.get<Clock>();
    bloc = Modular.get<CreateAccountBloc>();
  });

  tearDown(() {
    fakeSupabase.reset();
    fakeAnalytics.resetFake();
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
      act: (bloc) =>
          bloc.add(const CreateAccountGetProfessionalRolesRequested()),
      expect: () => [
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
      verify: (_) {
        expect(fakeAnalytics.trackedEvents, [
          const AnalyticsEvent(name: 'user_registered'),
        ]);
      },
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
      verify: (_) {
        expect(fakeAnalytics.trackedEvents, [
          const AnalyticsEvent(
            name: 'user_registration_failed',
            properties: {'reason': 'serverError'},
          ),
        ]);
      },
    );

    blocTest<CreateAccountBloc, CreateAccountState>(
      'emits [Loading, Failure] when user profile creation fails',
      build: () {
        fakeSupabase.setCurrentUser(createFakeUser('fail-insert@example.com'));
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
      verify: (_) {
        expect(fakeAnalytics.trackedEvents, [
          const AnalyticsEvent(
            name: 'user_registration_failed',
            properties: {'reason': 'serverError'},
          ),
        ]);
      },
    );

    group('consent recording', () {
      const submitted = CreateAccountSubmitted(
        email: 'consent@example.com',
        firstName: 'John',
        lastName: 'Doe',
        mobileNumber: '1234567890',
        password: 'securePassword',
        confirmPassword: 'securePassword',
        role: 'engineer',
        phonePrefix: '+1',
      );

      final requiredVersion = ConsentVersion(
        id: 'version-1',
        consentType: ConsentType.termsAndPrivacy,
        version: 1,
        documentUrl: 'https://example.com/terms/v1',
        publishedAt: DateTime.utc(2026, 8, 11),
      );

      late FakeConsentRepository consent;

      setUp(() {
        consent = Modular.get<ConsentRepository>() as FakeConsentRepository;
        fakeSupabase.setCurrentUser(createFakeUser('consent@example.com'));
      });

      blocTest<CreateAccountBloc, CreateAccountState>(
        'records an acceptance before reporting success',
        // The success state is what routes to the shell, so the record has to
        // exist by the time it is emitted or ConsentGuard blocks the account
        // signup just created.
        build: () {
          consent.cachedStatusToReturn = ConsentNeverGiven(requiredVersion);
          return bloc;
        },
        act: (bloc) => bloc.add(submitted),
        expect: () => [
          isA<CreateAccountLoading>(),
          isA<CreateAccountSuccess>(),
        ],
        verify: (_) => expect(consent.recordedAcceptances, [
          (consentType: ConsentType.termsAndPrivacy, version: 1),
        ]),
      );

      blocTest<CreateAccountBloc, CreateAccountState>(
        'records the published version when one is already outdated',
        build: () {
          consent.cachedStatusToReturn = ConsentOutdated(
            acceptedVersion: 0,
            requiredVersion: requiredVersion,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(submitted),
        // N3: this used to assert only the write happened, never that the
        // bloc actually reached success -- a regression that recorded and
        // then failed the signup anyway would have passed unchanged.
        expect: () => [
          isA<CreateAccountLoading>(),
          isA<CreateAccountSuccess>(),
        ],
        verify: (_) => expect(consent.recordedAcceptances, [
          (consentType: ConsentType.termsAndPrivacy, version: 1),
        ]),
      );

      blocTest<CreateAccountBloc, CreateAccountState>(
        'writes nothing when the check failed but an acceptance is on file',
        // ConsentUnverified: same "nothing new to record" outcome as
        // ConsentSatisfied, previously untested on its own.
        build: () {
          consent.cachedStatusToReturn = const ConsentUnverified(1);
          return bloc;
        },
        act: (bloc) => bloc.add(submitted),
        expect: () => [
          isA<CreateAccountLoading>(),
          isA<CreateAccountSuccess>(),
        ],
        verify: (_) => expect(consent.recordedAcceptances, isEmpty),
      );

      blocTest<CreateAccountBloc, CreateAccountState>(
        'writes nothing when an acceptance is already on file',
        build: () {
          consent.cachedStatusToReturn = const ConsentSatisfied(1);
          return bloc;
        },
        act: (bloc) => bloc.add(submitted),
        expect: () => [
          isA<CreateAccountLoading>(),
          isA<CreateAccountSuccess>(),
        ],
        verify: (_) => expect(consent.recordedAcceptances, isEmpty),
      );

      blocTest<CreateAccountBloc, CreateAccountState>(
        'fails the signup when the consent write fails',
        // Advancing here would land the user in the shell believing they had
        // consented, with no record to show for it.
        build: () {
          consent
            ..cachedStatusToReturn = ConsentNeverGiven(requiredVersion)
            ..acceptanceResultToReturn = const Left(
              ConsentFailure(errorType: ConsentErrorType.connectionError),
            );
          return bloc;
        },
        act: (bloc) => bloc.add(submitted),
        expect: () => [
          isA<CreateAccountLoading>(),
          isA<CreateAccountFailure>().having(
            (s) => s.failure,
            'failure',
            isA<ConsentFailure>(),
          ),
        ],
      );

      // N4: neither of these two branches had any coverage. Both used to
      // silently return null -- reporting a successful signup while
      // recording nothing -- and both are reachable for a brand-new user:
      // the session token is minted before createUserProfile runs, so a
      // missing internal_user_id claim (-> the synthetic ConsentSatisfied
      // sentinel) or a local read that hasn't warmed up yet (->
      // ConsentIndeterminate) are the likely case, not the exception.
      blocTest<CreateAccountBloc, CreateAccountState>(
        'fails the signup rather than silently succeeding when the '
        'internal user id could not be identified',
        build: () {
          consent.cachedStatusToReturn = const ConsentSatisfied(
            ConsentRepository.noUserVersion,
          );
          return bloc;
        },
        act: (bloc) => bloc.add(submitted),
        expect: () => [
          isA<CreateAccountLoading>(),
          isA<CreateAccountFailure>().having(
            (s) => s.failure,
            'failure',
            const ConsentFailure(
              errorType: ConsentErrorType.authenticationError,
            ),
          ),
        ],
        verify: (_) => expect(consent.recordedAcceptances, isEmpty),
      );

      blocTest<CreateAccountBloc, CreateAccountState>(
        'fails the signup rather than silently succeeding when the '
        'requirement could not be established',
        build: () {
          consent.cachedStatusToReturn = const ConsentIndeterminate(ConsentType.termsAndPrivacy);
          return bloc;
        },
        act: (bloc) => bloc.add(submitted),
        expect: () => [
          isA<CreateAccountLoading>(),
          isA<CreateAccountFailure>().having(
            (s) => s.failure,
            'failure',
            const ConsentFailure(errorType: ConsentErrorType.unexpectedError),
          ),
        ],
        verify: (_) => expect(consent.recordedAcceptances, isEmpty),
      );

      blocTest<CreateAccountBloc, CreateAccountState>(
        'does not check or record consent at all when the gate flag is off',
        // The flag already governs whether ConsentGuard is registered on
        // the shell (shell_module.dart); this proves the one thing that
        // actually writes today is inert under the same flag, not just the
        // route guard's UI.
        build: () {
          (Modular.get<EnvLoader>() as FakeEnvLoader).setEnvVar(
            consentGateEnabledKey,
            'false',
          );
          consent.cachedStatusToReturn = ConsentNeverGiven(requiredVersion);
          return bloc;
        },
        act: (bloc) => bloc.add(submitted),
        expect: () => [
          isA<CreateAccountLoading>(),
          isA<CreateAccountSuccess>(),
        ],
        verify: (_) {
          expect(consent.cachedStatusRequests, isEmpty);
          expect(consent.recordedAcceptances, isEmpty);
        },
      );
    });
  });
}

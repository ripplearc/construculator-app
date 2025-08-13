import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late CreateAccountBloc bloc;
  const testPhone = '+12019292918';
  const testEmail = 'test@example.com';
  
  FakeUser createFakeUser(String email) {
    return FakeUser(
      id: 'fake-user-${email.hashCode}',
      email: email,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  setUp(() {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    bloc = Modular.get<CreateAccountBloc>();
  });

  tearDown(() {
    fakeSupabase.reset();
    Modular.destroy();
  });

  group('CreateAccountBloc', () {
    blocTest<CreateAccountBloc, CreateAccountState>(
      'emits [Loading, Success] when LoadProfessionalRoles succeeds',
      build: () {
        fakeSupabase.addTableData('professional_roles', [
          {'id': '1', 'name': 'Engineer'},
        ]);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadProfessionalRoles()),
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
      act:
          (bloc) => bloc.add(
            const CreateAccountSendOtpRequested(
              address: testPhone,
              isEmailRegistration: true,
            ),
          ),
      expect:
          () => [
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
      act:
          (bloc) => bloc.add(
            const CreateAccountSendOtpRequested(
              address: testEmail,
              isEmailRegistration: true,
            ),
          ),
      expect:
          () => [
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
      act:
          (bloc) => bloc.add(
            const CreateAccountOtpVerified(contact: testEmail),
          ),
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
      act:
          (bloc) => bloc.add(
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
      act:
          (bloc) => bloc.add(
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
      expect:
          () => [
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
      act:
          (bloc) => bloc.add(
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
      expect:
          () => [
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

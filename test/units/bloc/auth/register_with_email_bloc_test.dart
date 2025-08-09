import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/features/auth/presentation/bloc/register_with_email_bloc/register_with_email_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late RegisterWithEmailBloc bloc;
  const testEmail = 'test@example.com';

  setUp(() {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    bloc = Modular.get<RegisterWithEmailBloc>();
  });

  tearDown(() {
    fakeSupabase.reset();
    Modular.destroy();
  });
  group('RegisterWithEmailBloc Tests', () {
    group('RegisterWithEmailEmailChanged', () {
      test('emits [RegisterWithEmailInitial] when email is empty', () async {
        bloc.add(RegisterWithEmailEmailChanged(''));
        await expectLater(
          bloc.stream,
          emitsInOrder([
            RegisterWithEmailEmailCheckLoading(),
            RegisterWithEmailEmailCheckFailure(
              failure: AuthFailure(errorType: AuthErrorType.unknownError),
            ),
          ]),
        );
      });

      test(
        'emits [RegisterWithEmailEmailCheckLoading, RegisterWithEmailEmailCheckSuccess] when email is available',
        () async {
          bloc.add(RegisterWithEmailEmailChanged(testEmail));
          await expectLater(
            bloc.stream,
            emitsInOrder([
              RegisterWithEmailEmailCheckLoading(),
              RegisterWithEmailEmailCheckCompleted(isEmailRegistered: false),
            ]),
          );
        },
      );

      test(
        'emits [RegisterWithEmailEmailCheckLoading, RegisterWithEmailEmailCheckSuccess] when email is taken',
        () async {
          fakeSupabase.addTableData('users', [
            {
              'id': '1',
              'email': testEmail,
              'created_at': DateTime.now().toIso8601String(),
            },
          ]);
          bloc.add(RegisterWithEmailEmailChanged(testEmail));
          await expectLater(
            bloc.stream,
            emitsInOrder([
              RegisterWithEmailEmailCheckLoading(),
              RegisterWithEmailEmailCheckCompleted(isEmailRegistered: true),
            ]),
          );
        },
      );

      test(
        'emits [RegisterWithEmailEmailCheckLoading, RegisterWithEmailEmailCheckFailure] when backend error occurs',
        () async {
          fakeSupabase.shouldThrowOnSelect = true;
          bloc.add(RegisterWithEmailEmailChanged(testEmail));
          await expectLater(
            bloc.stream,
            emitsInOrder([
              RegisterWithEmailEmailCheckLoading(),
              isA<RegisterWithEmailEmailCheckFailure>(),
            ]),
          );
        },
      );
    });

    group('RegisterWithEmailContinuePressed', () {
      blocTest<RegisterWithEmailBloc, RegisterWithEmailState>(
        'emits [RegisterWithEmailOtpSendingLoading, RegisterWithEmailOtpSendingSuccess] when OTP sending succeeds',
        build: () {
          fakeSupabase.shouldThrowOnOtp = false;
          return bloc;
        },
        act: (bloc) => bloc.add(RegisterWithEmailContinuePressed(testEmail)),
        expect:
            () => [
              RegisterWithEmailOtpSendingLoading(),
              RegisterWithEmailOtpSendingSuccess(),
            ],
      );

      blocTest<RegisterWithEmailBloc, RegisterWithEmailState>(
        'emits [RegisterWithEmailOtpSendingLoading, RegisterWithEmailOtpSendingFailure] when OTP sending fails',
        build: () {
          fakeSupabase.shouldThrowOnOtp = true;
          return bloc;
        },
        act: (bloc) => bloc.add(RegisterWithEmailContinuePressed(testEmail)),
        expect:
            () => [
              RegisterWithEmailOtpSendingLoading(),
              isA<RegisterWithEmailOtpSendingFailure>(),
            ],
      );
    });

    group('RegisterWithEmailEditEmail', () {
      test(
        'emits [RegisterWithEmailEditUserEmail] when edit email is triggered',
        () async {
          bloc.add(RegisterWithEmailEditEmail());
          await expectLater(
            bloc.stream,
            emitsInOrder([isA<RegisterWithEmailEditUserEmail>()]),
          );
        },
      );
    });

  });
}

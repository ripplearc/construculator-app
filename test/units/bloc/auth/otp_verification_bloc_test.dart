import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

void main() {
  group('OtpVerificationBloc Tests', () {
    late FakeSupabaseWrapper fakeSupabase;
    late OtpVerificationBloc bloc;
    const testEmail = 'test@example.com';

    setUp(() {
      Modular.init(AuthTestModule());
      fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
      bloc = Modular.get<OtpVerificationBloc>();
    });

    tearDown(() {
      fakeSupabase.reset();
      Modular.destroy();
    });

    group('OtpVerificationSubmitted', () {
      blocTest<OtpVerificationBloc, OtpVerificationState>(
        'emits [OtpVerificationLoading, OtpVerificationSuccess] when OTP verification succeeds',
        build: () {
          fakeSupabase.shouldThrowOnVerifyOtp = false;
          return bloc;
        },
        act:
            (bloc) => bloc.add(
              OtpVerificationSubmitted(
                contact: testEmail,
                otp: '123456',
              ),
            ),
        expect:
            () => [
              OtpVerificationLoading(),
              OtpVerificationSuccess(email: testEmail),
            ],
      );

      blocTest<OtpVerificationBloc, OtpVerificationState>(
        'emits [OtpVerificationLoading, OtpVerificationFailure] when OTP is invalid',
        build: () {
          return bloc;
        },
        act:
            (bloc) => bloc.add(
              OtpVerificationSubmitted(contact: testEmail, otp: '000'),
            ),
        expect: () => [OtpVerificationLoading(), isA<OtpVerificationFailure>()],
      );
    });

    group('OtpVerificationResendRequested', () {
      blocTest<OtpVerificationBloc, OtpVerificationState>(
        'emits [OtpVerificationResendLoading, OtpVerificationOtpResent] when OTP resend succeeds',
        build: () {
          return bloc;
        },
        act:
            (bloc) => bloc.add(
              OtpVerificationResendRequested(contact: testEmail),
            ),
        expect:
            () => [OtpVerificationResendLoading(), OtpVerificationOtpResendSuccess()],
      );

      blocTest<OtpVerificationBloc, OtpVerificationState>(
        'emits [OtpVerificationResendLoading, OtpVerificationResendFailure] when OTP resend fails',
        build: () {
          fakeSupabase.shouldThrowOnOtp = true;
          return bloc;
        },
        act:
            (bloc) => bloc.add(
              OtpVerificationResendRequested(contact: testEmail),
            ),
        expect:
            () => [
              OtpVerificationResendLoading(),
              isA<OtpVerificationResendFailure>(),
            ],
      );
    });

    group('OtpVerificationOtpChanged', () {
      blocTest<OtpVerificationBloc, OtpVerificationState>(
        'emits [OtpVerificationOtpChangeUpdated] when OTP input changes',
        build: () {
          return bloc;
        },
        act: (bloc) => bloc.add(
          OtpVerificationOtpChanged(otp: '123456'),
        ),
        expect: () => [
          OtpVerificationOtpChangeSuccess(otp: '123456', otpInvalid: false),
        ],
      );

      blocTest<OtpVerificationBloc, OtpVerificationState>(
        'emits [OtpVerificationOtpChangeUpdated] when OTP input changes to empty string',
        build: () {
          return bloc;
        },
        act: (bloc) => bloc.add(
          OtpVerificationOtpChanged(otp: ''),
        ),
        expect: () => [
          OtpVerificationOtpChangeSuccess(otp: '', otpInvalid: true),
        ],
      );

      blocTest<OtpVerificationBloc, OtpVerificationState>(
        'emits [OtpVerificationOtpChangeUpdated] when OTP input changes to partial value',
        build: () {
          return bloc;
        },
        act: (bloc) => bloc.add(
          OtpVerificationOtpChanged(otp: '123'),
        ),
        expect: () => [
          OtpVerificationOtpChangeSuccess(otp: '123', otpInvalid: true),
        ],
      );
    });
 });
}

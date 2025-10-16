import 'package:construculator/features/auth/domain/usecases/check_email_availability_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/register_with_email_bloc/register_with_email_bloc.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/modular/testing/fake_injector.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeInjector fakeInjector;

  setUp(() {
    fakeInjector = FakeInjector();
  });

  FakeAuthManager createFakeAuthManager() {
    final clock = FakeClockImpl();
    return FakeAuthManager(
      authNotifier: FakeAuthNotifier(),
      authRepository: FakeAuthRepository(clock: clock),
      wrapper: FakeSupabaseWrapper(clock: clock),
      clock: clock,
    );
  }

  group('FakeInjector', () {
    group('initial state', () {
      test('should start with zero counts', () {
        expect(fakeInjector.addLazySingletonCalls, 0);
        expect(fakeInjector.addCalls, 0);
        expect(fakeInjector.executedUseCaseFactories, 0);
        expect(fakeInjector.executedBlocFactories, 0);
        expect(fakeInjector.executedFactories, 0);
        expect(fakeInjector.useCaseFactories, 0);
        expect(fakeInjector.blocFactories, 0);
        expect(fakeInjector.lazySingletonCalls, 0);
        expect(fakeInjector.createdUseCases, isEmpty);
        expect(fakeInjector.createdBlocs, isEmpty);
      });

      test('should have correct total dependencies', () {
        expect(fakeInjector.totalDependencies, 0);
        expect(fakeInjector.totalCalls, 0);
      });
    });

    group('addLazySingleton', () {
      test('should track successful use case creation', () {
        fakeInjector.addLazySingleton<ResetPasswordUseCase>(
          () => ResetPasswordUseCase(createFakeAuthManager()),
        );

        expect(fakeInjector.addLazySingletonCalls, 1);
        expect(fakeInjector.lazySingletonCalls, 1);
        expect(fakeInjector.executedUseCaseFactories, 1);
        expect(fakeInjector.executedFactories, 1);
        expect(
          fakeInjector.useCaseFactories,
          1,
        ); // ResetPasswordUseCase contains "UseCase"
        expect(fakeInjector.createdUseCases, contains('ResetPasswordUseCase'));
      });

      test('should track multiple use case creations', () {
        fakeInjector.addLazySingleton<ResetPasswordUseCase>(
          () => ResetPasswordUseCase(createFakeAuthManager()),
        );
        fakeInjector.addLazySingleton<CreateAccountUseCase>(
          () => CreateAccountUseCase(createFakeAuthManager(), FakeClockImpl()),
        );

        expect(fakeInjector.addLazySingletonCalls, 2);
        expect(fakeInjector.lazySingletonCalls, 2);
        expect(fakeInjector.executedUseCaseFactories, 2);
        expect(fakeInjector.executedFactories, 2);
        expect(fakeInjector.useCaseFactories, 2);
        expect(fakeInjector.createdUseCases, contains('ResetPasswordUseCase'));
        expect(fakeInjector.createdUseCases, contains('CreateAccountUseCase'));
      });

      test('should handle factory function exceptions', () {
        fakeInjector.addLazySingleton<ResetPasswordUseCase>(
          () => throw Exception('Dependency not found'),
        );

        expect(fakeInjector.addLazySingletonCalls, 1);
        expect(fakeInjector.lazySingletonCalls, 1);
        expect(fakeInjector.executedUseCaseFactories, 1);
        expect(fakeInjector.executedFactories, 1);
        expect(fakeInjector.useCaseFactories, 0);
        expect(fakeInjector.createdUseCases, isEmpty);
      });

      test('should handle non-use case types', () {
        fakeInjector.addLazySingleton<String>(() => 'test string');

        expect(fakeInjector.addLazySingletonCalls, 1);
        expect(fakeInjector.lazySingletonCalls, 1);
        expect(fakeInjector.executedUseCaseFactories, 1);
        expect(fakeInjector.executedFactories, 1);
        expect(fakeInjector.useCaseFactories, 0);
        expect(fakeInjector.createdUseCases, isEmpty);
      });

      test('should track factory execution even when result is null', () {
        fakeInjector.addLazySingleton<String>(() => '');

        expect(fakeInjector.addLazySingletonCalls, 1);
        expect(fakeInjector.executedFactories, 1);
      });
    });

    group('add', () {
      test('should track successful bloc creation', () {
        fakeInjector.add<RegisterWithEmailBloc>(
          () => RegisterWithEmailBloc(
            checkEmailAvailabilityUseCase: CheckEmailAvailabilityUseCase(
              createFakeAuthManager(),
            ),
            sendOtpUseCase: SendOtpUseCase(createFakeAuthManager()),
          ),
        );

        expect(fakeInjector.addCalls, 1);
        expect(fakeInjector.executedBlocFactories, 1);
        expect(fakeInjector.executedFactories, 1);
        expect(fakeInjector.blocFactories, 1);
        expect(fakeInjector.createdBlocs, contains('RegisterWithEmailBloc'));
      });

      test('should track multiple bloc creations', () {
        fakeInjector.add<RegisterWithEmailBloc>(
          () => RegisterWithEmailBloc(
            checkEmailAvailabilityUseCase: CheckEmailAvailabilityUseCase(
              createFakeAuthManager(),
            ),
            sendOtpUseCase: SendOtpUseCase(createFakeAuthManager()),
          ),
        );
        fakeInjector.add<OtpVerificationBloc>(
          () => OtpVerificationBloc(
            verifyOtpUseCase: VerifyOtpUseCase(createFakeAuthManager()),
            sendOtpUseCase: SendOtpUseCase(createFakeAuthManager()),
          ),
        );

        expect(fakeInjector.addCalls, 2);
        expect(fakeInjector.executedBlocFactories, 2);
        expect(fakeInjector.executedFactories, 2);
        expect(fakeInjector.blocFactories, 2);
        expect(fakeInjector.createdBlocs, contains('RegisterWithEmailBloc'));
        expect(fakeInjector.createdBlocs, contains('OtpVerificationBloc'));
      });

      test('should handle factory function exceptions', () {
        fakeInjector.add<RegisterWithEmailBloc>(
          () => throw Exception('Dependency not found'),
        );

        expect(fakeInjector.addCalls, 1);
        expect(fakeInjector.executedBlocFactories, 1);
        expect(fakeInjector.executedFactories, 1);
        expect(fakeInjector.blocFactories, 0);
        expect(fakeInjector.createdBlocs, isEmpty);
      });

      test('should handle non-bloc types', () {
        fakeInjector.add<String>(() => 'test string');

        expect(fakeInjector.addCalls, 1);
        expect(fakeInjector.executedBlocFactories, 1);
        expect(fakeInjector.executedFactories, 1);
        expect(fakeInjector.blocFactories, 0);
        expect(fakeInjector.createdBlocs, isEmpty);
      });
    });

    group('mixed operations', () {
      test('should track both use cases and blocs', () {
        fakeInjector.addLazySingleton<ResetPasswordUseCase>(
          () => ResetPasswordUseCase(createFakeAuthManager()),
        );
        fakeInjector.add<RegisterWithEmailBloc>(
          () => RegisterWithEmailBloc(
            checkEmailAvailabilityUseCase: CheckEmailAvailabilityUseCase(
              createFakeAuthManager(),
            ),
            sendOtpUseCase: SendOtpUseCase(createFakeAuthManager()),
          ),
        );

        expect(fakeInjector.totalDependencies, 2);
        expect(fakeInjector.totalCalls, 2);
        expect(fakeInjector.executedFactories, 2);
        expect(fakeInjector.useCaseFactories, 1);
        expect(fakeInjector.blocFactories, 1);
        expect(fakeInjector.createdUseCases, contains('ResetPasswordUseCase'));
        expect(fakeInjector.createdBlocs, contains('RegisterWithEmailBloc'));
      });

      test('should maintain separate counters', () {
        fakeInjector.addLazySingleton<ResetPasswordUseCase>(
          () => ResetPasswordUseCase(createFakeAuthManager()),
        );
        fakeInjector.addLazySingleton<CreateAccountUseCase>(
          () => CreateAccountUseCase(createFakeAuthManager(), FakeClockImpl()),
        );
        fakeInjector.add<RegisterWithEmailBloc>(
          () => RegisterWithEmailBloc(
            checkEmailAvailabilityUseCase: CheckEmailAvailabilityUseCase(
              createFakeAuthManager(),
            ),
            sendOtpUseCase: SendOtpUseCase(createFakeAuthManager()),
          ),
        );

        expect(fakeInjector.addLazySingletonCalls, 2);
        expect(fakeInjector.addCalls, 1);
        expect(fakeInjector.lazySingletonCalls, 2);
        expect(fakeInjector.executedUseCaseFactories, 2);
        expect(fakeInjector.executedBlocFactories, 1);
        expect(fakeInjector.totalDependencies, 3);
        expect(fakeInjector.totalCalls, 3);
      });
    });

    group('reset', () {
      test('should reset all counters and lists', () {
        fakeInjector.addLazySingleton<ResetPasswordUseCase>(
          () => ResetPasswordUseCase(createFakeAuthManager()),
        );
        fakeInjector.add<RegisterWithEmailBloc>(
          () => RegisterWithEmailBloc(
            checkEmailAvailabilityUseCase: CheckEmailAvailabilityUseCase(
              createFakeAuthManager(),
            ),
            sendOtpUseCase: SendOtpUseCase(createFakeAuthManager()),
          ),
        );

        expect(fakeInjector.addLazySingletonCalls, 1);
        expect(fakeInjector.addCalls, 1);
        expect(fakeInjector.createdUseCases, isNotEmpty);
        expect(fakeInjector.createdBlocs, isNotEmpty);

        fakeInjector.reset();

        expect(fakeInjector.addLazySingletonCalls, 0);
        expect(fakeInjector.addCalls, 0);
        expect(fakeInjector.executedUseCaseFactories, 0);
        expect(fakeInjector.executedBlocFactories, 0);
        expect(fakeInjector.executedFactories, 0);
        expect(fakeInjector.useCaseFactories, 0);
        expect(fakeInjector.blocFactories, 0);
        expect(fakeInjector.lazySingletonCalls, 0);
        expect(fakeInjector.createdUseCases, isEmpty);
        expect(fakeInjector.createdBlocs, isEmpty);
        expect(fakeInjector.totalDependencies, 0);
        expect(fakeInjector.totalCalls, 0);
      });
    });

    group('edge cases', () {
      test('should handle empty factory functions', () {
        fakeInjector.addLazySingleton<ResetPasswordUseCase>(
          () => throw Exception('Empty'),
        );
        fakeInjector.add<RegisterWithEmailBloc>(() => throw Exception('Empty'));

        expect(fakeInjector.addLazySingletonCalls, 1);
        expect(fakeInjector.addCalls, 1);
        expect(fakeInjector.executedFactories, 2);
        expect(fakeInjector.createdUseCases, isEmpty);
        expect(fakeInjector.createdBlocs, isEmpty);
      });
    });

    group('getters', () {
      test(
        'totalDependencies should return sum of addLazySingletonCalls and addCalls',
        () {
          fakeInjector.addLazySingleton<ResetPasswordUseCase>(
            () => ResetPasswordUseCase(createFakeAuthManager()),
          );
          fakeInjector.addLazySingleton<CreateAccountUseCase>(
            () =>
                CreateAccountUseCase(createFakeAuthManager(), FakeClockImpl()),
          );
          fakeInjector.add<RegisterWithEmailBloc>(
            () => RegisterWithEmailBloc(
              checkEmailAvailabilityUseCase: CheckEmailAvailabilityUseCase(
                createFakeAuthManager(),
              ),
              sendOtpUseCase: SendOtpUseCase(createFakeAuthManager()),
            ),
          );

          expect(fakeInjector.totalDependencies, 3);
          expect(fakeInjector.addLazySingletonCalls + fakeInjector.addCalls, 3);
        },
      );

      test(
        'totalCalls should return sum of lazySingletonCalls and addCalls',
        () {
          fakeInjector.addLazySingleton<ResetPasswordUseCase>(
            () => ResetPasswordUseCase(createFakeAuthManager()),
          );
          fakeInjector.addLazySingleton<CreateAccountUseCase>(
            () =>
                CreateAccountUseCase(createFakeAuthManager(), FakeClockImpl()),
          );
          fakeInjector.add<RegisterWithEmailBloc>(
            () => RegisterWithEmailBloc(
              checkEmailAvailabilityUseCase: CheckEmailAvailabilityUseCase(
                createFakeAuthManager(),
              ),
              sendOtpUseCase: SendOtpUseCase(createFakeAuthManager()),
            ),
          );

          expect(fakeInjector.totalCalls, 3);
          expect(fakeInjector.lazySingletonCalls + fakeInjector.addCalls, 3);
        },
      );
    });

    group('type detection', () {
      test('should detect use cases by runtime type', () {
        fakeInjector.addLazySingleton<ResetPasswordUseCase>(
          () => ResetPasswordUseCase(createFakeAuthManager()),
        );

        expect(fakeInjector.createdUseCases, contains('ResetPasswordUseCase'));
        expect(fakeInjector.useCaseFactories, 1);
      });

      test('should detect blocs by runtime type', () {
        fakeInjector.add<RegisterWithEmailBloc>(
          () => RegisterWithEmailBloc(
            checkEmailAvailabilityUseCase: CheckEmailAvailabilityUseCase(
              createFakeAuthManager(),
            ),
            sendOtpUseCase: SendOtpUseCase(createFakeAuthManager()),
          ),
        );

        expect(fakeInjector.createdBlocs, contains('RegisterWithEmailBloc'));
        expect(fakeInjector.blocFactories, 1);
      });

      test('should handle factory string parsing for exceptions', () {
        fakeInjector.addLazySingleton<ResetPasswordUseCase>(
          () => throw Exception('ResetPasswordUseCase error'),
        );

        expect(fakeInjector.createdUseCases, isEmpty);
        expect(fakeInjector.useCaseFactories, 0);
      });

      test('should handle factory string parsing for bloc exceptions', () {
        fakeInjector.add<RegisterWithEmailBloc>(
          () => throw Exception('RegisterWithEmailBloc error'),
        );

        expect(fakeInjector.createdBlocs, isEmpty);
        expect(fakeInjector.blocFactories, 0);
      });
    });
  });
}

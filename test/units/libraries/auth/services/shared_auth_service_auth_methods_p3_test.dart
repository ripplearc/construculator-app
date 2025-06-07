import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/shared_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthNotifier authNotifier;
  late FakeAuthRepository authRepository;
  late SharedAuthService authService;

  setUp(() {
    authNotifier = FakeAuthNotifier();
    authRepository = FakeAuthRepository();

    authService = SharedAuthService(
      notifier: authNotifier,
      repository: authRepository,
    );
  });

  tearDown(() {
    authNotifier.dispose();
    authRepository.dispose();
  });

  group('Authentication Methods - Part 3', () {
    test(
      'resetPassword should return true when email is sent successfully',
      () async {
        final result = await authService.resetPassword('test@example.com');

        expect(result, true);
        expect(authRepository.resetPasswordCalls, contains('test@example.com'));
        expect(authRepository.resetPasswordCalls.length, 1);
      },
    );

    test(
      'resetPassword should return false when email fails to send',
      () async {
        authRepository.fakeAuthResponse(succeed: false);

        final result = await authService.resetPassword('fail@example.com');

        expect(result, false);
        expect(authRepository.resetPasswordCalls, contains('fail@example.com'));
        expect(authRepository.resetPasswordCalls.length, 1);
      },
    );

    test('resetPassword should handle network exceptions gracefully', () async {
      authRepository.shouldThrowOnResetPassword = true;
      authRepository.exceptionMessage = 'Network connection failed';

      final result = await authService.resetPassword('test@example.com');

      expect(result, isFalse);
      expect(result, isNot(isTrue));
      expect(authRepository.resetPasswordCalls, contains('test@example.com'));
    });

    test('isEmailRegistered should return true for registered email', () async {
      const testEmail = 'registered@example.com';

      final result = await authService.isEmailRegistered(testEmail);

      expect(result, true);
      expect(authRepository.emailCheckCalls, contains(testEmail));
      expect(authRepository.emailCheckCalls.length, 1);
    });

    test(
      'isEmailRegistered should return false for unregistered email',
      () async {
        final result = await authService.isEmailRegistered(
          'unknown@example.com',
        );

        expect(result, false);
        expect(authRepository.emailCheckCalls, contains('unknown@example.com'));
        expect(authRepository.emailCheckCalls.length, 1);
      },
    );

    test('isEmailRegistered should return false when check fails', () async {
      authRepository.fakeAuthResponse(succeed: false);

      final result = await authService.isEmailRegistered('fail@example.com');

      expect(result, false);
      expect(authRepository.emailCheckCalls, contains('fail@example.com'));
      expect(authRepository.emailCheckCalls.length, 1);
    });

    test(
      'isEmailRegistered should handle network exceptions gracefully',
      () async {
        authRepository.shouldThrowOnEmailCheck = true;
        authRepository.exceptionMessage = 'Network connection failed';

        final result = await authService.isEmailRegistered('test@example.com');

        expect(result, isFalse);
        expect(result, isNot(isTrue));
        expect(authRepository.emailCheckCalls, contains('test@example.com'));
      },
    );

    test('getCurrentUser should return null when not authenticated', () async {
      authRepository = FakeAuthRepository(startAuthenticated: false);
      authService = SharedAuthService(
        notifier: authNotifier,
        repository: authRepository
        );

      final userCredential = await authService.getCurrentUser();

      expect(userCredential, isNull);
      expect(authRepository.getCurrentUserCallCount, 1);
    });

    test(
      'getCurrentUser should return credentials when authenticated',
      () async {
        final repo = FakeAuthRepository(startAuthenticated: true);
        final notifier = FakeAuthNotifier();
        final authService = SharedAuthService(
          notifier: notifier,
          repository: repo
        );

        final credential = await authService.getCurrentUser();

        expect(credential, isNotNull);
        expect(credential?.email, isNotNull);
        expect(credential?.id, isNotNull);
        expect(repo.getCurrentUserCallCount, 2);
      },
    );

    test('user can retry login after a failed attempt', () async {
      authRepository.fakeAuthResponse(succeed: false);
      final firstAttempt = await authService.loginWithEmail(
        'test@example.com',
        'wrong',
      );
      expect(firstAttempt, false);

      authRepository.fakeAuthResponse(succeed: true);

      final secondAttempt = await authService.loginWithEmail(
        'test@example.com',
        'correct',
      );

      expect(secondAttempt, true);
      expect(
        authRepository.loginCalls,
        containsAll(['test@example.com:wrong', 'test@example.com:correct']),
      );
      expect(authRepository.loginCalls.length, 2);
    });
  });
} 
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

  group('Authentication Methods - Part 1', () {
    test('loginWithEmail should return true on successful login', () async {
      authRepository.reset();
      final result = await authService.loginWithEmail(
        'test@example.com',
        'password',
      );
      expect(result, true);
      expect(authRepository.loginCalls, contains('test@example.com:password'));
      expect(authRepository.loginCalls.length, 1);
      expect(authRepository.registerCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test('loginWithEmail should return false when login fails', () async {
      authRepository.fakeAuthResponse(succeed: false);
      final result = await authService.loginWithEmail(
        'fail@example.com',
        'password',
      );
      expect(result, false);
      expect(authRepository.loginCalls, contains('fail@example.com:password'));
      expect(authRepository.loginCalls.length, 1);
      expect(authRepository.registerCalls, isEmpty);
    });

    test('loginWithEmail should handle empty email', () async {
      authRepository.reset();
      final result = await authService.loginWithEmail('', 'password');
      expect(result, false);
      expect(
        authRepository.loginCalls,
        isEmpty,
      );
      expect(authRepository.registerCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test('loginWithEmail should handle empty password', () async {
      authRepository.reset();
      final result = await authService.loginWithEmail('test@example.com', '');
      expect(result, false);
      expect(
        authRepository.loginCalls,
        isEmpty,
      );
      expect(authRepository.registerCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test(
      'loginWithEmail should handle network exceptions gracefully',
      () async {
        authRepository.shouldThrowOnLogin = true;
        authRepository.exceptionMessage = 'Network connection failed';
        final result = await authService.loginWithEmail(
          'test@example.com',
          'password123',
        );
        expect(result, isFalse);
        expect(result, isNot(isTrue));
        expect(
          authRepository.loginCalls,
          contains('test@example.com:password123'),
        );
        expect(authRepository.registerCalls, isEmpty);
      },
    );

    test(
      'loginWithEmail should return false when repository returns success but null data',
      () async {
        authRepository.reset();
        authRepository.returnSuccessWithNullData = true;
        final result = await authService.loginWithEmail(
          'test@example.com',
          'password',
        );
        expect(
          result,
          false,
          reason: 'Should return false when data is null despite success',
        );
        expect(
          authRepository.loginCalls,
          contains('test@example.com:password'),
        );
        expect(authRepository.loginCalls.length, 1);
        expect(authRepository.registerCalls, isEmpty);
      },
    );

    test(
      'registerWithEmail should return true on successful registration',
      () async {
        authRepository.reset();
        final result = await authService.registerWithEmail(
          'test@example.com',
          'password',
        );
        expect(result, true);
        expect(
          authRepository.registerCalls,
          contains('test@example.com:password'),
        );
        expect(authRepository.registerCalls.length, 1);
        expect(authRepository.loginCalls, isEmpty);
        expect(authRepository.logoutCalls, isEmpty);
      },
    );

    test(
      'registerWithEmail should return false when registration fails',
      () async {
        authRepository.fakeAuthResponse(succeed: false);
        final result = await authService.registerWithEmail(
          'fail@example.com',
          'password',
        );
        expect(result, false);
        expect(
          authRepository.registerCalls,
          contains('fail@example.com:password'),
        );
        expect(authRepository.registerCalls.length, 1);
        expect(authRepository.loginCalls, isEmpty);
      },
    );

    test('registerWithEmail should handle empty email', () async {
      authRepository.reset();
      final result = await authService.registerWithEmail('', 'password');
      expect(result, false);
      expect(
        authRepository.registerCalls,
        isEmpty,
      );
      expect(authRepository.loginCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test('registerWithEmail should handle empty password', () async {
      authRepository.reset();
      final result = await authService.registerWithEmail(
        'test@example.com',
        '',
      );
      expect(result, false);
      expect(
        authRepository.registerCalls,
        isEmpty,
      );
      expect(authRepository.loginCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test(
      'registerWithEmail should handle network exceptions gracefully',
      () async {
        authRepository.shouldThrowOnRegister = true;
        authRepository.exceptionMessage = 'Network connection failed';
        final result = await authService.registerWithEmail(
          'test@example.com',
          'password123',
        );
        expect(result, isFalse);
        expect(result, isNot(isTrue));
        expect(
          authRepository.registerCalls,
          contains('test@example.com:password123'),
        );
        expect(authRepository.loginCalls, isEmpty);
      },
    );

    test(
      'registerWithEmail should return false when repository returns success but null data',
      () async {
        authRepository.reset();
        authRepository.returnSuccessWithNullData = true;
        final result = await authService.registerWithEmail(
          'test@example.com',
          'password',
        );
        expect(
          result,
          false
        );
        expect(
          authRepository.registerCalls,
          contains('test@example.com:password'),
        );
        expect(authRepository.registerCalls.length, 1);
        expect(authRepository.loginCalls, isEmpty);
      },
    );
    
    test('isAuthenticated should return true when user is authenticated', () {
      authRepository = FakeAuthRepository(startAuthenticated: true);
      authService = SharedAuthService(
        notifier: authNotifier,
        repository: authRepository,
      );
      final result = authService.isAuthenticated();
      expect(result, true);
    });

    test(
      'isAuthenticated should return false when user is not authenticated',
      () {
        final result = authService.isAuthenticated();
        expect(result, false);
      },
    );
  });
} 
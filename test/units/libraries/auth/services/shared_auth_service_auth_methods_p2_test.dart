import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/shared_auth_service.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';

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

  group('Authentication Methods - Part 2', () {
    test('getUserInfo should return user profile when it exists', () async {
      final testCredential = UserCredential(
        id: 'test-user-id',
        email: 'test@example.com',
        metadata: {},
        createdAt: DateTime.now(),
      );

      final testUser = User(
        id: 'test-user-id',
        credentialId: 'test-user-id',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        professionalRole: 'Developer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userStatus: UserProfileStatus.active,
        userPreferences: {},
      );

      authRepository.fakeUserProfile(testUser);

      authRepository.emitAuthStateChanged(AuthStatus.authenticated);
      authRepository.emitUserUpdated(testCredential);

      await Future.delayed(const Duration(milliseconds: 50));

      final userInfo = await authService.getUserInfo();

      expect(userInfo, isNotNull);
      expect(userInfo?.email, 'test@example.com');
      expect(userInfo?.firstName, 'Test');
      expect(userInfo?.lastName, 'User');
      expect(userInfo?.professionalRole, 'Developer');
      expect(userInfo?.userStatus, UserProfileStatus.active);
      expect(authRepository.getUserProfileCalls, contains('test-user-id'));
      expect(authRepository.getUserProfileCalls.length, 1);
    });

    test(
      'getUserInfo should return null when profile retrieval succeeds but returns null data',
      () async {

        final testCredential = UserCredential(
          id: 'test-id',
          email: 'test@example.com',
          metadata: {},
          createdAt: DateTime.now(),
        );

        authRepository.emitAuthStateChanged(AuthStatus.authenticated);
        authRepository.emitUserUpdated(testCredential);

        authRepository.returnSuccessWithNullUserProfile = true;

        final userInfo = await authService.getUserInfo();

        expect(
          userInfo,
          isNull,
          reason:
              'Should return null when profile data is null despite success',
        );
        expect(authRepository.getUserProfileCalls, contains('test-id'));
        expect(authRepository.getUserProfileCalls.length, 1);
      },
    );

    test(
      'getUserInfo should return null when no user is authenticated',
      () async {
        authRepository = FakeAuthRepository(startAuthenticated: false);
        authService = SharedAuthService(
          notifier: authNotifier,
          repository: authRepository,
        );

        final userInfo = await authService.getUserInfo();

        expect(userInfo, isNull);
      },
    );

    test('logout should work correctly', () async {
      await authService.logout();

      expect(authRepository.logoutCalls, isNotEmpty);
      expect(authRepository.logoutCalls.length, 1);
    });

    test('sendOtp should return true when OTP is sent successfully', () async {
      final result = await authService.sendOtp(
        'test@example.com',
        OtpReceiver.email,
      );

      expect(result, true);
      expect(
        authRepository.sendOtpCalls,
        contains('test@example.com:OtpReceiver.email'),
      );
      expect(authRepository.sendOtpCalls.length, 1);
      expect(authRepository.getSentOtp('test@example.com'), isNotNull);
    });

    test('sendOtp should return false when sending OTP fails', () async {
      authRepository.fakeAuthResponse(succeed: false);

      final result = await authService.sendOtp(
        'fail@example.com',
        OtpReceiver.email,
      );

      expect(result, false);
      expect(
        authRepository.sendOtpCalls,
        contains('fail@example.com:OtpReceiver.email'),
      );
      expect(authRepository.sendOtpCalls.length, 1);
    });

    test('sendOtp should handle network exceptions gracefully', () async {
      authRepository.shouldThrowOnSendOtp = true;
      authRepository.exceptionMessage = 'Network connection failed';

      final result = await authService.sendOtp(
        'test@example.com',
        OtpReceiver.email,
      );

      expect(result, isFalse);
      expect(result, isNot(isTrue));
      expect(
        authRepository.sendOtpCalls,
        contains('test@example.com:OtpReceiver.email'),
      );
    });

    test('verifyOtp should return true for valid OTP', () async {
      final email = 'test@example.com';
      await authService.sendOtp(email, OtpReceiver.email);
      final sentOtp = authRepository.getSentOtp(email)!;

      final result = await authService.verifyOtp(
        email,
        sentOtp,
        OtpReceiver.email,
      );

      expect(result, true);
      expect(
        authRepository.verifyOtpCalls,
        contains('$email:$sentOtp:OtpReceiver.email'),
      );
      expect(authRepository.verifyOtpCalls.length, 1);
    });

    test('verifyOtp should return false for invalid OTP', () async {
      final email = 'test@example.com';
      await authService.sendOtp(email, OtpReceiver.email);

      final result = await authService.verifyOtp(
        email,
        'invalid',
        OtpReceiver.email,
      );

      expect(result, false);
      expect(
        authRepository.verifyOtpCalls,
        contains('$email:invalid:OtpReceiver.email'),
      );
      expect(authRepository.verifyOtpCalls.length, 1);
    });

    test('verifyOtp should handle network exceptions gracefully', () async {
      authRepository.shouldThrowOnVerifyOtp = true;
      authRepository.exceptionMessage = 'Network connection failed';

      final result = await authService.verifyOtp(
        'test@example.com',
        '123456',
        OtpReceiver.email,
      );

      expect(result, isFalse);
      expect(result, isNot(isTrue));
      expect(
        authRepository.verifyOtpCalls,
        contains('test@example.com:123456:OtpReceiver.email'),
      );
    });
  });
} 
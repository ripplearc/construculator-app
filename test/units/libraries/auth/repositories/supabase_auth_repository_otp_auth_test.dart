import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/repositories/supabase_auth_repository.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late SupabaseAuthRepository authRepository;

  setUp(() {
    fakeSupabaseWrapper = FakeSupabaseWrapper();
    authRepository = SupabaseAuthRepository(supabaseWrapper: fakeSupabaseWrapper);
  });

  tearDown(() {
    // Ensure resources are cleaned up after each test.
    authRepository.dispose();
    fakeSupabaseWrapper.dispose();
    fakeSupabaseWrapper.reset();
  });

  group('One-Time Password (OTP) Authentication', () {
    test('should send OTP to user email address', () async {
      const userEmail = 'contractor@buildsite.com';

      final result = await authRepository.sendOtp(
        userEmail,
        OtpReceiver.email,
      );

      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);

      final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
        'signInWithOtp',
      );
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first['email'], equals(userEmail));
      expect(methodCalls.first['phone'], isNull);
      expect(methodCalls.first['shouldCreateUser'], isTrue);
    });

    test('should send OTP to user phone number', () async {
      const userPhone = '+1-555-123-4567';

      final result = await authRepository.sendOtp(
        userPhone,
        OtpReceiver.phone,
      );

      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);

      final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
        'signInWithOtp',
      );
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first['email'], isNull);
      expect(methodCalls.first['phone'], equals(userPhone));
      expect(methodCalls.first['shouldCreateUser'], isTrue);
    });

    test('should verify valid OTP code sent to email', () async {
      const userEmail = 'foreman@construction.com';
      const otpCode = '123456';

      final result = await authRepository.verifyOtp(
        userEmail,
        otpCode,
        OtpReceiver.email,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?.email, equals(userEmail));

      final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
        'verifyOTP',
      );
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first['email'], equals(userEmail));
      expect(methodCalls.first['phone'], isNull);
      expect(methodCalls.first['token'], equals(otpCode));
      expect(methodCalls.first['type'], equals(supabase.OtpType.email));
    });

    test('should verify valid OTP code sent to phone', () async {
      const userPhone = '+1-555-987-6543';
      const otpCode = '654321';

      final result = await authRepository.verifyOtp(
        userPhone,
        otpCode,
        OtpReceiver.phone,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);

      final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
        'verifyOTP',
      );
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first['email'], isNull);
      expect(methodCalls.first['phone'], equals(userPhone));
      expect(methodCalls.first['token'], equals(otpCode));
      expect(methodCalls.first['type'], equals(supabase.OtpType.sms));
    });

    test('should handle invalid OTP verification', () async {
      fakeSupabaseWrapper.shouldReturnNullUser = true;

      final result = await authRepository.verifyOtp(
        'user@example.com',
        '000000',
        OtpReceiver.email,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.invalidCredentials));
      expect(result.errorMessage, contains('Invalid verification code'));
    });
  });
} 
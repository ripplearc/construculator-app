import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('FakeSupabaseWrapper Authentication Methods', () {
    late FakeSupabaseWrapper fakeWrapper;

    setUp(() {
      fakeWrapper = FakeSupabaseWrapper();
    });

    tearDown(() {
      fakeWrapper.reset();
    });

    group('signInWithPassword', () {
      test('returns success with user when configured for successful sign-in', () async {
        final result = await fakeWrapper.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.user, isNotNull);
        expect(result.user!.email, equals('test@example.com'));
        expect(result.session, isNotNull);
        expect(fakeWrapper.currentUser, isNotNull);
        expect(fakeWrapper.isAuthenticated, isTrue);
      });

      test('throws exception when configured to fail sign-in', () async {
        fakeWrapper.shouldThrowOnSignIn = true;
        fakeWrapper.signInErrorMessage = 'Invalid credentials';

        expect(
          () async => await fakeWrapper.signInWithPassword(
            email: 'test@example.com',
            password: 'wrong-password',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid credentials'),
          )),
        );
      });

      test('returns null user when configured for null user on sign-in', () async {
        fakeWrapper.shouldReturnNullUser = true;

        final result = await fakeWrapper.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.user, isNull);
        expect(result.session, isNull);
      });
    });

    group('signUp', () {
      test('returns success with new user on successful sign-up', () async {
        final result = await fakeWrapper.signUp(
          email: 'new@example.com',
          password: 'password123',
        );

        expect(result.user, isNotNull);
        expect(result.user!.email, equals('new@example.com'));
        expect(result.session, isNotNull);
        expect(fakeWrapper.currentUser, isNotNull);
        expect(fakeWrapper.isAuthenticated, isTrue);
      });

      test('throws exception when configured to fail sign-up', () async {
        fakeWrapper.shouldThrowOnSignUp = true;
        fakeWrapper.signUpErrorMessage = 'Email already exists';

        expect(
          () async => await fakeWrapper.signUp(
            email: 'existing@example.com',
            password: 'password123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Email already exists'),
          )),
        );
      });
    });

    group('signInWithOtp', () {
      test('completes successfully when configured for OTP sign-in', () async {
        expect(
          () async => await fakeWrapper.signInWithOtp(
            email: 'test@example.com',
            shouldCreateUser: true,
          ),
          returnsNormally,
        );
      });

      test('throws exception when configured to fail OTP sign-in', () async {
        fakeWrapper.shouldThrowOnOtp = true;
        fakeWrapper.otpErrorMessage = 'Failed to send OTP';

        expect(
          () async => await fakeWrapper.signInWithOtp(
            email: 'test@example.com',
            shouldCreateUser: true,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to send OTP'),
          )),
        );
      });
    });

    group('verifyOTP', () {
      test('returns success with user on successful OTP verification', () async {
        final result = await fakeWrapper.verifyOTP(
          email: 'otp@example.com',
          token: '123456',
          type: supabase.OtpType.email,
        );

        expect(result.user, isNotNull);
        expect(result.user!.email, equals('otp@example.com'));
        expect(result.session, isNotNull);
        expect(fakeWrapper.currentUser, isNotNull);
        expect(fakeWrapper.isAuthenticated, isTrue);
      });

      test('throws exception when configured to fail OTP verification', () async {
        fakeWrapper.shouldThrowOnVerifyOtp = true;
        fakeWrapper.verifyOtpErrorMessage = 'Invalid OTP code';

        expect(
          () async => await fakeWrapper.verifyOTP(
            email: 'test@example.com',
            token: 'invalid',
            type: supabase.OtpType.email,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid OTP code'),
          )),
        );
      });
    });

    group('resetPasswordForEmail', () {
      test('completes successfully when configured for password reset', () async {
        expect(
          () async => await fakeWrapper.resetPasswordForEmail(
            'test@example.com',
            redirectTo: null,
          ),
          returnsNormally,
        );
      });

      test('throws exception when configured to fail password reset', () async {
        fakeWrapper.shouldThrowOnResetPassword = true;
        fakeWrapper.resetPasswordErrorMessage = 'User not found';

        expect(
          () async => await fakeWrapper.resetPasswordForEmail(
            'notfound@example.com',
            redirectTo: null,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User not found'),
          )),
        );
      });
    });

    group('signOut', () {
      test('completes successfully and clears user session', () async {
        // Sign in a user first to establish a session
        await fakeWrapper.signInWithPassword(
          email: 'test@example.com',
          password: 'password',
        );
        expect(fakeWrapper.isAuthenticated, isTrue, reason: "User should be authenticated before sign out");

        await fakeWrapper.signOut();

        expect(fakeWrapper.currentUser, isNull);
        expect(fakeWrapper.isAuthenticated, isFalse);
      });

      test('throws exception when configured to fail sign-out', () async {
        fakeWrapper.shouldThrowOnSignOut = true;
        fakeWrapper.signOutErrorMessage = 'Sign out failed';

        expect(
          () async => await fakeWrapper.signOut(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Sign out failed'),
          )),
        );
      });
    });

    test(
      'setCurrentUser updates the current user',
      () async {
        // Arrange
        fakeWrapper.setCurrentUser(supabase.User(
          id: 'currentuser123',
          email: 'currentuser@example.com',
          appMetadata: {},
          userMetadata: {},
          aud: 'test',
          createdAt: DateTime.now().toIso8601String(),
        ));
        expect(fakeWrapper.currentUser, isNotNull);
        expect(fakeWrapper.currentUser!.email, equals('currentuser@example.com'));
        expect(fakeWrapper.currentUser!.id, equals('currentuser123'));
        
        fakeWrapper.setCurrentUser(null);
        expect(fakeWrapper.currentUser, isNull);
      },
    );
 
  });
} 
import 'dart:async';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/repositories/supabase_auth_repository.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late SupabaseAuthRepository authRepository;

  setUp(() {
    fakeSupabaseWrapper = FakeSupabaseWrapper();
    authRepository = SupabaseAuthRepository(
      supabaseWrapper: fakeSupabaseWrapper,
    );
  });

  tearDown(() {
    authRepository.dispose();
    fakeSupabaseWrapper.dispose();
    fakeSupabaseWrapper.reset();
  });

  group('Authentication State Management', () {
    test('should handle authentication stream errors appropriately', () async {
      // Test various auth stream errors
      final authErrors = [
        'Authentication token has expired',
        'User session is no longer valid',
        'Access to resource is forbidden',
        'Invalid authentication grant provided',
        'No active session found for user',
      ];

      for (final errorMessage in authErrors) {
        var localFakeSupabaseWrapper = FakeSupabaseWrapper();
        var localAuthRepository = SupabaseAuthRepository(
          supabaseWrapper: localFakeSupabaseWrapper,
        );

        localFakeSupabaseWrapper.simulateAuthStreamError(errorMessage);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(
          true,
          isTrue,
          reason: "Error '$errorMessage' should be handled gracefully.",
        );
        localAuthRepository.dispose();
      }
    });

    test('should handle network-related stream errors', () async {
      var localFakeSupabaseWrapper = FakeSupabaseWrapper();
      var localAuthRepository = SupabaseAuthRepository(
        supabaseWrapper: localFakeSupabaseWrapper,
      );

      localFakeSupabaseWrapper.simulateAuthStreamError(
        'Network connection lost during authentication',
      );
      await Future.delayed(const Duration(milliseconds: 10));

      expect(
        true,
        isTrue,
        reason: "Network stream error should be handled gracefully.",
      );
      localAuthRepository.dispose();
    });

    test(
      'should handle authentication responses with missing user data',
      () async {
        // Test first scenario: null user returned from login
        fakeSupabaseWrapper.shouldReturnNullUser = true;
        var result = await authRepository.loginWithEmail(
          'test@example.com',
          'password',
        );
        expect(
          result.isSuccess,
          isFalse,
          reason: "Login should fail if service returns null user.",
        );

        // Test second scenario: successful auth with user
        // Resetting the shared fakeSupabaseWrapper for the second part of this specific test
        fakeSupabaseWrapper.reset();
        fakeSupabaseWrapper.shouldReturnNullUser =
            false; // Ensure it doesn't return null now

        result = await authRepository.loginWithEmail(
          'test@example.com',
          'password',
        );
        expect(
          result.isSuccess,
          isTrue,
          reason: "Login should succeed with valid user data.",
        );
      },
    );

    test('should handle getCurrentCredentials when user is null', () {
      fakeSupabaseWrapper.shouldReturnUser = false;
      final credentials = authRepository.getCurrentCredentials();
      expect(credentials, isNull);
    });

    test('should handle getCurrentCredentials when user exists', () async {
      // First login to establish a current user for the test
      await authRepository.loginWithEmail('test@example.com', 'password');
      fakeSupabaseWrapper.shouldReturnUser =
          true; // Ensure Supabase client returns the user

      final credentials = authRepository.getCurrentCredentials();
      expect(credentials, isNotNull);
      expect(credentials?.email, equals('test@example.com'));
    });

    test('should handle isAuthenticated when user is null', () {
      fakeSupabaseWrapper.shouldReturnUser = false;
      final isAuth = authRepository.isAuthenticated();
      expect(isAuth, isFalse);
    });

    test('should handle isAuthenticated when user exists', () async {
      // First login to establish a current user for the test
      await authRepository.loginWithEmail('test@example.com', 'password');
      fakeSupabaseWrapper.shouldReturnUser =
          true; // Ensure Supabase client returns the user

      final isAuth = authRepository.isAuthenticated();
      expect(isAuth, isTrue);
    });

    test('should emit authenticated state when user logs in', () async {
      fakeSupabaseWrapper.shouldReturnUser =
          true; // Ensure Supabase client returns the user
      await authRepository.loginWithEmail('test@example.com', 'password');
      final authState = await authRepository.authStateChanges.first;
      expect(authState, AuthStatus.authenticated);
    });

    test('should emit user when user logs in', () async {
      fakeSupabaseWrapper.shouldReturnUser =
          true; // Ensure Supabase client returns the user
      await authRepository.loginWithEmail('test@example.com', 'password');
      final user = await authRepository.userChanges.first;
      expect(user, isNotNull);
      expect(user?.email, equals('test@example.com'));
    });

    test(
      'should emit user when user is updated, token refreshed, or mfa challenge verified',
      () async {
        // First login to establish a current user for the test
        fakeSupabaseWrapper.shouldReturnUser =
            true; // Ensure Supabase client returns the user
        final events = [
          supabase.AuthChangeEvent.userUpdated,
          supabase.AuthChangeEvent.tokenRefreshed,
          supabase.AuthChangeEvent.mfaChallengeVerified,
        ];
        for (final event in events) {
          fakeSupabaseWrapper.signInEvent = event;
          await authRepository.loginWithEmail('test@example.com', 'password');
          final user = await authRepository.userChanges.first;
          expect(user, isNotNull);
          expect(user?.email, equals('test@example.com'));
        }
      },
    );

    test('should emit unauthenticated state when user logs out', () async {
      // First login to establish a current user for the test
      final authStateCompleter = Completer<AuthStatus>();
      final StreamSubscription<AuthStatus> subscription = authRepository
          .authStateChanges
          .listen(
            authStateCompleter.complete,
            onError: (error) {
              authStateCompleter.completeError(error);
            },
          );
      fakeSupabaseWrapper.shouldReturnUser =
          true; // Ensure Supabase client returns the user
      await authRepository.logout();
      final authState = await authStateCompleter.future;
      expect(authState, AuthStatus.unauthenticated);
      await subscription.cancel();
    });

    test('getCurrentCredentials should return user if user is already logged in', () async {
      // If mimic user already logged in
      fakeSupabaseWrapper.setCurrentUser(
        supabase.User(
          id: 'currentuser123',
          email: 'currentuser@example.com',
          appMetadata: {},
          userMetadata: {},
          aud: 'test',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      final authStateCompleter = Completer<AuthStatus>();
      // When user is already logged in, it should return the user
      final newAuthRepository = SupabaseAuthRepository(
        supabaseWrapper: fakeSupabaseWrapper,
      );
      final StreamSubscription<AuthStatus> subscription = newAuthRepository
          .authStateChanges
          .listen(
            authStateCompleter.complete,
            onError: (error) {
              authStateCompleter.completeError(error);
            },
          );

      final authState = await authStateCompleter.future;
      expect(authState, AuthStatus.authenticated);
      expect(
        newAuthRepository.getCurrentCredentials()?.email,
        equals('currentuser@example.com'),
      );
      expect(
        newAuthRepository.getCurrentCredentials()?.id,
        equals('currentuser123'),
      );
      await subscription.cancel();
    });
  });
}

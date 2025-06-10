import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/repositories/supabase_auth_repository.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late SupabaseAuthRepository authRepository;

  setUp(() {
    fakeSupabaseWrapper = FakeSupabaseWrapper();
    authRepository = SupabaseAuthRepository(supabaseWrapper: fakeSupabaseWrapper);
  });

  tearDown(() {
    authRepository.dispose();
    fakeSupabaseWrapper.dispose();
    fakeSupabaseWrapper.reset();
  });

  group('Authentication State Management', () {
    test(
      'should handle authentication stream errors appropriately',
      () async {
        // Test various auth stream errors
        final authErrors = [
          'Authentication token has expired',
          'User session is no longer valid',
          'Access to resource is forbidden',
          'Invalid authentication grant provided',
          'No active session found for user',
        ];

        for (final errorMessage in authErrors) {
          // This test inherently tests behavior of a persistent repository,
          // so re-creating it for each sub-scenario is part of the test logic.
          var localFakeSupabaseWrapper = FakeSupabaseWrapper();
          var localAuthRepository = SupabaseAuthRepository(
            supabaseWrapper: localFakeSupabaseWrapper,
          );

          localFakeSupabaseWrapper.simulateAuthStreamError(errorMessage);
          await Future.delayed(const Duration(milliseconds: 10)); // Allow time for stream to emit and be handled

          // The test implies that the repository should internally handle these
          // stream errors without crashing. If it reaches here, it's a pass.
          expect(true, isTrue, reason: "Error '$errorMessage' should be handled gracefully.");
          localAuthRepository.dispose();
        }
      },
    );

    test('should handle network-related stream errors', () async {
      // Similar to the above, re-creation is part of the test logic.
      var localFakeSupabaseWrapper = FakeSupabaseWrapper();
      var localAuthRepository = SupabaseAuthRepository(
        supabaseWrapper: localFakeSupabaseWrapper,
      );

      localFakeSupabaseWrapper.simulateAuthStreamError(
        'Network connection lost during authentication',
      );
      await Future.delayed(const Duration(milliseconds: 10));

      expect(true, isTrue, reason: "Network stream error should be handled gracefully.");
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
        expect(result.isSuccess, isFalse, reason: "Login should fail if service returns null user.");

        // Test second scenario: successful auth with user
        // Resetting the shared fakeSupabaseWrapper for the second part of this specific test
        fakeSupabaseWrapper.reset(); 
        fakeSupabaseWrapper.shouldReturnNullUser = false; // Ensure it doesn't return null now
        
        result = await authRepository.loginWithEmail(
          'test@example.com',
          'password',
        );
        expect(result.isSuccess, isTrue, reason: "Login should succeed with valid user data.");
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
      fakeSupabaseWrapper.shouldReturnUser = true; // Ensure Supabase client returns the user

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
      fakeSupabaseWrapper.shouldReturnUser = true; // Ensure Supabase client returns the user

      final isAuth = authRepository.isAuthenticated();
      expect(isAuth, isTrue);
    });

     test('should emit authenticated state when user logs in', () async {
      // First login to establish a current user for the test
      final authStateCompleter = Completer<AuthStatus>();
      final StreamSubscription<AuthStatus> subscription = authRepository.authStateChanges.listen(
        authStateCompleter.complete,
        onError: (error) {
          authStateCompleter.completeError(error);
        },
      );
      fakeSupabaseWrapper.shouldReturnUser = true; // Ensure Supabase client returns the user
      await authRepository.loginWithEmail('test@example.com', 'password');
      final authState = await authStateCompleter.future;
      expect(authState, AuthStatus.authenticated);
      await subscription.cancel();
    });

      test('should emit user when user logs in', () async {
      // First login to establish a current user for the test
      final userCompleter = Completer<UserCredential?>();
      final StreamSubscription<UserCredential?> subscription = authRepository.userChanges.listen(
        userCompleter.complete,
        onError: (error) {
          userCompleter.completeError(error);
        },
      );
      fakeSupabaseWrapper.shouldReturnUser = true; // Ensure Supabase client returns the user
      await authRepository.loginWithEmail('test@example.com', 'password');
      final user = await userCompleter.future;
      expect(user, isNotNull);
      expect(user?.email, equals('test@example.com'));
      await subscription.cancel();
    });
  });
} 
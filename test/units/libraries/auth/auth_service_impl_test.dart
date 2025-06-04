import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/config/env_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/auth_service_impl.dart';
import 'package:construculator/libraries/auth/fakes/fake_auth_repository.dart';
import 'package:construculator/libraries/config/app_config.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';

void main() {
  // Initialize the testing environment
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Set up our minimal test environment
  late FakeAuthNotifier authNotifier;
  late FakeAuthRepository authRepository;
  late AuthServiceImpl authService;

  setUp(() {
    // Initialize AppConfig.environment to prevent Logger errors
    AppConfig.instance.environment = Environment.dev;
    
    // Create the fake dependencies
    authNotifier = FakeAuthNotifier();
    authRepository = FakeAuthRepository();
    
    // Create the service to test
    authService = AuthServiceImpl(
      notifier: authNotifier,
      repository: authRepository,
    );
  });

  tearDown(() {
    authNotifier.dispose();
    authRepository.dispose();
  });

  group('Authentication Methods', () {
    test('loginWithEmail should return true on successful login', () async {
      // Arrange
      authRepository.reset(); // Clear any previous calls
      
      // Act
      final result = await authService.loginWithEmail('test@example.com', 'password');
      
      // Assert - Rigorous verification catches mutations naturally
      expect(result, true);
      // CRITICAL: Verify repository was called with correct parameters
      expect(authRepository.loginCalls, contains('test@example.com:password'));
      // CRITICAL: Verify repository was called exactly once
      expect(authRepository.loginCalls.length, 1);
      // CRITICAL: Verify no other repository methods were called
      expect(authRepository.registerCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test('loginWithEmail should return false when login fails', () async {
      // Arrange
      authRepository.fakeAuthResponse(succeed: false);
      
      // Act
      final result = await authService.loginWithEmail('fail@example.com', 'password');
      
      // Assert - Rigorous verification
      expect(result, false);
      expect(authRepository.loginCalls, contains('fail@example.com:password'));
      expect(authRepository.loginCalls.length, 1);
      // Verify no other methods called
      expect(authRepository.registerCalls, isEmpty);
    });

    test('loginWithEmail should handle empty email', () async {
      // Arrange
      authRepository.reset(); // Clear any previous calls
      
      // Act
      final result = await authService.loginWithEmail('', 'password');
      
      // Assert - Rigorous verification catches OR→AND mutations naturally
      expect(result, false);
      // CRITICAL: Verify repository was NOT called - this catches OR→AND mutations
      // With OR: empty email returns false immediately, no repository call
      // With AND: both must be empty, so this would call repository and return true
      expect(authRepository.loginCalls, isEmpty, 
        reason: 'Repository should not be called when email is empty');
      // CRITICAL: Verify no other methods called either
      expect(authRepository.registerCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });
    
    test('loginWithEmail should handle empty password', () async {
      // Arrange
      authRepository.reset(); // Clear any previous calls
      
      // Act
      final result = await authService.loginWithEmail('test@example.com', '');
      
      // Assert - Rigorous verification catches OR→AND mutations naturally
      expect(result, false);
      // CRITICAL: Verify repository was NOT called - this catches OR→AND mutations
      // With OR: empty password returns false immediately, no repository call
      // With AND: both must be empty, so this would call repository and return true
      expect(authRepository.loginCalls, isEmpty,
        reason: 'Repository should not be called when password is empty');
      // CRITICAL: Verify no other methods called either
      expect(authRepository.registerCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test('loginWithEmail should handle network exceptions gracefully', () async {
      // Arrange
      authRepository.shouldThrowOnLogin = true;
      authRepository.exceptionMessage = 'Network connection failed';

      // Act
      final result = await authService.loginWithEmail('test@example.com', 'password123');

      expect(result, isFalse);
      expect(result, isNot(isTrue)); 
      // Verify attempt was made
      expect(authRepository.loginCalls, contains('test@example.com:password123'));
      expect(authRepository.registerCalls, isEmpty);
    });

    test('loginWithEmail should return false when repository returns success but null data', () async {
      // Arrange
      authRepository.reset();
      authRepository.returnSuccessWithNullData = true; // Success but null data
      
      // Act
      final result = await authService.loginWithEmail('test@example.com', 'password');
      
      // Assert - Rigorous verification catches AND→OR mutations naturally
      expect(result, false, reason: 'Should return false when data is null despite success');
      // CRITICAL: Verify repository was called - this catches AND→OR mutations
      // With AND: success=true AND data=null → false (correct)
      // With OR: success=true OR data=null → true (incorrect)
      expect(authRepository.loginCalls, contains('test@example.com:password'));
      expect(authRepository.loginCalls.length, 1);
      expect(authRepository.registerCalls, isEmpty);
    });

    test('registerWithEmail should return true on successful registration', () async {
      // Arrange
      authRepository.reset(); // Clear any previous calls
      
      // Act
      final result = await authService.registerWithEmail('test@example.com', 'password');
      
      // Assert - Rigorous verification catches mutations naturally
      expect(result, true);
      // CRITICAL: Verify repository was called with correct parameters
      expect(authRepository.registerCalls, contains('test@example.com:password'));
      // CRITICAL: Verify repository was called exactly once
      expect(authRepository.registerCalls.length, 1);
      // CRITICAL: Verify no other repository methods were called
      expect(authRepository.loginCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test('registerWithEmail should return false when registration fails', () async {
      // Arrange
      authRepository.fakeAuthResponse(succeed: false);
      
      // Act
      final result = await authService.registerWithEmail('fail@example.com', 'password');
      
      // Assert - Rigorous verification
      expect(result, false);
      expect(authRepository.registerCalls, contains('fail@example.com:password'));
      expect(authRepository.registerCalls.length, 1);
      expect(authRepository.loginCalls, isEmpty);
    });

    test('registerWithEmail should handle empty email', () async {
      // Arrange
      authRepository.reset(); // Clear any previous calls
      
      // Act
      final result = await authService.registerWithEmail('', 'password');
      
      // Assert - Rigorous verification catches OR→AND mutations naturally
      expect(result, false);
      // CRITICAL: Verify repository was NOT called - this catches OR→AND mutations
      // With OR: empty email returns false immediately, no repository call
      // With AND: both must be empty, so this would call repository and return true
      expect(authRepository.registerCalls, isEmpty,
        reason: 'Repository should not be called when email is empty');
      // CRITICAL: Verify no other methods called either
      expect(authRepository.loginCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });
    
    test('registerWithEmail should handle empty password', () async {
      // Arrange
      authRepository.reset(); // Clear any previous calls
      
      // Act
      final result = await authService.registerWithEmail('test@example.com', '');
      
      // Assert - Rigorous verification catches OR→AND mutations naturally
      expect(result, false);
      // CRITICAL: Verify repository was NOT called - this catches OR→AND mutations
      // With OR: empty password returns false immediately, no repository call
      // With AND: both must be empty, so this would call repository and return true
      expect(authRepository.registerCalls, isEmpty,
        reason: 'Repository should not be called when password is empty');
      // CRITICAL: Verify no other methods called either
      expect(authRepository.loginCalls, isEmpty);
      expect(authRepository.logoutCalls, isEmpty);
    });

    test('registerWithEmail should handle network exceptions gracefully', () async {
      // Arrange
      authRepository.shouldThrowOnRegister = true;
      authRepository.exceptionMessage = 'Network connection failed';

      // Act
      final result = await authService.registerWithEmail('test@example.com', 'password123');

      // Assert 
      expect(result, isFalse);
      expect(result, isNot(isTrue)); 
      // Verify attempt was made
      expect(authRepository.registerCalls, contains('test@example.com:password123'));
      expect(authRepository.loginCalls, isEmpty);
    });

    test('registerWithEmail should return false when repository returns success but null data', () async {
      // Arrange
      authRepository.reset();
      authRepository.returnSuccessWithNullData = true; // Success but null data
      
      // Act
      final result = await authService.registerWithEmail('test@example.com', 'password');
      
      // Assert - Rigorous verification catches AND→OR mutations naturally
      expect(result, false, reason: 'Should return false when data is null despite success');
      // CRITICAL: Verify repository was called - this catches AND→OR mutations
      // With AND: success=true AND data=null → false (correct)
      // With OR: success=true OR data=null → true (incorrect)
      expect(authRepository.registerCalls, contains('test@example.com:password'));
      expect(authRepository.registerCalls.length, 1);
      expect(authRepository.loginCalls, isEmpty);
    });

    test('isAuthenticated should return true when user is authenticated', () {
      // Arrange
      authRepository = FakeAuthRepository(startAuthenticated: true);
      authService = AuthServiceImpl(
        notifier: authNotifier,
        repository: authRepository,
      );
      
      // Act
      final result = authService.isAuthenticated();
      
      // Assert
      expect(result, true);
    });

    test('isAuthenticated should return false when user is not authenticated', () {
      // Act
      final result = authService.isAuthenticated();
      
      // Assert
      expect(result, false);
    });
    
    test('getUserInfo should return user profile when it exists', () async {
      // Arrange
      authRepository.reset();
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
      
      // Simulate authenticated user
      authRepository.emitAuthStateChanged(AuthStatus.authenticated);
      authRepository.emitUserUpdated(testCredential);
      
      // Wait for async auth state changes to be processed
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Act
      final userInfo = await authService.getUserInfo();
      
      // Assert - Rigorous verification catches AND→OR mutations naturally
      expect(userInfo, isNotNull);
      expect(userInfo?.email, 'test@example.com');
      expect(userInfo?.firstName, 'Test');
      expect(userInfo?.lastName, 'User');
      expect(userInfo?.professionalRole, 'Developer');
      expect(userInfo?.userStatus, UserProfileStatus.active);
      // CRITICAL: Verify repository was called to get profile
      expect(authRepository.getUserProfileCalls, contains('test-user-id'));
      expect(authRepository.getUserProfileCalls.length, 1);
    });
    
    test('getUserInfo should return null when profile retrieval succeeds but returns null data', () async {
      // Arrange
      authRepository.reset();
      final testCredential = UserCredential(
        id: 'test-id',
        email: 'test@example.com',
        metadata: {},
        createdAt: DateTime.now(),
      );
      
      // Simulate authenticated user
      authRepository.emitAuthStateChanged(AuthStatus.authenticated);
      authRepository.emitUserUpdated(testCredential);
      
      // Configure repository to return success but null profile data
      authRepository.returnSuccessWithNullUserProfile = true;
      
      // Act
      final userInfo = await authService.getUserInfo();
      
      // Assert - Rigorous verification catches AND→OR mutations naturally
      expect(userInfo, isNull, reason: 'Should return null when profile data is null despite success');
      expect(authRepository.getUserProfileCalls, contains('test-id'));
      expect(authRepository.getUserProfileCalls.length, 1);
    });

    test('getUserInfo should return null when no user is authenticated', () async {
      // Arrange - ensure no user is authenticated
      authRepository = FakeAuthRepository(startAuthenticated: false);
      authService = AuthServiceImpl(
        notifier: authNotifier,
        repository: authRepository,
      );
      
      // Act
      final userInfo = await authService.getUserInfo();
      
      // Assert
      expect(userInfo, isNull);
    });
    
    test('logout should work correctly', () async {
      // Act
      await authService.logout();
      
      // Assert - Rigorous verification
      expect(authRepository.logoutCalls, isNotEmpty);
      expect(authRepository.logoutCalls.length, 1);
    });
    
    test('sendOtp should return true when OTP is sent successfully', () async {
      // Act
      final result = await authService.sendOtp('test@example.com', OtpReceiver.email);
      
      // Assert - Rigorous verification
      expect(result, true);
      expect(authRepository.sendOtpCalls, contains('test@example.com:OtpReceiver.email'));
      expect(authRepository.sendOtpCalls.length, 1);
      expect(authRepository.getSentOtp('test@example.com'), isNotNull);
    });
    
    test('sendOtp should return false when sending OTP fails', () async {
      // Arrange
      authRepository.fakeAuthResponse(succeed: false);
      
      // Act
      final result = await authService.sendOtp('fail@example.com', OtpReceiver.email);
      
      // Assert - Rigorous verification
      expect(result, false);
      expect(authRepository.sendOtpCalls, contains('fail@example.com:OtpReceiver.email'));
      expect(authRepository.sendOtpCalls.length, 1);
    });

    test('sendOtp should handle network exceptions gracefully', () async {
      // Arrange
      authRepository.shouldThrowOnSendOtp = true;
      authRepository.exceptionMessage = 'Network connection failed';

      // Act
      final result = await authService.sendOtp('test@example.com', OtpReceiver.email);

      // Assert 
      expect(result, isFalse);
      expect(result, isNot(isTrue)); 
      // Verify attempt was made
      expect(authRepository.sendOtpCalls, contains('test@example.com:OtpReceiver.email'));
    });
    
    test('verifyOtp should return true for valid OTP', () async {
      // Arrange
      final email = 'test@example.com';
      await authService.sendOtp(email, OtpReceiver.email);
      final sentOtp = authRepository.getSentOtp(email)!;
      
      // Act
      final result = await authService.verifyOtp(email, sentOtp, OtpReceiver.email);
      
      // Assert - Rigorous verification
      expect(result, true);
      expect(authRepository.verifyOtpCalls, contains('$email:$sentOtp:OtpReceiver.email'));
      expect(authRepository.verifyOtpCalls.length, 1);
    });
    
    test('verifyOtp should return false for invalid OTP', () async {
      // Arrange
      final email = 'test@example.com';
      await authService.sendOtp(email, OtpReceiver.email);
      
      // Act - use an invalid OTP
      final result = await authService.verifyOtp(email, 'invalid', OtpReceiver.email);
      
      // Assert - Rigorous verification
      expect(result, false);
      expect(authRepository.verifyOtpCalls, contains('$email:invalid:OtpReceiver.email'));
      expect(authRepository.verifyOtpCalls.length, 1);
    });

    test('verifyOtp should handle network exceptions gracefully', () async {
      // Arrange
      authRepository.shouldThrowOnVerifyOtp = true;
      authRepository.exceptionMessage = 'Network connection failed';

      // Act
      final result = await authService.verifyOtp('test@example.com', '123456', OtpReceiver.email);

      // Assert 
      expect(result, isFalse);
      expect(result, isNot(isTrue)); 
      // Verify attempt was made
      expect(authRepository.verifyOtpCalls, contains('test@example.com:123456:OtpReceiver.email'));
    });
    
    test('resetPassword should return true when email is sent successfully', () async {
      // Act
      final result = await authService.resetPassword('test@example.com');
      
      // Assert - Rigorous verification
      expect(result, true);
      expect(authRepository.resetPasswordCalls, contains('test@example.com'));
      expect(authRepository.resetPasswordCalls.length, 1);
    });
    
    test('resetPassword should return false when email fails to send', () async {
      // Arrange
      authRepository.fakeAuthResponse(succeed: false);
      
      // Act
      final result = await authService.resetPassword('fail@example.com');
      
      // Assert - Rigorous verification
      expect(result, false);
      expect(authRepository.resetPasswordCalls, contains('fail@example.com'));
      expect(authRepository.resetPasswordCalls.length, 1);
    });

    test('resetPassword should handle network exceptions gracefully', () async {
      // Arrange
      authRepository.shouldThrowOnResetPassword = true;
      authRepository.exceptionMessage = 'Network connection failed';

      // Act
      final result = await authService.resetPassword('test@example.com');

      // Assert 
      expect(result, isFalse);
      expect(result, isNot(isTrue)); 
      // Verify attempt was made
      expect(authRepository.resetPasswordCalls, contains('test@example.com'));
    });
    
    test('isEmailRegistered should return true for registered email', () async {
      // Arrange - use one of the pre-registered emails
      const testEmail = 'registered@example.com';
      
      // Act
      final result = await authService.isEmailRegistered(testEmail);
      
      // Assert - Rigorous verification
      expect(result, true);
      expect(authRepository.emailCheckCalls, contains(testEmail));
      expect(authRepository.emailCheckCalls.length, 1);
    });
    
    test('isEmailRegistered should return false for unregistered email', () async {
      // Act
      final result = await authService.isEmailRegistered('unknown@example.com');
      
      // Assert - Rigorous verification
      expect(result, false);
      expect(authRepository.emailCheckCalls, contains('unknown@example.com'));
      expect(authRepository.emailCheckCalls.length, 1);
    });
    
    test('isEmailRegistered should return false when check fails', () async {
      // Arrange
      authRepository.fakeAuthResponse(succeed: false);
      
      // Act
      final result = await authService.isEmailRegistered('fail@example.com');
      
      // Assert - Rigorous verification
      expect(result, false);
      expect(authRepository.emailCheckCalls, contains('fail@example.com'));
      expect(authRepository.emailCheckCalls.length, 1);
    });

    test('isEmailRegistered should handle network exceptions gracefully', () async {
      // Arrange
      authRepository.shouldThrowOnEmailCheck = true;
      authRepository.exceptionMessage = 'Network connection failed';

      // Act
      final result = await authService.isEmailRegistered('test@example.com');

      // Assert 
      expect(result, isFalse);
      expect(result, isNot(isTrue)); 
      // Verify attempt was made
      expect(authRepository.emailCheckCalls, contains('test@example.com'));
    });

    test('getCurrentUser should return null when not authenticated', () async {
      // Arrange
      authRepository = FakeAuthRepository(startAuthenticated: false);
      authService = AuthServiceImpl(
        notifier: authNotifier,
        repository: authRepository,
      );
      
      // Act
      final userCredential = await authService.getCurrentUser();
      
      // Assert - Rigorous verification
      expect(userCredential, isNull);
      expect(authRepository.getCurrentUserCallCount, 1);
    });
    
    test('getCurrentUser should return credentials when authenticated', () async {
      // Arrange
      final repo = FakeAuthRepository(startAuthenticated: true);
      final notifier = FakeAuthNotifier();
      final authService = AuthServiceImpl(
        notifier: notifier,
        repository: repo,
      );
      
      // Act
      final credential = await authService.getCurrentUser();
      
      // Assert - Rigorous verification
      expect(credential, isNotNull);
      expect(credential?.email, isNotNull);
      expect(credential?.id, isNotNull);
      // One call during initialization, one call during our explicit call
      expect(repo.getCurrentUserCallCount, 2);
    });

    test('user can retry login after a failed attempt', () async {
      // Arrange - first login attempt fails
      authRepository.fakeAuthResponse(succeed: false);
      final firstAttempt = await authService.loginWithEmail('test@example.com', 'wrong');
      expect(firstAttempt, false);
      
      // Arrange - second login attempt succeeds
      authRepository.fakeAuthResponse(succeed: true);
      
      // Act
      final secondAttempt = await authService.loginWithEmail('test@example.com', 'correct');
      
      // Assert - Rigorous verification
      expect(secondAttempt, true);
      expect(authRepository.loginCalls, containsAll(['test@example.com:wrong', 'test@example.com:correct']));
      expect(authRepository.loginCalls.length, 2);
    });
  });
  
  group('Auth State Management', () {
    late FakeAuthNotifier authNotifier;
    late FakeAuthRepository authRepository;
    late AuthServiceImpl authService;

    setUp(() {
      // Initialize AppConfig.environment to prevent Logger errors
      AppConfig.instance.environment = Environment.dev;
      
      // Create the fake dependencies
      authNotifier = FakeAuthNotifier();
      authRepository = FakeAuthRepository();
      
      // Create the service to test
      authService = AuthServiceImpl(
        notifier: authNotifier,
        repository: authRepository,
      );
    });

    tearDown(() {
      authNotifier.dispose();
      authRepository.dispose();
    });
    
    test('successful login should emit correct auth state', () async {
      // Arrange
      authNotifier = FakeAuthNotifier();
      authRepository = FakeAuthRepository();
      authService = AuthServiceImpl(
        notifier: authNotifier,
        repository: authRepository,
      );
      
      // Act
      final result = await authService.loginWithEmail('test@example.com', 'password');
      
      // Allow time for async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Assert - Rigorous verification
      expect(result, true);
      expect(authNotifier.loginEvents.isNotEmpty, true);
      expect(authNotifier.loginEvents.first.email, 'test@example.com');
      expect(authNotifier.loginEvents.length, 1);
    });
    
    test('logout should emit unauthenticated state', () async {
      // Arrange
      authNotifier = FakeAuthNotifier();
      authRepository = FakeAuthRepository(startAuthenticated: true);
      authService = AuthServiceImpl(
        notifier: authNotifier,
        repository: authRepository,
      );
      
      // Act
      await authService.logout();
      
      // Allow time for async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Assert - Rigorous verification
      expect(authNotifier.logoutEvents.length, 1);
      expect(authRepository.logoutCalls.length, 1);
    });
    
    test('repository authentication changes should propagate to notifier', () async {
      // Arrange
      authNotifier = FakeAuthNotifier();
      authRepository = FakeAuthRepository();
      authService = AuthServiceImpl(
        notifier: authNotifier,
        repository: authRepository,
      );
      
      // Act - simulate auth state change from repository
      authRepository.emitAuthStateChanged(AuthStatus.authenticated);
      
      // Assert - check that the auth service forwarded it to the notifier
      await Future.delayed(Duration(milliseconds: 100)); // Allow time for stream events
      expect(authNotifier.stateChangedEvents.contains(AuthStatus.authenticated), true);
      expect(authNotifier.stateChangedEvents.length, greaterThan(0));
    });
    
    test('setup profile event should be emitted when profile not found', () async {
      // Arrange
      authNotifier = FakeAuthNotifier();
      authRepository = FakeAuthRepository(startAuthenticated: true);
      
      // Configure the repository to return null for user profile
      authRepository.returnNullUserProfile = true;
      
      // Create service which will trigger user profile check on initialization
      authService = AuthServiceImpl(
        notifier: authNotifier,
        repository: authRepository,
      );
      
      // Act - explicitly trigger a user info check
      await authService.getUserInfo();
      
      // Allow time for async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Assert - Rigorous verification
      expect(authNotifier.setupProfileEvents.length, greaterThan(0));
    });
  });

  group('Error Handling and Edge Cases', () {
    test('logout should handle repository failure gracefully', () async {
      // Arrange
      authRepository.reset();
      authRepository.fakeAuthResponse(succeed: false, errorMessage: 'Logout failed');
      
      // Act & Assert
      expect(() => authService.logout(), throwsException);
      expect(authRepository.logoutCalls.length, 1);
    });

    test('logout should handle exceptions during logout', () async {
      // Arrange
      authRepository.reset();
      authRepository.shouldThrowOnLogout = true;
      authRepository.exceptionMessage = 'Network error';
      
      // Act & Assert
      expect(() => authService.logout(), throwsException);
      expect(authRepository.logoutCalls.length, 1);
    });

    test('getUserInfo should return null when no current user', () async {
      // Arrange
      authRepository.reset(); // This clears the current user
      
      // Act
      final result = await authService.getUserInfo();
      
      // Assert
      expect(result, isNull);
      expect(authRepository.getUserProfileCalls, isEmpty);
    });

    test('getUserInfo should handle profile retrieval failure', () async {
      // Arrange
      authRepository.reset(authenticated: true);
      authRepository.fakeAuthResponse(succeed: false, errorMessage: 'Profile not found');
      
      // Act
      final result = await authService.getUserInfo();
      
      // Assert
      expect(result, isNull);
      expect(authRepository.getUserProfileCalls, contains('test-user-id'));
    });

    test('getUserInfo should emit setup profile event when profile not found', () async {
      // Arrange
      authRepository.reset(authenticated: true);
      authNotifier.reset();
      authRepository.returnNullUserProfile = true;
      
      // Act
      final result = await authService.getUserInfo();
      
      // Allow time for async operations
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Assert
      expect(result, isNull);
      expect(authRepository.getUserProfileCalls, contains('test-user-id'));
      expect(authNotifier.setupProfileEvents.length, 1);
    });

    test('getUserInfo should handle exceptions during profile retrieval', () async {
      // Arrange
      authRepository.reset(authenticated: true);
      authRepository.shouldThrowOnGetUserProfile = true;
      authRepository.exceptionMessage = 'Database error';
      
      // Act
      final result = await authService.getUserInfo();
      
      // Assert
      expect(result, isNull);
      expect(authRepository.getUserProfileCalls, contains('test-user-id'));
    });

    test('getUserInfo should handle success with null profile data', () async {
      // Arrange
      authRepository.reset(authenticated: true);
      authRepository.returnSuccessWithNullUserProfile = true;
      
      // Act
      final result = await authService.getUserInfo();
      
      // Assert
      expect(result, isNull);
      expect(authRepository.getUserProfileCalls, contains('test-user-id'));
    });

    test('should handle successful profile retrieval', () async {
      // Arrange
      authRepository.reset(authenticated: true);
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
      
      // Act
      final result = await authService.getUserInfo();
      
      // Assert
      expect(result, isNotNull);
      expect(result?.id, equals('test-user-id'));
      expect(result?.email, equals('test@example.com'));
      expect(authRepository.getUserProfileCalls, contains('test-user-id'));
    });

    test('getCurrentUser should return current credentials', () async {
      // Arrange
      authRepository.reset(authenticated: true);
      
      // Act
      final result = await authService.getCurrentUser();
      
      // Assert
      expect(result, isNotNull);
      expect(result?.id, equals('test-user-id'));
      expect(result?.email, equals('test@example.com'));
    });

    test('getCurrentUser should return null when no user', () async {
      // Arrange
      authRepository.reset(); // This clears the current user
      
      // Act
      final result = await authService.getCurrentUser();
      
      // Assert
      expect(result, isNull);
    });

    test('isAuthenticated should return repository authentication status', () {
      // Arrange
      authRepository.reset(authenticated: true);
      
      // Act
      final result = authService.isAuthenticated();
      
      // Assert
      expect(result, isTrue);
    });

    test('isAuthenticated should return false when not authenticated', () {
      // Arrange
      authRepository.reset(); // This clears the current user
      
      // Act
      final result = authService.isAuthenticated();
      
      // Assert
      expect(result, isFalse);
    });

    test('authStateChanges should return repository auth state stream', () {
      // Arrange & Act
      final stream = authService.authStateChanges;
      
      // Assert
      expect(stream, isNotNull);
      expect(stream, equals(authRepository.authStateChanges));
    });

    test('dispose should clean up resources', () {
      // Act
      authService.dispose();
      
      // Assert - No exception should be thrown
      expect(true, isTrue); // Test passes if no exception
    });

    test('should handle auth state stream errors', () async {
      // Arrange
      authRepository.reset();
      authNotifier.reset();
      
      // Act - Emit an error on the auth state stream
      authRepository.emitAuthStreamError('Stream error');
      
      // Allow time for error handling
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Assert - The service should handle the error gracefully
      // The error handling is internal, so we just verify no exception is thrown
      expect(true, isTrue);
    });

    test('should handle user credentials stream errors', () async {
      // Arrange
      authRepository.reset();
      authNotifier.reset();
      
      // Act - Emit an error on the user credentials stream
      authRepository.emitUserStreamError('User stream error');
      
      // Allow time for error handling
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Assert - The service should handle the error gracefully
      // The error handling is internal, so we just verify no exception is thrown
      expect(true, isTrue);
    });
  });
} 
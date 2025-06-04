import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// A fake implementation of IAuthRepository for testing purposes.
class FakeAuthRepository implements AuthRepository, Disposable {
  final _authStateController = StreamController<AuthStatus>.broadcast();
  final _userController = StreamController<UserCredential?>.broadcast();
  
  // Control vars for testing
  UserCredential? _currentUser;
  final Map<String, User> _userProfiles = {};
  bool _authShouldSucceed = true;
  String? _errorMessage;
  bool shouldRejectEmptyCredentials = false;
  bool returnNullUserProfile = false;
  bool returnSuccessWithNullData = false;
  bool returnSuccessWithNullUserProfile = false; // New flag for getUserProfile testing
  
  // Exception throwing flags for testing catch blocks
  bool shouldThrowOnLogin = false;
  bool shouldThrowOnRegister = false;
  bool shouldThrowOnSendOtp = false;
  bool shouldThrowOnVerifyOtp = false;
  bool shouldThrowOnResetPassword = false;
  bool shouldThrowOnEmailCheck = false;
  bool shouldThrowOnLogout = false;
  bool shouldThrowOnGetUserProfile = false;
  String exceptionMessage = 'Test exception';
  
  // For tracking method calls in tests
  final List<String> loginCalls = [];
  final List<String> registerCalls = [];
  final List<String> logoutCalls = [];
  final List<String> sendOtpCalls = [];
  final List<String> verifyOtpCalls = [];
  final List<String> resetPasswordCalls = [];
  final List<String> emailCheckCalls = [];
  final List<String> getUserProfileCalls = [];
  final List<User> createProfileCalls = [];
  final List<User> updateProfileCalls = [];
  int getCurrentUserCallCount = 0;
  
  // OTP tracking - now includes receiver type
  final Map<String, Map<OtpReceiver, String>> _sentOtpCodes = {}; // Maps address -> receiver -> code
  
  // Email registration tracking
  final Set<String> _registeredEmails = {'registered@example.com'};
  
  FakeAuthRepository({bool startAuthenticated = false}) {
    if (startAuthenticated) {
      _setAuthenticatedUser(
        UserCredential(
          id: 'test-user-id',
          email: 'test@example.com',
          metadata: {},
          createdAt: DateTime.now(),
        ),
      );
    } else {
      _authStateController.add(AuthStatus.unauthenticated);
    }
  }
  
  /// Control method to set the authenticated user
  void _setAuthenticatedUser(UserCredential user) {
    _currentUser = user;
    _authStateController.add(AuthStatus.authenticated);
    _userController.add(user);
  }
  
  /// Configure testing behavior
  void fakeAuthResponse({bool succeed = true, String? errorMessage}) {
    _authShouldSucceed = succeed;
    _errorMessage = errorMessage;
  }
  
  /// Setup fake user profiles for testing
  void fakeUserProfile(User user) {
    _userProfiles[user.credentialId] = user;
  }
  
  @override
  Future<AuthResult<UserCredential>> loginWithEmail(String email, String password) async {
    loginCalls.add('$email:$password');
    
    // Throw exception if configured to do so
    if (shouldThrowOnLogin) {
      throw Exception(exceptionMessage);
    }
    
    if (shouldRejectEmptyCredentials && (email.isEmpty || password.isEmpty)) {
      return AuthResult.failure('Email or password cannot be empty', AuthErrorType.invalidCredentials);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Authentication failed', AuthErrorType.invalidCredentials);
    }
    
    // For testing AND logic mutations - return success but with null data
    if (returnSuccessWithNullData) {
      return AuthResult.success(null);
    }
    
    final user = UserCredential(
      id: 'user-${email.split('@')[0]}',
      email: email,
      metadata: {'loginMethod': 'email'},
      createdAt: DateTime.now(),
    );
    
    _setAuthenticatedUser(user);
    return AuthResult.success(user);
  }
  
  @override
  Future<AuthResult<UserCredential>> registerWithEmail(String email, String password) async {
    registerCalls.add('$email:$password');
    
    // Throw exception if configured to do so
    if (shouldThrowOnRegister) {
      throw Exception(exceptionMessage);
    }
    
    if (shouldRejectEmptyCredentials && (email.isEmpty || password.isEmpty)) {
      return AuthResult.failure('Email or password cannot be empty', AuthErrorType.registrationFailure);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Registration failed', AuthErrorType.registrationFailure);
    }
    
    // For testing AND logic mutations - return success but with null data
    if (returnSuccessWithNullData) {
      return AuthResult.success(null);
    }
    
    final user = UserCredential(
      id: 'user-${email.split('@')[0]}',
      email: email,
      metadata: {'registrationMethod': 'email'},
      createdAt: DateTime.now(),
    );
    
    _setAuthenticatedUser(user);
    return AuthResult.success(user);
  }
  
  @override
  Future<AuthResult<void>> sendOtp(String address, OtpReceiver receiver) async {
    sendOtpCalls.add('$address:$receiver');
    
    // Throw exception if configured to do so
    if (shouldThrowOnSendOtp) {
      throw Exception(exceptionMessage);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to send OTP', AuthErrorType.serverError);
    }
    
    // Generate a fake 6-digit OTP code
    final otp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    
    // Initialize the address entry if it doesn't exist
    if (!_sentOtpCodes.containsKey(address)) {
      _sentOtpCodes[address] = {};
    }
    
    // Add the receiver-specific OTP
    _sentOtpCodes[address]![receiver] = otp;
    
    return AuthResult.success(null);
  }
  
  @override
  Future<AuthResult<UserCredential>> verifyOtp(String address, String otp, OtpReceiver receiver) async {
    verifyOtpCalls.add('$address:$otp:$receiver');
    
    // Throw exception if configured to do so
    if (shouldThrowOnVerifyOtp) {
      throw Exception(exceptionMessage);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'OTP verification failed', AuthErrorType.invalidCredentials);
    }
    
    // Check if the OTP matches what was sent
    final sentOtp = _sentOtpCodes[address]?[receiver];
    if (sentOtp == null) {
      return AuthResult.failure('No OTP was sent to this address', AuthErrorType.invalidCredentials);
    }
    
    if (sentOtp != otp && otp != '123456') { // Allow a test-specific OTP
      return AuthResult.failure('Invalid OTP code', AuthErrorType.invalidCredentials);
    }
    
    // OTP is valid, authenticate the user
    final user = UserCredential(
      id: 'user-${address.split('@')[0]}',
      email: receiver == OtpReceiver.email ? address : 'fake@example.com',
      metadata: {'loginMethod': 'otp', 'receiver': receiver.name},
      createdAt: DateTime.now(),
    );
    
    _setAuthenticatedUser(user);
    return AuthResult.success(user);
  }
  
  @override
  Future<AuthResult<void>> resetPassword(String email) async {
    resetPasswordCalls.add(email);
    
    // Throw exception if configured to do so
    if (shouldThrowOnResetPassword) {
      throw Exception(exceptionMessage);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to send password reset email', AuthErrorType.serverError);
    }
    
    // Just record that this was called - in a real system, an email would be sent
    return AuthResult.success(null);
  }
  
  @override
  Future<AuthResult<bool>> isEmailRegistered(String email) async {
    emailCheckCalls.add(email);
    
    // Throw exception if configured to do so
    if (shouldThrowOnEmailCheck) {
      throw Exception(exceptionMessage);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to check email registration', AuthErrorType.serverError);
    }
    
    // Check if email is in our predefined set or was previously registered
    final isRegistered = _registeredEmails.contains(email);
    return AuthResult.success(isRegistered);
  }
  
  @override
  Future<AuthResult<void>> logout() async {
    logoutCalls.add('logout');
    
    // Throw exception if configured to do so
    if (shouldThrowOnLogout) {
      throw Exception(exceptionMessage);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Logout failed', AuthErrorType.serverError);
    }
    
    _currentUser = null;
    _authStateController.add(AuthStatus.unauthenticated);
    _userController.add(null);
    return AuthResult.success(null);
  }
  
  @override
  bool isAuthenticated() {
    return _currentUser != null;
  }
  
  @override
  UserCredential? getCurrentCredentials() {
    getCurrentUserCallCount++;
    return _currentUser;
  }
  
  @override
  Future<AuthResult<User>> getUserProfile(String userId) async {
    getUserProfileCalls.add(userId);
    
    // Throw exception if configured to do so
    if (shouldThrowOnGetUserProfile) {
      throw Exception(exceptionMessage);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to get user profile', AuthErrorType.serverError);
    }
    
    // For testing AND→OR mutations - return success but with null data
    if (returnSuccessWithNullUserProfile) {
      return AuthResult.success(null);
    }
    
    // For testing profile not found scenario
    if (returnNullUserProfile) {
      return AuthResult.failure('User profile not found', AuthErrorType.userNotFound);
    }
    
    final profile = _userProfiles[userId];
    
    if (profile != null) {
      return AuthResult.success(profile);
    } else {
      return AuthResult.failure('User profile not found', AuthErrorType.userNotFound);
    }
  }
  
  @override
  Future<AuthResult<User>> createUserProfile(User user) async {
    createProfileCalls.add(user);
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to create user profile', AuthErrorType.serverError);
    }
    
    // Create a copy with an ID
    final createdUser = User(
      id: 'profile-${user.email.split('@')[0]}',
      credentialId: user.credentialId,
      email: user.email,
      phone: user.phone,
      firstName: user.firstName,
      lastName: user.lastName,
      professionalRole: user.professionalRole,
      profilePhotoUrl: user.profilePhotoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userStatus: user.userStatus,
      userPreferences: user.userPreferences,
    );
    
    _userProfiles[user.credentialId] = createdUser;
    return AuthResult.success(createdUser);
  }
  
  @override
  Future<AuthResult<User>> updateUserProfile(User user) async {
    updateProfileCalls.add(user);
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to update user profile', AuthErrorType.serverError);
    }
    
    if (!_userProfiles.containsKey(user.credentialId)) {
      return AuthResult.failure('User profile not found', AuthErrorType.userNotFound);
    }
    
    // Create a copy with updated timestamp
    final updatedUser = User(
      id: user.id,
      credentialId: user.credentialId,
      email: user.email,
      phone: user.phone,
      firstName: user.firstName,
      lastName: user.lastName,
      professionalRole: user.professionalRole,
      profilePhotoUrl: user.profilePhotoUrl,
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
      userStatus: user.userStatus,
      userPreferences: user.userPreferences,
    );
    
    _userProfiles[user.credentialId] = updatedUser;
    return AuthResult.success(updatedUser);
  }
  
  @override
  Stream<AuthStatus> get authStateChanges => _authStateController.stream;
  
  @override
  Stream<UserCredential?> get userChanges => _userController.stream;
  
  /// Emulates a user update event
  void emitUserUpdated(UserCredential? user) {
    _currentUser = user;
    _userController.add(user);
  }
  
  /// Manually triggers an auth state change
  void emitAuthStateChanged(AuthStatus status) {
    _authStateController.add(status);
    if (status == AuthStatus.unauthenticated) {
      _currentUser = null;
      _userController.add(null);
    }
  }
  
  /// Manually triggers an auth state stream error for testing
  void emitAuthStreamError(String errorMessage) {
    _authStateController.addError(Exception(errorMessage));
  }
  
  /// Manually triggers a user credentials stream error for testing
  void emitUserStreamError(String errorMessage) {
    _userController.addError(Exception(errorMessage));
  }
  
  /// Get the OTP sent to an address for testing purposes
  String? getSentOtp(String address, [OtpReceiver? receiver]) {
    final addressMap = _sentOtpCodes[address];
    if (addressMap == null) return null;
    
    if (receiver != null) {
      return addressMap[receiver];
    }
    
    // For backward compatibility, return the first available OTP
    return addressMap.values.isNotEmpty ? addressMap.values.first : null;
  }
  
  /// Reset the fake to its initial state
  void reset({bool authenticated = false}) {
    _currentUser = null;
    _userProfiles.clear();
    _authShouldSucceed = true;
    _errorMessage = null;
    shouldRejectEmptyCredentials = false;
    returnNullUserProfile = false;
    returnSuccessWithNullData = false;
    returnSuccessWithNullUserProfile = false;
    
    // Reset exception throwing flags
    shouldThrowOnLogin = false;
    shouldThrowOnRegister = false;
    shouldThrowOnSendOtp = false;
    shouldThrowOnVerifyOtp = false;
    shouldThrowOnResetPassword = false;
    shouldThrowOnEmailCheck = false;
    shouldThrowOnLogout = false;
    shouldThrowOnGetUserProfile = false;
    exceptionMessage = 'Test exception';
    
    _sentOtpCodes.clear();
    loginCalls.clear();
    registerCalls.clear();
    logoutCalls.clear();
    sendOtpCalls.clear();
    verifyOtpCalls.clear();
    resetPasswordCalls.clear();
    emailCheckCalls.clear();
    getUserProfileCalls.clear();
    createProfileCalls.clear();
    updateProfileCalls.clear();
    
    if (authenticated) {
      _setAuthenticatedUser(
        UserCredential(
          id: 'test-user-id',
          email: 'test@example.com',
          metadata: {},
          createdAt: DateTime.now(),
        ),
      );
    } else {
      _authStateController.add(AuthStatus.unauthenticated);
      _userController.add(null);
    }
  }
  
  @override
  void dispose() {
    _authStateController.close();
    _userController.close();
  }
} 
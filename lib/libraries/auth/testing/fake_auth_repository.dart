import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// A fake implementation of AuthRepository for testing purposes.
class FakeAuthRepository implements AuthRepository, Disposable {
  /// Controller for authentication state changes
  final _authStateController = StreamController<AuthStatus>.broadcast();

  /// Controller for user changes
  final _userController = StreamController<UserCredential?>.broadcast();
  
  /// Currently authenticated user
  UserCredential? _currentUser;

  /// Map of user profiles, keyed by credentialId
  final Map<String, User> _userProfiles = {};

  /// Flag to control if authentication should succeed
  bool _authShouldSucceed = true;

  /// Error message to be returned on exceptions
  String? _errorMessage;

  /// Flag to control if empty credentials should be rejected
  bool shouldRejectEmptyCredentials = false;

  /// Flag to control if a null user profile should be returned
  bool returnNullUserProfile = false;

  /// Flag to control if a success result with null data should be returned
  bool returnSuccessWithNullData = false;

  /// Flag to control if a success result with null user profile should be returned
  bool returnSuccessWithNullUserProfile = false;
  
  /// Flag to control if a login should throw an exception
  bool shouldThrowOnLogin = false;

  /// Flag to control if a registration should throw an exception
  bool shouldThrowOnRegister = false;

  /// Flag to control if a send OTP should throw an exception
  bool shouldThrowOnSendOtp = false;

  /// Flag to control if a verify OTP should throw an exception
  bool shouldThrowOnVerifyOtp = false;

  /// Flag to control if a reset password should throw an exception
  bool shouldThrowOnResetPassword = false;

  /// Flag to control if an email check should throw an exception
  bool shouldThrowOnEmailCheck = false;

  /// Flag to control if a logout should throw an exception
  bool shouldThrowOnLogout = false;

  /// Flag to control if a get user profile should throw an exception
  bool shouldThrowOnGetUserProfile = false;

  /// Exception message to be returned on exceptions
  String exceptionMessage = 'Test exception';
  
  /// List of login calls
  final List<String> loginCalls = [];

  /// List of register calls
  final List<String> registerCalls = [];

  /// List of logout calls
  final List<String> logoutCalls = [];

  /// List of send OTP calls
  final List<String> sendOtpCalls = [];

  /// List of verify OTP calls
  final List<String> verifyOtpCalls = [];

  /// List of reset password calls
  final List<String> resetPasswordCalls = [];

  /// List of email check calls
  final List<String> emailCheckCalls = [];

  /// List of get user profile calls
  final List<String> getUserProfileCalls = [];

  /// List of create profile calls
  final List<User> createProfileCalls = [];

  /// List of update profile calls
  final List<User> updateProfileCalls = [];

  /// Count of get current user calls
  int getCurrentUserCallCount = 0;
  
  /// OTP tracking - now includes receiver type
  final Map<String, Map<OtpReceiver, String>> _sentOtpCodes = {}; // Maps address -> receiver -> code
  
  /// Tracks a set of registered emails
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
  
  /// Sets the authenticated user and sets the authentication state to authenticated
  void _setAuthenticatedUser(UserCredential user) {
    _currentUser = user;
    _authStateController.add(AuthStatus.authenticated);
    _userController.add(user);
  }
  
  /// Configures the response behavior for the auth operations
  void fakeAuthResponse({bool succeed = true, String? errorMessage}) {
    _authShouldSucceed = succeed;
    _errorMessage = errorMessage;
  }
  
  /// Sets up fake user profiles for testing
  void fakeUserProfile(User user) {
    _userProfiles[user.credentialId] = user;
  }
  
  @override
  Future<AuthResult<UserCredential>> loginWithEmail(String email, String password) async {
    loginCalls.add('$email:$password');
    
    if (shouldThrowOnLogin) {
      throw Exception(exceptionMessage);
    }
    
    if (shouldRejectEmptyCredentials && (email.isEmpty || password.isEmpty)) {
      return AuthResult.failure('Email or password cannot be empty', AuthErrorType.invalidCredentials);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Authentication failed', AuthErrorType.invalidCredentials);
    }
    
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
    
    if (shouldThrowOnRegister) {
      throw Exception(exceptionMessage);
    }
    
    if (shouldRejectEmptyCredentials && (email.isEmpty || password.isEmpty)) {
      return AuthResult.failure('Email or password cannot be empty', AuthErrorType.registrationFailure);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Registration failed', AuthErrorType.registrationFailure);
    }
    
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
    
    if (shouldThrowOnSendOtp) {
      throw Exception(exceptionMessage);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to send OTP', AuthErrorType.serverError);
    }
    
    final otp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    
    if (!_sentOtpCodes.containsKey(address)) {
      _sentOtpCodes[address] = {};
    }
    
    _sentOtpCodes[address]![receiver] = otp;
    
    return AuthResult.success(null);
  }
  
  @override
  Future<AuthResult<UserCredential>> verifyOtp(String address, String otp, OtpReceiver receiver) async {
    verifyOtpCalls.add('$address:$otp:$receiver');
    
    if (shouldThrowOnVerifyOtp) {
      throw Exception(exceptionMessage);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'OTP verification failed', AuthErrorType.invalidCredentials);
    }
    
    final sentOtp = _sentOtpCodes[address]?[receiver];
    if (sentOtp == null) {
      return AuthResult.failure('No OTP was sent to this address', AuthErrorType.invalidCredentials);
    }
    
    if (sentOtp != otp && otp != '123456') {
      return AuthResult.failure('Invalid OTP code', AuthErrorType.invalidCredentials);
    }
    
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
    
    if (shouldThrowOnResetPassword) {
      throw Exception(exceptionMessage);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to send password reset email', AuthErrorType.serverError);
    }
    
    return AuthResult.success(null);
  }
  
  @override
  Future<AuthResult<bool>> isEmailRegistered(String email) async {
    emailCheckCalls.add(email);
    
    if (shouldThrowOnEmailCheck) {
      throw Exception(exceptionMessage);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to check email registration', AuthErrorType.serverError);
    }
    
    final isRegistered = _registeredEmails.contains(email);
    return AuthResult.success(isRegistered);
  }
  
  @override
  Future<AuthResult<void>> logout() async {
    logoutCalls.add('logout');
    
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
    
    if (shouldThrowOnGetUserProfile) {
      throw Exception(exceptionMessage);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to get user profile', AuthErrorType.serverError);
    }
    
    if (returnSuccessWithNullUserProfile) {
      return AuthResult.success(null);
    }
    
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
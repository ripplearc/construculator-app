import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';

class FakeAuthManager implements AuthManager {
  final AuthNotifier _authNotifier;
  final AuthRepository _authRepository;
  
  /// Flag to control if auth operations should succeed
  bool _authShouldSucceed = true;
  
  /// Error message to be returned on failure
  String? _errorMessage;
  
  /// Currently authenticated user credential
  UserCredential? _currentCredential;
  
  /// List of login attempts
  final List<({String email, String password})> loginAttempts = [];
  
  /// List of registration attempts
  final List<({String email, String password})> registrationAttempts = [];
  
  /// List of OTP send attempts
  final List<({String address, OtpReceiver receiver})> otpSendAttempts = [];
  
  /// List of OTP verification attempts
  final List<({String address, String otp, OtpReceiver receiver})> otpVerificationAttempts = [];
  
  /// List of password reset attempts
  final List<String> passwordResetAttempts = [];
  
  /// List of email registration check attempts
  final List<String> emailCheckAttempts = [];
  
  /// List of logout attempts
  final List<void> logoutAttempts = [];

  FakeAuthManager({
    required AuthNotifier authNotifier,
    required AuthRepository authRepository,
  })  : _authNotifier = authNotifier,
        _authRepository = authRepository;

  /// Configure the auth response behavior
  void setAuthResponse({bool succeed = true, String? errorMessage}) {
    _authShouldSucceed = succeed;
    _errorMessage = errorMessage;
  }

  /// Set the current user credential
  void setCurrentCredential(UserCredential? credential) {
    _currentCredential = credential;
    if (credential != null) {
      _authNotifier.emitAuthStateChanged(
        AuthState(status: AuthStatus.authenticated, user: credential),
      );
    } else {
      _authNotifier.emitAuthStateChanged(
        AuthState(status: AuthStatus.unauthenticated, user: null),
      );
    }
  }

  @override
  Future<AuthResult<UserCredential>> loginWithEmail(
    String email,
    String password,
  ) async {
    loginAttempts.add((email: email, password: password));
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(
        _errorMessage ?? 'Login failed',
        AuthErrorType.invalidCredentials,
      );
    }

    final credential = UserCredential(
      id: 'test-${email.split('@')[0]}',
      email: email,
      metadata: {},
      createdAt: DateTime.now(),
    );
    
    setCurrentCredential(credential);
    return AuthResult.success(credential);
  }

  @override
  Future<AuthResult<UserCredential>> registerWithEmail(
    String email,
    String password,
  ) async {
    registrationAttempts.add((email: email, password: password));
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(
        _errorMessage ?? 'Registration failed',
        AuthErrorType.registrationFailure,
      );
    }

    final credential = UserCredential(
      id: 'test-${email.split('@')[0]}',
      email: email,
      metadata: {},
      createdAt: DateTime.now(),
    );
    
    setCurrentCredential(credential);
    return AuthResult.success(credential);
  }

  @override
  Future<AuthResult> sendOtp(String address, OtpReceiver receiver) async {
    otpSendAttempts.add((address: address, receiver: receiver));
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(
        _errorMessage ?? 'Failed to send OTP',
        AuthErrorType.serverError,
      );
    }
    
    return AuthResult.success(null);
  }

  @override
  Future<AuthResult<UserCredential>> verifyOtp(
    String address,
    String otp,
    OtpReceiver receiver,
  ) async {
    otpVerificationAttempts.add((
      address: address,
      otp: otp,
      receiver: receiver,
    ));
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(
        _errorMessage ?? 'Invalid verification code',
        AuthErrorType.invalidCredentials,
      );
    }

    final credential = UserCredential(
      id: 'test-${address.split('@')[0]}',
      email: receiver == OtpReceiver.email ? address : '',
      metadata: {},
      createdAt: DateTime.now(),
    );
    
    setCurrentCredential(credential);
    return AuthResult.success(credential);
  }

  @override
  Future<AuthResult<bool>> resetPassword(String email) async {
    passwordResetAttempts.add(email);
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(
        _errorMessage ?? 'Password reset failed',
        AuthErrorType.invalidCredentials,
      );
    }
    
    return AuthResult.success(true);
  }

  @override
  Future<AuthResult<bool>> isEmailRegistered(String email) async {
    emailCheckAttempts.add(email);
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(
        _errorMessage ?? 'Email check failed',
        AuthErrorType.serverError,
      );
    }
    
    return AuthResult.success(true);
  }

  @override
  Future<AuthResult<void>> logout() async {
    logoutAttempts.add(null);
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(
        _errorMessage ?? 'Logout failed',
        AuthErrorType.serverError,
      );
    }
    
    setCurrentCredential(null);
    return AuthResult.success(null);
  }

  @override
  bool isAuthenticated() {
    return _currentCredential != null;
  }

  @override
  Future<AuthResult<User?>> createUserProfile(User user) async {
    if (!_authShouldSucceed) {
      return AuthResult.failure(
        _errorMessage ?? 'Failed to create user profile',
        AuthErrorType.serverError,
      );
    }
    
    final result = await _authRepository.createUserProfile(user);
    _authNotifier.emitUserProfileChanged(result);
    return AuthResult.success(result);
  }

  @override
  AuthResult<UserCredential?> getCurrentCredentials() {
    if (!_authShouldSucceed) {
      return AuthResult.failure(
        _errorMessage ?? 'Failed to get current credentials',
        AuthErrorType.serverError,
      );
    }
    
    return AuthResult.success(_currentCredential);
  }

  @override
  Future<AuthResult<User?>> getUserProfile(String credentialId) async {
    if (!_authShouldSucceed) {
      return AuthResult.failure(
        _errorMessage ?? 'Failed to get user profile',
        AuthErrorType.serverError,
      );
    }
    
    final result = await _authRepository.getUserProfile(credentialId);
    _authNotifier.emitUserProfileChanged(result);
    return AuthResult.success(result);
  }

  @override
  Future<AuthResult<User?>> updateUserProfile(User user) async {
    if (!_authShouldSucceed) {
      return AuthResult.failure(
        _errorMessage ?? 'Failed to update user profile',
        AuthErrorType.serverError,
      );
    }
    
    final result = await _authRepository.updateUserProfile(user);
    _authNotifier.emitUserProfileChanged(result);
    return AuthResult.success(result);
  }

  /// Reset all tracking lists
  void reset() {
    loginAttempts.clear();
    registrationAttempts.clear();
    otpSendAttempts.clear();
    otpVerificationAttempts.clear();
    passwordResetAttempts.clear();
    emailCheckAttempts.clear();
    logoutAttempts.clear();
    _authShouldSucceed = true;
    _errorMessage = null;
    _currentCredential = null;
  }
} 
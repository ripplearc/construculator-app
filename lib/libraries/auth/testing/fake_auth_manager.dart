import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/models/professional_role.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';

/// A fake implementation of [AuthManager] for testing purposes
class FakeAuthManager implements AuthManager {
  final AuthNotifierController _authNotifier;
  final AuthRepository _authRepository;
  final SupabaseWrapper _wrapper;
  final Clock _clock;

  // Flag to control if auth operations should succeed
  bool _authShouldSucceed = true;

  // Error type to be returned on exceptions
  AuthErrorType _errorType = AuthErrorType.serverError;

  // Currently authenticated user credential
  UserCredential? _currentCredential;

  /// List of login attempts
  final List<({String email, String password})> loginAttempts = [];

  /// List of registration attempts
  final List<({String email, String password})> registrationAttempts = [];

  /// List of OTP send attempts
  final List<({String address, OtpReceiver receiver})> otpSendAttempts = [];

  /// List of OTP verification attempts
  final List<({String address, String otp, OtpReceiver receiver})>
  otpVerificationAttempts = [];

  /// List of password reset attempts
  final List<String> passwordResetAttempts = [];

  /// List of email registration check attempts
  final List<String> emailCheckAttempts = [];

  /// List of logout attempts
  final List<void> logoutAttempts = [];

  /// Creates a new [FakeAuthManager]
  FakeAuthManager({
    required AuthNotifierController authNotifier,
    required AuthRepository authRepository,
    required SupabaseWrapper wrapper,
    required Clock clock,
  }) : _authNotifier = authNotifier,
       _authRepository = authRepository,
       _wrapper = wrapper,
       _clock = clock {
    // Initialize with unauthenticated state
    _authNotifier.emitAuthStateChanged(
      AuthState(status: AuthStatus.unauthenticated, user: null),
    );
  }

  /// Configure the auth response behavior
  void setAuthResponse({
    bool succeed = true,
    String? errorMessage,
    AuthErrorType errorType = AuthErrorType.serverError,
  }) {
    _authShouldSucceed = succeed;
    _errorType = errorType;
  }

  /// Set the current user credential
  void setCurrentCredential(UserCredential? credential) {
    _currentCredential = credential;
    _authNotifier.emitAuthStateChanged(
      AuthState(
        status: credential != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: credential,
      ),
    );
  }

  // Validate email format
  AuthResult<void> _validateEmail(String email) {
    final emailValidation = AuthValidation.validateEmail(email);
    if (emailValidation != null) {
      return AuthResult.failure(emailValidation);
    }
    return AuthResult.success(null);
  }

  // Validate password
  AuthResult<void> _validatePassword(String password) {
    final passwordValidation = AuthValidation.validatePassword(password);
    if (passwordValidation != null) {
      return AuthResult.failure(passwordValidation);
    }
    return AuthResult.success(null);
  }

  // Validate OTP format
  AuthResult<void> _validateOtp(String otp) {
    final otpValidation = AuthValidation.validateOtp(otp);
    if (otpValidation != null) {
      return AuthResult.failure(otpValidation);
    }
    return AuthResult.success(null);
  }

  @override
  Future<AuthResult<UserCredential>> loginWithEmail(
    String email,
    String password,
  ) async {
    loginAttempts.add((email: email, password: password));

    // Validate inputs
    final emailValidation = _validateEmail(email);
    if (!emailValidation.isSuccess) {
      return AuthResult.failure(emailValidation.errorType);
    }

    if (password.isEmpty) {
      return AuthResult.failure(AuthErrorType.passwordRequired);
    }

    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
    }

    final credential = UserCredential(
      id: 'test-${email.split('@')[0]}',
      email: email,
      metadata: {},
      createdAt: _clock.now(),
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

    // Validate inputs
    final emailValidation = _validateEmail(email);
    if (!emailValidation.isSuccess) {
      return AuthResult.failure(emailValidation.errorType);
    }

    final passwordValidation = _validatePassword(password);
    if (!passwordValidation.isSuccess) {
      return AuthResult.failure(passwordValidation.errorType);
    }

    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
    }

    final credential = UserCredential(
      id: 'test-${email.split('@')[0]}',
      email: email,
      metadata: {},
      createdAt: _clock.now(),
    );

    setCurrentCredential(credential);
    return AuthResult.success(credential);
  }

  @override
  Future<AuthResult> sendOtp(String address, OtpReceiver receiver) async {
    otpSendAttempts.add((address: address, receiver: receiver));

    // Validate address based on receiver type
    if (receiver == OtpReceiver.email) {
      final validation = _validateEmail(address);
      if (!validation.isSuccess) {
        return AuthResult.failure(validation.errorType);
      }
    }

    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
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

    // Validate address based on receiver type
    if (receiver == OtpReceiver.email) {
      final validation = _validateEmail(address);
      if (!validation.isSuccess) {
        return AuthResult.failure(validation.errorType);
      }
    }

    // Validate OTP
    final otpValidation = _validateOtp(otp);
    if (!otpValidation.isSuccess) {
      return AuthResult.failure(otpValidation.errorType);
    }

    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
    }

    final credential = UserCredential(
      id: 'test-${address.split('@')[0]}',
      email: receiver == OtpReceiver.email ? address : '',
      metadata: {},
      createdAt: _clock.now(),
    );

    setCurrentCredential(credential);
    return AuthResult.success(credential);
  }

  @override
  Future<AuthResult<bool>> resetPassword(String email) async {
    passwordResetAttempts.add(email);

    // Validate email
    final validation = _validateEmail(email);
    if (!validation.isSuccess) {
      return AuthResult.failure(validation.errorType);
    }

    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
    }

    return AuthResult.success(true);
  }

  @override
  Future<AuthResult<bool>> isEmailRegistered(String email) async {
    emailCheckAttempts.add(email);

    // Validate email
    final validation = _validateEmail(email);
    if (!validation.isSuccess) {
      return AuthResult.failure(validation.errorType);
    }

    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
    }

    return AuthResult.success(true);
  }

  @override
  Future<AuthResult<void>> logout() async {
    logoutAttempts.add(null);

    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
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
      return AuthResult.failure(_errorType);
    }

    final result = await _authRepository.createUserProfile(user);
    _authNotifier.emitUserProfileChanged(result);
    return AuthResult.success(result);
  }

  @override
  AuthResult<UserCredential?> getCurrentCredentials() {
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
    }

    return AuthResult.success(_currentCredential);
  }

  @override
  Future<AuthResult<User?>> getUserProfile(String credentialId) async {
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
    }

    try {
      final result = await _authRepository.getUserProfile(credentialId);
      _authNotifier.emitUserProfileChanged(result);
      return AuthResult.success(result);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResult<User?>> updateUserProfile(User user) async {
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
    }

    final result = await _authRepository.updateUserProfile(user);
    _authNotifier.emitUserProfileChanged(result);
    return AuthResult.success(result);
  }

  @override
  Future<AuthResult<UserCredential?>> updateUserPassword(
    String password,
  ) async {
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
    }
    final result = await _authRepository.updateUserPassword(password);
    _authNotifier.emitAuthStateChanged(
      AuthState(status: AuthStatus.authenticated, user: result),
    );
    return AuthResult.success(result);
  }

  @override
  Future<AuthResult<UserCredential?>> updateUserEmail(String email) async {
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
    }
    final result = await _authRepository.updateUserEmail(email);
    _authNotifier.emitAuthStateChanged(
      AuthState(status: AuthStatus.authenticated, user: result),
    );
    return AuthResult.success(result);
  }

  @override
  Future<AuthResult<List<ProfessionalRole>>> getProfessionalRoles() async {
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorType);
    }
    final rolesData = await _wrapper.selectAllProfessionalRoles();
    return AuthResult.success(
      rolesData.map((roleMap) => ProfessionalRole.fromJson(roleMap)).toList(),
    );
  }

  /// Get the auth repository for testing purposes
  AuthRepository get authRepository => _authRepository;

  /// Reset all tracking lists and state
  void reset() {
    loginAttempts.clear();
    registrationAttempts.clear();
    otpSendAttempts.clear();
    otpVerificationAttempts.clear();
    passwordResetAttempts.clear();
    emailCheckAttempts.clear();
    logoutAttempts.clear();
    _authShouldSucceed = true;
    _errorType = AuthErrorType.serverError;
    setCurrentCredential(null);
  }
}

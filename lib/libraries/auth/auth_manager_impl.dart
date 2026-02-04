import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/models/professional_role.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/domain/validation/auth_validation.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthManagerImpl implements AuthManager {
  final SupabaseWrapper _wrapper;
  final AuthNotifierController _authNotifier;
  final AuthRepository _authRepository;
  final _logger = AppLogger().tag('AuthManagerImpl');

  AuthManagerImpl({
    required SupabaseWrapper wrapper,
    required AuthRepository authRepository,
    required AuthNotifierController authNotifier,
  }) : _wrapper = wrapper,
       _authRepository = authRepository,
       _authNotifier = authNotifier {
    _initAuthListener();
  }

  void _emitAuthStateChanged(AuthStatus status, UserCredential? user) {
    _authNotifier.emitAuthStateChanged(AuthState(status: status, user: user));
  }

  void _initAuthListener() {
    _wrapper.onAuthStateChange.listen(
      (state) {
        if (state.event == supabase.AuthChangeEvent.signedIn) {
          final user = state.session?.user;
          if (user != null) {
            _emitAuthStateChanged(
              AuthStatus.authenticated,
              _mapSupabaseUserToCredential(user),
            );
          } else {
            _emitAuthStateChanged(AuthStatus.unauthenticated, null);
          }
        } else if (state.event == supabase.AuthChangeEvent.signedOut) {
          _emitAuthStateChanged(AuthStatus.unauthenticated, null);
        }
      },
      onError: (error) {
        _logger.error('Error in auth state stream', error);
        if (error is supabase.AuthSessionMissingException) {
          _logger.warning('Auth-specific error, emitting unauthenticated');
          _emitAuthStateChanged(AuthStatus.unauthenticated, null);
        } else {
          _logger.warning(
            'Stream error (network/connection issue), emitting connectionError',
          );
          _emitAuthStateChanged(AuthStatus.connectionError, null);
        }
      },
    );
    if (_wrapper.isAuthenticated) {
      final user = _wrapper.currentUser;
      if (user != null) {
        _emitAuthStateChanged(
          AuthStatus.authenticated,
          _mapSupabaseUserToCredential(user),
        );
      } else {
        _emitAuthStateChanged(AuthStatus.unauthenticated, null);
      }
    } else {
      _emitAuthStateChanged(AuthStatus.unauthenticated, null);
    }
  }

  UserCredential _mapSupabaseUserToCredential(supabase.User user) {
    return UserCredential(
      id: user.id,
      email: user.email ?? '',
      metadata: {...user.appMetadata, ...user.userMetadata ?? {}},
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  AuthResult<T> _handleException<T>(dynamic error, String operation) {
    _logger.error('$operation failed with error', error);

    if (error is supabase.AuthException) {
      final code = SupabaseAuthErrorCode.fromCode(error.code ?? 'unknown');
      return AuthResult.failure(code.toAuthErrorType());
    }

    if (error is TimeoutException) {
      return AuthResult.failure(AuthErrorType.timeout);
    }
    if (error is supabase.PostgrestException) {
      final code = PostgresErrorCode.fromCode(error.code ?? 'unknown');
      return AuthResult.failure(code.toAuthErrorType());
    }
    return AuthResult.failure(AuthErrorType.serverError);
  }

  @override
  Future<AuthResult<UserCredential>> loginWithEmail(
    String email,
    String password,
  ) async {
    _logger.info('Attempting login for user: $email');

    // Validate email
    final emailError = AuthValidation.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    // Validate password
    final passwordError = AuthValidation.validatePassword(password);
    if (passwordError != null) {
      return AuthResult.failure(passwordError);
    }

    try {
      final response = await _wrapper.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        _logger.warning('Login failed for user: $email - No user returned');
        return AuthResult.failure(AuthErrorType.invalidCredentials);
      }

      _logger.info('Login successful for user: $email');
      return AuthResult.success(_mapSupabaseUserToCredential(user));
    } catch (e) {
      return _handleException(e, 'Login');
    }
  }

  @override
  Future<AuthResult<UserCredential>> registerWithEmail(
    String email,
    String password,
  ) async {
    _logger.info('Attempting registration for user: $email');

    // Validate email
    final emailError = AuthValidation.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    // Validate password
    final passwordError = AuthValidation.validatePassword(password);
    if (passwordError != null) {
      return AuthResult.failure(passwordError);
    }

    try {
      final response = await _wrapper.signUp(email: email, password: password);
      final user = response.user;
      if (user == null) {
        _logger.warning(
          'Registration failed for user: $email - No user returned',
        );
        return AuthResult.failure(AuthErrorType.registrationFailure);
      }

      _logger.info('Registration successful for user: $email');
      return AuthResult.success(_mapSupabaseUserToCredential(user));
    } catch (e) {
      return _handleException(e, 'Registration');
    }
  }

  @override
  Future<AuthResult> sendOtp(String address, OtpReceiver receiver) async {
    _logger.info('Sending OTP to: $address');

    final addressError = receiver == OtpReceiver.email
        ? AuthValidation.validateEmail(address)
        : AuthValidation.validatePhoneNumber(address);
    if (addressError != null) {
      return AuthResult.failure(addressError);
    }

    try {
      await _wrapper.signInWithOtp(
        email: receiver == OtpReceiver.email ? address : null,
        phone: receiver == OtpReceiver.phone ? address : null,
        shouldCreateUser: true,
      );

      _logger.info('OTP sent successfully to: $address');
      return AuthResult.success(null);
    } catch (e) {
      return _handleException(e, 'Send OTP');
    }
  }

  @override
  Future<AuthResult<UserCredential>> verifyOtp(
    String address,
    String otp,
    OtpReceiver receiver,
  ) async {
    _logger.info('Verifying OTP for: $address');

    final addressError = receiver == OtpReceiver.email
        ? AuthValidation.validateEmail(address)
        : AuthValidation.validatePhoneNumber(address);

    if (addressError != null) {
      return AuthResult.failure(addressError);
    }

    // Validate OTP
    final otpError = AuthValidation.validateOtp(otp);
    if (otpError != null) {
      return AuthResult.failure(otpError);
    }

    try {
      final response = await _wrapper.verifyOTP(
        email: receiver == OtpReceiver.email ? address : null,
        phone: receiver == OtpReceiver.phone ? address : null,
        token: otp,
        type: receiver == OtpReceiver.email
            ? supabase.OtpType.email
            : supabase.OtpType.sms,
      );
      final user = response.user;
      if (user == null) {
        _logger.warning(
          'OTP verification failed for: $address - No user returned',
        );
        return AuthResult.failure(AuthErrorType.invalidCredentials);
      }

      _logger.info('OTP verification successful for: $address');
      return AuthResult.success(_mapSupabaseUserToCredential(user));
    } catch (e) {
      return _handleException(e, 'OTP verification');
    }
  }

  @override
  Future<AuthResult<bool>> resetPassword(String email) async {
    _logger.info('Initiating password reset for: $email');

    // Validate email
    final emailError = AuthValidation.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    try {
      await _wrapper.resetPasswordForEmail(email, redirectTo: null);

      _logger.info('Password reset email sent successfully to: $email');
      return AuthResult.success(null);
    } catch (e) {
      return _handleException(e, 'Password reset');
    }
  }

  @override
  Future<AuthResult<bool>> isEmailRegistered(String email) async {
    _logger.info('Checking if email is registered: $email');

    final emailError = AuthValidation.validateEmail(email);
    if (emailError != null) {
      return AuthResult.failure(emailError);
    }

    try {
      final response = await _wrapper.rpc<bool>(
        'check_email_exists',
        params: {'email_input': email},
      );

      _logger.info('Email check complete for: $email - Registered: $response');
      return AuthResult.success(response);
    } catch (e) {
      return _handleException(e, 'Email registration check');
    }
  }

  @override
  Future<AuthResult<void>> logout() async {
    _logger.info('Logging out user');
    try {
      await _wrapper.signOut();
      _logger.info('Logout successful');
      return AuthResult.success(null);
    } catch (e) {
      return _handleException(e, 'Logout');
    }
  }

  @override
  bool isAuthenticated() {
    return _wrapper.isAuthenticated;
  }

  @override
  Future<AuthResult<User?>> createUserProfile(User user) async {
    try {
      final credentialResult = getCurrentCredentials();
      if (!credentialResult.isSuccess) {
        return AuthResult.failure(AuthErrorType.serverError);
      }
      final credentialId = credentialResult.data?.id;
      if (credentialId == null || credentialId.isEmpty) {
        return AuthResult.failure(AuthErrorType.invalidCredentials);
      }
      user = user.copyWith(credentialId: credentialId);
      final result = await _authRepository.createUserProfile(user);
      _authNotifier.emitUserProfileChanged(result);
      return AuthResult.success(result);
    } catch (e) {
      return _handleException(e, 'Create user profile');
    }
  }

  @override
  AuthResult<UserCredential?> getCurrentCredentials() {
    try {
      final result = _authRepository.getCurrentCredentials();
      return AuthResult.success(result);
    } catch (e) {
      return _handleException(e, 'Get current credentials');
    }
  }

  @override
  Future<AuthResult<User?>> getUserProfile(String credentialId) async {
    try {
      final result = await _authRepository.getUserProfile(credentialId);
      _authNotifier.emitUserProfileChanged(result);
      return AuthResult.success(result);
    } catch (e) {
      return _handleException(e, 'Get user profile');
    }
  }

  @override
  Future<AuthResult<User?>> updateUserProfile(User user) async {
    try {
      final result = await _authRepository.updateUserProfile(user);
      _authNotifier.emitUserProfileChanged(result);
      return AuthResult.success(result);
    } catch (e) {
      return _handleException(e, 'Update user profile');
    }
  }

  @override
  Future<AuthResult<UserCredential?>> updateUserPassword(
    String password,
  ) async {
    try {
      final result = await _authRepository.updateUserPassword(password);
      if (result == null) {
        return AuthResult.failure(AuthErrorType.invalidCredentials);
      }
      _authNotifier.emitAuthStateChanged(
        AuthState(status: AuthStatus.authenticated, user: result),
      );
      return AuthResult.success(result);
    } catch (e) {
      return _handleException(e, 'Update user password');
    }
  }

  @override
  Future<AuthResult<UserCredential?>> updateUserEmail(String email) async {
    try {
      final result = await _authRepository.updateUserEmail(email);
      if (result == null) {
        return AuthResult.failure(AuthErrorType.invalidCredentials);
      }
      _authNotifier.emitAuthStateChanged(
        AuthState(status: AuthStatus.authenticated, user: result),
      );
      return AuthResult.success(result);
    } catch (e) {
      return _handleException(e, 'Update user email');
    }
  }

  @override
  Future<AuthResult<List<ProfessionalRole>>> getProfessionalRoles() async {
    try {
      final rolesData = await _wrapper.selectAllProfessionalRoles();
      return AuthResult.success(
        rolesData.map((roleMap) => ProfessionalRole.fromJson(roleMap)).toList(),
      );
    } catch (e) {
      return _handleException(e, 'Get professional roles');
    }
  }
}

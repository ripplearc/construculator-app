import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SupabaseAuthRepository implements AuthRepository, Disposable {
  final SupabaseWrapper supabaseWrapper;
  final _logger = AppLogger().tag('SupabaseAuthRepository');
  final _authStateController = StreamController<AuthStatus>.broadcast();
  final _userController = StreamController<UserCredential?>.broadcast();
  StreamSubscription<supabase.AuthState>? _authSubscription;

  SupabaseAuthRepository({required this.supabaseWrapper}) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = supabaseWrapper.onAuthStateChange.listen(
      (state) {
        _handleAuthStateChange(state);
      },
      onError: (error) {
        _logger.error('Error in Supabase auth state stream', error);
        if (error is supabase.AuthSessionMissingException) {
          _logger.warning('Auth-specific error, emitting unauthenticated');
          _authStateController.add(AuthStatus.unauthenticated);
          _userController.add(null);
        } else {
          _logger.warning(
            'Non-auth stream error (network/connection issue), emitting connectionError',
          );
          _authStateController.add(AuthStatus.connectionError);
        }
      },
    );

    // Check initial state
    final initialUser = supabaseWrapper.currentUser;
    if (initialUser != null) {
      _authStateController.add(AuthStatus.authenticated);
      _userController.add(_mapSupabaseUserToCredential(initialUser));
    } else {
      _authStateController.add(AuthStatus.unauthenticated);
      _userController.add(null);
    }
  }

  void _handleAuthStateChange(supabase.AuthState state) {
    final event = state.event;
    final session = state.session;

    _logger.info('Auth state changed: $event');

    switch (event) {
      case supabase.AuthChangeEvent.signedIn:
      case supabase.AuthChangeEvent.userUpdated:
      case supabase.AuthChangeEvent.tokenRefreshed:
      case supabase.AuthChangeEvent.mfaChallengeVerified:
        final user = session?.user;
        if (user != null) {
          _authStateController.add(AuthStatus.authenticated);
          _userController.add(_mapSupabaseUserToCredential(user));
        }
        break;
      case supabase.AuthChangeEvent.signedOut:
        _authStateController.add(AuthStatus.unauthenticated);
        _userController.add(null);
        break;
      default:
        _logger.debug('Unhandled auth event: $event');
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

  /// Maps exceptions to appropriate AuthErrorType for better error handling
  AuthResult<T> _handleException<T>(dynamic error, String operation) {
    _logger.error('$operation failed with error', error);

    // Network-related errors
    if (error is SocketException) {
      return AuthResult.failure(
        'Network connection failed. Please check your internet connection.',
        AuthErrorType.networkError,
      );
    }

    if (error is TimeoutException) {
      return AuthResult.failure(
        'Request timed out. Please try again.',
        AuthErrorType.timeout,
      );
    }

    // Supabase AuthException with error codes
    if (error is supabase.AuthException) {
      // Use error.code to check for specific Supabase error codes
      switch (error.code) {
        case 'invalid_credentials':
          return AuthResult.failure(
            'Invalid email or password',
            AuthErrorType.invalidCredentials,
          );
        case 'email_address_invalid':
          return AuthResult.failure(
            'Invalid email address format',
            AuthErrorType.invalidCredentials,
          );
        case 'weak_password':
          return AuthResult.failure(
            'Password does not meet security requirements',
            AuthErrorType.invalidCredentials,
          );
        case 'user_not_found':
          return AuthResult.failure(
            'Invalid email or password',
            AuthErrorType.invalidCredentials,
          ); // Security: don't reveal user existence
        case 'email_not_confirmed':
          return AuthResult.failure(
            'Please verify your email address',
            AuthErrorType.invalidCredentials,
          );
        case 'email_exists':
        case 'user_already_exists':
          return AuthResult.failure(
            'Email already exists',
            AuthErrorType.registrationFailure,
          );
        case 'over_request_rate_limit':
        case 'over_email_send_rate_limit':
        case 'over_sms_send_rate_limit':
          return AuthResult.failure(
            'Too many attempts. Please try again later.',
            AuthErrorType.rateLimited,
          );
        case 'signup_disabled':
        case 'email_provider_disabled':
        case 'phone_provider_disabled':
          return AuthResult.failure(
            'Registration is currently disabled',
            AuthErrorType.registrationFailure,
          );
        case 'session_expired':
        case 'session_not_found':
        case 'refresh_token_not_found':
        case 'refresh_token_already_used':
          return AuthResult.failure(
            'Session expired. Please login again.',
            AuthErrorType.invalidCredentials,
          );
        case 'request_timeout':
          return AuthResult.failure(
            'Request timed out. Please try again.',
            AuthErrorType.timeout,
          );
        case 'otp_expired':
          return AuthResult.failure(
            'OTP code has expired. Please request a new one.',
            AuthErrorType.invalidCredentials,
          );
        case 'bad_jwt':
        case 'no_authorization':
          return AuthResult.failure(
            'Authentication token is invalid',
            AuthErrorType.invalidCredentials,
          );
        default:
          // Fallback for unknown auth error codes
          return AuthResult.failure(
            'Authentication failed',
            AuthErrorType.invalidCredentials,
          );
      }
    }

    if (error is supabase.PostgrestException) {
      switch (convertToPostgresErrorCode(error.code)) {
        case PostgresErrorCode.uniqueViolation:
          return AuthResult.failure(
            'Email already exists',
            AuthErrorType.registrationFailure,
          );
        case PostgresErrorCode.unableToConnect:
        case PostgresErrorCode.connectionFailure:
        case PostgresErrorCode.connectionDoesNotExist:
          return AuthResult.failure(
            'Database connection failed',
            AuthErrorType.connectionError,
          );
        default:
          return AuthResult.failure(
            'Database error occurred',
            AuthErrorType.serverError,
          );
      }
    }

    // Default to server error for unknown errors
    return AuthResult.failure(error.toString(), AuthErrorType.serverError);
  }

  @override
  Future<AuthResult<UserCredential>> loginWithEmail(
    String email,
    String password,
  ) async {
    _logger.info('Attempting login for user: $email');

    try {
      final response = await supabaseWrapper.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        _logger.warning('Login failed for user: $email - No user returned');
        return AuthResult.failure(
          'Login failed - invalid credentials',
          AuthErrorType.invalidCredentials,
        );
      }

      _logger.info('Login successful for user: $email');
      return AuthResult.success(_mapSupabaseUserToCredential(response.user!));
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

    try {
      final response = await supabaseWrapper.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        _logger.warning(
          'Registration failed for user: $email - No user returned',
        );
        return AuthResult.failure(
          'Registration failed - please try again',
          AuthErrorType.registrationFailure,
        );
      }

      _logger.info('Registration successful for user: $email');
      return AuthResult.success(_mapSupabaseUserToCredential(response.user!));
    } catch (e) {
      return _handleException(e, 'Registration');
    }
  }

  @override
  Future<AuthResult<void>> sendOtp(String address, OtpReceiver receiver) async {
    _logger.info('Sending OTP to: $address');
    try {
      // signInWithOtp will send an otp to the address if user is registered already.
      // If the user is not registered, It will create a new user and send an otp to the address
      await supabaseWrapper.signInWithOtp(
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
    try {
      final response = await supabaseWrapper.verifyOTP(
        email: receiver == OtpReceiver.email ? address : null,
        phone: receiver == OtpReceiver.phone ? address : null,
        token: otp,
        type:
            receiver == OtpReceiver.email
                ? supabase.OtpType.email
                : supabase.OtpType.sms,
      );

      if (response.user == null) {
        _logger.warning(
          'OTP verification failed for: $address - No user returned',
        );
        return AuthResult.failure(
          'Invalid verification code',
          AuthErrorType.invalidCredentials,
        );
      }

      _logger.info('OTP verification successful for: $address');
      return AuthResult.success(_mapSupabaseUserToCredential(response.user!));
    } catch (e) {
      return _handleException(e, 'OTP verification');
    }
  }

  @override
  Future<AuthResult<void>> resetPassword(String email) async {
    _logger.info('Initiating password reset for: $email');
    try {
      await supabaseWrapper.resetPasswordForEmail(email, redirectTo: null);

      _logger.info('Password reset email sent successfully to: $email');
      return AuthResult.success(null);
    } catch (e) {
      return _handleException(e, 'Password reset');
    }
  }

  @override
  Future<AuthResult<bool>> isEmailRegistered(String email) async {
    _logger.info('Checking if email is registered: $email');
    try {
      final response = await supabaseWrapper.selectSingle(
        table: 'users',
        columns: 'id',
        filterColumn: 'email',
        filterValue: email,
      );

      final isRegistered = response != null;

      _logger.info(
        'Email check complete for: $email - Registered: $isRegistered',
      );
      return AuthResult.success(isRegistered);
    } catch (e) {
      return _handleException(e, 'Email registration check');
    }
  }

  @override
  Future<AuthResult<void>> logout() async {
    _logger.info('Logging out user');
    try {
      await supabaseWrapper.signOut();
      _logger.info('Logout successful');
      return AuthResult.success(null);
    } catch (e) {
      return _handleException(e, 'Logout');
    }
  }

  @override
  bool isAuthenticated() {
    return supabaseWrapper.isAuthenticated;
  }

  @override
  UserCredential? getCurrentCredentials() {
    final supaUser = supabaseWrapper.currentUser;
    if (supaUser == null) return null;
    return _mapSupabaseUserToCredential(supaUser);
  }

  @override
  Future<AuthResult<User>> getUserProfile(String credentialId) async {
    _logger.debug('Fetching user profile for credential ID: $credentialId');
    try {
      final response = await supabaseWrapper.selectSingle(
        table: 'users',
        filterColumn: 'credential_id',
        filterValue: credentialId,
      );

      if (response == null) {
        _logger.warning(
          'No user profile found for credential ID: $credentialId',
        );
        return AuthResult.failure(
          'User profile not found',
          AuthErrorType.userNotFound,
        );
      }

      _logger.debug('Successfully retrieved user profile');

      // Parse user_preferences from JSONB
      Map<String, dynamic> userPreferences = {};
      if (response['user_preferences'] != null) {
        if (response['user_preferences'] is Map) {
          userPreferences = Map<String, dynamic>.from(
            response['user_preferences'],
          );
        } else if (response['user_preferences'] is String) {
          userPreferences = jsonDecode(response['user_preferences']);
        }
      }

      final user = User(
        id: response['id'].toString(),
        credentialId: response['credential_id'],
        email: response['email'],
        phone: response['phone'],
        firstName: response['first_name'],
        lastName: response['last_name'],
        professionalRole: response['professional_role'],
        profilePhotoUrl: response['profile_photo_url'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        userStatus:
            response['user_status'] == 'active'
                ? UserProfileStatus.active
                : UserProfileStatus.inactive,
        userPreferences: userPreferences,
      );

      return AuthResult.success(user);
    } catch (e) {
      return _handleException(e, 'Get user profile');
    }
  }

  @override
  Future<AuthResult<User>> createUserProfile(User user) async {
    _logger.info('Creating user profile for: ${user.email}');
    try {
      final userData = {
        'credential_id': user.credentialId,
        'email': user.email,
        'phone': user.phone,
        'first_name': user.firstName,
        'last_name': user.lastName,
        'professional_role': user.professionalRole,
        'profile_photo_url': user.profilePhotoUrl,
        'user_status':
            user.userStatus == UserProfileStatus.active ? 'active' : 'inactive',
        'user_preferences': user.userPreferences,
      };

      final response = await supabaseWrapper.insert(
        table: 'users',
        data: userData,
      );

      _logger.info('User profile created successfully');

      final createdUser = User(
        id: response['id'].toString(),
        credentialId: response['credential_id'],
        email: response['email'],
        phone: response['phone'],
        firstName: response['first_name'],
        lastName: response['last_name'],
        professionalRole: response['professional_role'],
        profilePhotoUrl: response['profile_photo_url'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        userStatus:
            response['user_status'] == 'active'
                ? UserProfileStatus.active
                : UserProfileStatus.inactive,
        userPreferences:
            response['user_preferences'] is Map
                ? Map<String, dynamic>.from(response['user_preferences'])
                : {},
      );

      return AuthResult.success(createdUser);
    } catch (e) {
      return _handleException(e, 'Create user profile');
    }
  }

  @override
  Future<AuthResult<User>> updateUserProfile(User user) async {
    _logger.info('Updating user profile for: ${user.email}');
    try {
      final userData = {
        'email': user.email,
        'phone': user.phone,
        'first_name': user.firstName,
        'last_name': user.lastName,
        'professional_role': user.professionalRole,
        'profile_photo_url': user.profilePhotoUrl,
        'user_status':
            user.userStatus == UserProfileStatus.active ? 'active' : 'inactive',
        'user_preferences': user.userPreferences,
      };

      final response = await supabaseWrapper.update(
        table: 'users',
        data: userData,
        filterColumn: 'credential_id',
        filterValue: user.credentialId,
      );

      _logger.info('User profile updated successfully');

      final updatedUser = User(
        id: response['id'].toString(),
        credentialId: response['credential_id'],
        email: response['email'],
        phone: response['phone'],
        firstName: response['first_name'],
        lastName: response['last_name'],
        professionalRole: response['professional_role'],
        profilePhotoUrl: response['profile_photo_url'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        userStatus:
            response['user_status'] == 'active'
                ? UserProfileStatus.active
                : UserProfileStatus.inactive,
        userPreferences:
            response['user_preferences'] is Map
                ? Map<String, dynamic>.from(response['user_preferences'])
                : {},
      );

      return AuthResult.success(updatedUser);
    } catch (e) {
      return _handleException(e, 'Update user profile');
    }
  }

  @override
  Stream<AuthStatus> get authStateChanges => _authStateController.stream;

  @override
  Stream<UserCredential?> get userChanges => _userController.stream;

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authStateController.close();
    _userController.close();
    _logger.debug('SupabaseAuthRepository disposed');
  }
}

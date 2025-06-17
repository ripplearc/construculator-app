import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/interfaces/auth_service.dart';
import 'package:construculator/libraries/logging/interfaces/logger.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AuthServiceImpl implements IAuthService, Disposable {
  final IAuthNotifier _notifier;
  final IAuthRepository _repository;
  final Logger _logger = Modular.get<Logger>().tag('AuthService');
  
  // Track subscriptions for disposal
  StreamSubscription<AuthStatus>? _authStateSubscription;
  StreamSubscription<UserCredential?>? _userSubscription;

  AuthServiceImpl({
    required IAuthNotifier notifier,
    required IAuthRepository repository,
  }) : _notifier = notifier,
       _repository = repository {
    _logger.debug('Initializing auth service');
    _initializeListeners();
  }

  void _initializeListeners() {
    // Listen for authentication state changes from the repository
    _authStateSubscription = _repository.authStateChanges.listen(
      (status) {
        _logger.debug('Auth state changed: $status');
        
        // Forward auth state changes to all listeners
        _notifier.emitAuthStateChanged(status);
        
        // If authentication state changes to unauthenticated, emit logout
        if (status == AuthStatus.unauthenticated) {
          _notifier.emitLogout();
        }
      },
      onError: (error) {
        _logger.error('Unexpected error in auth state stream - repository should handle this', error);
        // Repository should handle all stream errors and convert them to appropriate AuthStatus
        // If we reach here, it means the repository error handling failed
        _notifier.emitAuthStateChanged(AuthStatus.connectionError);
      },
    );
    
    // Listen for user credential changes from the repository
    _userSubscription = _repository.userChanges.listen(
      (credentials) {
        if (credentials == null) {
          _logger.debug('User credentials cleared');
          return;
        }
        
        _logger.debug('User credentials updated: ${credentials.id}');
        
        // Just emit the credentials - let consumers fetch user profile when needed
        _notifier.emitLogin(credentials);
      },
      onError: (error) {
        _logger.error('Unexpected error in user credentials stream - repository should handle this', error);
        // Repository should handle all stream errors appropriately
        // If we reach here, it means the repository error handling failed
         _notifier.emitAuthStateChanged(AuthStatus.connectionError);
      },
    );

    // Check initial state
    _checkInitialState();
  }

  void _checkInitialState() {
    final isAuth = _repository.isAuthenticated();
    _logger.info(isAuth 
        ? 'User is already authenticated on initialization' 
        : 'No authenticated user on initialization');
    
    if (isAuth) {
      final credentials = _repository.getCurrentCredentials();
      if (credentials != null) {
        _notifier.emitLogin(credentials);
        _notifier.emitAuthStateChanged(AuthStatus.authenticated);
      }
    } else {
      _notifier.emitAuthStateChanged(AuthStatus.unauthenticated);
    }
  }

  @override
  Future<bool> loginWithEmail(String email, String password) async {
    _logger.info('Attempting login for user: $email');
    
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      _logger.warning('Login attempt with empty email or password');
      return false;
    }
    
    try {
      final result = await _repository.loginWithEmail(email, password);
      
      if (result.isSuccess && result.data != null) {
        _logger.info('Login successful for user: $email');
        return true;
      } else {
        _logger.warning('Login failed for user: $email - ${result.errorMessage}');
        return false;
      }
    } catch (e) {
      _logger.error('Exception during login', e);
      return false;
    }
  }

  @override
  Future<bool> registerWithEmail(String email, String password) async {
    _logger.info('Attempting registration for user: $email');
    
    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      _logger.warning('Registration attempt with empty email or password');
      return false;
    }
    
    try {
      final result = await _repository.registerWithEmail(email, password);
      
      if (result.isSuccess && result.data != null) {
        _logger.info('Registration successful for user: $email');
        return true;
      } else {
        _logger.warning('Registration failed: ${result.errorMessage}');
        return false;
      }
    } catch (e) {
      _logger.error('Exception during registration', e);
      return false;
    }
  }

  @override
  Future<bool> sendOtp(String address, OtpReceiver receiver) async {
    _logger.info('Sending OTP to: $address');
    try {
      final result = await _repository.sendOtp(address, receiver);
      
      if (result.isSuccess) {
        _logger.info('OTP sent successfully to: $address');
        return true;
      } else {
        _logger.warning('Failed to send OTP: ${result.errorMessage}');
        return false;
      }
    } catch (e) {
      _logger.error('Failed to send OTP with exception', e);
      return false;
    }
  }
  
  @override
  Future<bool> verifyOtp(String address, String otp, OtpReceiver receiver) async {
    _logger.info('Verifying OTP for: $address');
    try {
      final result = await _repository.verifyOtp(address, otp, receiver);
      
      if (result.isSuccess) {
        _logger.info('OTP verification successful for: $address');
        return true;
      } else {
        _logger.warning('OTP verification failed: ${result.errorMessage}');
        return false;
      }
    } catch (e) {
      _logger.error('OTP verification failed with exception', e);
      return false;
    }
  }

  @override
  Future<bool> resetPassword(String email) async {
    _logger.info('Initiating password reset for: $email');
    try {
      final result = await _repository.resetPassword(email);
      
      if (result.isSuccess) {
        _logger.info('Password reset email sent successfully to: $email');
        return true;
      } else {
        _logger.warning('Failed to send password reset email: ${result.errorMessage}');
        return false;
      }
    } catch (e) {
      _logger.error('Failed to send password reset email with exception', e);
      return false;
    }
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    _logger.info('Checking if email is registered: $email');
    try {
      final result = await _repository.isEmailRegistered(email);
      
      if (result.isSuccess) {
        final isRegistered = result.data ?? false;
        _logger.debug('Email registration check complete: $email - Registered: $isRegistered');
        return isRegistered;
      } else {
        _logger.warning('Failed to check email registration: ${result.errorMessage}');
        return false; // Default to false on error - safer to assume not registered
      }
    } catch (e) {
      _logger.error('Email registration check failed with exception', e);
      return false;
    }
  }

  @override
  Future<void> logout() async {
    _logger.info('Logging out user');
    try {
      final result = await _repository.logout();
      
      if (!result.isSuccess) {
        _logger.error('Logout failed: ${result.errorMessage}');
        throw Exception('Logout failed: ${result.errorMessage}');
      } else {
        _logger.info('Logout successful');
      }
    } catch (e) {
      _logger.error('Logout failed with exception', e);
      rethrow; // Consistent with original behavior
    }
  }

  @override
  bool isAuthenticated() {
    final isAuth = _repository.isAuthenticated();
    _logger.debug('Checking authentication status: $isAuth');
    return isAuth;
  }

  @override
  Future<User?> getUserInfo() async {
    _logger.debug('Getting current user info');
    final credentials = _repository.getCurrentCredentials();
    
    if (credentials == null) {
      _logger.info('No current user found');
      return null;
    }
    
    try {
      final profileResult = await _repository.getUserProfile(credentials.id);
      
      if (profileResult.isSuccess && profileResult.data != null) {
        _logger.debug('Current user profile retrieved successfully');
        return profileResult.data;
      } else {
        _logger.warning('Error getting user profile: ${profileResult.errorMessage}');
        // If profile wasn't found, emit setup profile event
        if (profileResult.errorType == AuthErrorType.userNotFound) {
          _logger.warning('User profile not found - need setup');
          _notifier.emitSetupProfile();
        }
        return null;
      }
    } catch (e) {
      _logger.error('Error getting current user profile', e);
      return null;
    }
  }

  @override
  Future<UserCredential?> getCurrentUser() async {
    _logger.debug('Getting current user credentials');
    return _repository.getCurrentCredentials();
  }

  @override
  Stream<AuthStatus> get authStateChanges => _repository.authStateChanges;

  @override
  void dispose() {
    _logger.debug('Disposing auth service');
    _authStateSubscription?.cancel();
    _userSubscription?.cancel();
  }
}

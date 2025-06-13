import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_service.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:flutter_modular/flutter_modular.dart';

class FakeAuthService implements AuthService, Disposable {
  final AuthNotifier _notifier;

  /// The controller for auth state changes
  final _authStateController = StreamController<AuthStatus>.broadcast();
  
  /// The controller for the current user
  bool _isAuthenticated = false;
  
  /// The currently authenticated user
  User? _currentUser;

  /// The currently authenticated user's credential
  UserCredential? _currentCredential;
  
  /// The flag to control if the login should succeed
  bool loginShouldSucceed = true;

  /// The flag to control if the OTP should succeed
  bool otpShouldSucceed = true;

  /// The flag to control if the reset password should succeed
  bool resetPasswordShouldSucceed = true;

  /// The flag to control if the email check should succeed
  bool emailCheckShouldSucceed = true;
  
  /// The list of login calls
  List<String> loginCalls = [];
  /// The list of OTP send calls
  List<String> otpSendCalls = [];
  /// The list of OTP verify calls
  List<String> otpVerifyCalls = [];
  /// The list of reset password calls
  List<String> resetPasswordCalls = [];
  /// The list of email check calls
  List<String> emailCheckCalls = [];
  /// The number of logout calls
  int logoutCallCount = 0;
  /// The number of get current user calls
  int getCurrentUserCallCount = 0;
  
  /// The set of emails that should be considered "registered"
  final Set<String> registeredEmails = {'registered@example.com'};
  
  FakeAuthService({
    required AuthNotifier notifier,
    bool initiallyAuthenticated = false,
  }) : _notifier = notifier {
    _isAuthenticated = initiallyAuthenticated;
    if (_isAuthenticated) {
      _setupAuthenticatedUser('test@example.com');
      _authStateController.add(AuthStatus.authenticated);
    } else {
      _authStateController.add(AuthStatus.unauthenticated);
    }
  }
  
  /// Sets up the authenticated user, sets the current credential and user
  void _setupAuthenticatedUser(String email) {
    _currentCredential = UserCredential(
      id: 'fake-credential-id',
      email: email,
      metadata: {'source': 'fake'},
      createdAt: DateTime.now(),
    );
    
    _currentUser = User(
      id: 'fake-id',
      credentialId: 'fake-credential-id',
      email: email,
      firstName: 'Test',
      lastName: 'User',
      professionalRole: 'fake-role-id',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userStatus: UserProfileStatus.active,
      userPreferences: {},
      profilePhotoUrl: null,
      phone: null,
    );
  }
  
  @override
  Future<bool> loginWithEmail(String email, String password) async {
    loginCalls.add('$email:$password');
    
    if (loginShouldSucceed) {
      _isAuthenticated = true;
      _setupAuthenticatedUser(email);
      _authStateController.add(AuthStatus.authenticated);
      _notifier.emitAuthStateChanged(AuthStatus.authenticated);
      return true;
    }
    return false;
  }
  
  @override
  Future<bool> registerWithEmail(String email, String password) async {
    loginCalls.add('register:$email:$password');
    
    if (loginShouldSucceed) {
      _isAuthenticated = true;
      _setupAuthenticatedUser(email);
      _authStateController.add(AuthStatus.authenticated);
      _notifier.emitAuthStateChanged(AuthStatus.authenticated);
      return true;
    }
    return false;
  }
  
  @override
  Future<bool> sendOtp(String address, OtpReceiver receiver) async {
    otpSendCalls.add('$address:$receiver');
    
    return otpShouldSucceed;
  }
  
  @override
  Future<bool> verifyOtp(String address, String otp, OtpReceiver receiver) async {
    otpVerifyCalls.add('$address:$otp:$receiver');
    
    if (otpShouldSucceed) {
      _isAuthenticated = true;
      _setupAuthenticatedUser(address);
      _authStateController.add(AuthStatus.authenticated);
      _notifier.emitAuthStateChanged(AuthStatus.authenticated);
      return true;
    }
    return false;
  }
  
  @override
  Future<bool> resetPassword(String email) async {
    resetPasswordCalls.add(email);
    
    return resetPasswordShouldSucceed;
  }
  
  @override
  Future<bool> isEmailRegistered(String email) async {
    emailCheckCalls.add(email);
    
    if (!emailCheckShouldSucceed) {
      return false; // Simulate a failure to check
    }
    
    return registeredEmails.contains(email);
  }
  
  @override
  Future<void> logout() async {
    logoutCallCount++;
    _isAuthenticated = false;
    _currentUser = null;
    _currentCredential = null;
    _authStateController.add(AuthStatus.unauthenticated);
    _notifier.emitLogout();
  }
  
  @override
  bool isAuthenticated() {
    return _isAuthenticated;
  }
  
  @override
  Future<UserCredential?> getCurrentUser() async {
    getCurrentUserCallCount++;
    return _currentCredential;
  }
  
  @override
  Stream<AuthStatus> get authStateChanges => _authStateController.stream;
  
  @override
  Future<User?> getUserInfo() async {
    return _currentUser;
  }
  
  /// Resets the fake service state
  void reset() {
    loginShouldSucceed = true;
    otpShouldSucceed = true;
    resetPasswordShouldSucceed = true;
    emailCheckShouldSucceed = true;
    loginCalls.clear();
    otpSendCalls.clear();
    otpVerifyCalls.clear();
    resetPasswordCalls.clear();
    emailCheckCalls.clear();
    logoutCallCount = 0;
    getCurrentUserCallCount = 0;
    _isAuthenticated = false;
    _currentUser = null;
    _currentCredential = null;
    _authStateController.add(AuthStatus.unauthenticated);
  }
  
  /// Sets the authenticated state for tests
  void setAuthenticated(bool value, {String? email}) {
    _isAuthenticated = value;
    if (value) {
      _setupAuthenticatedUser(email ?? 'test@example.com');
      _authStateController.add(AuthStatus.authenticated);
    } else {
      _currentUser = null;
      _currentCredential = null;
      _authStateController.add(AuthStatus.unauthenticated);
    }
  }
  
  @override
  void dispose() {
    _authStateController.close();
  }
} 
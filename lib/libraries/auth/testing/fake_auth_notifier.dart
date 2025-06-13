import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:flutter_modular/flutter_modular.dart';

class FakeAuthNotifier implements AuthNotifier, Disposable {
  /// The controller for login events
  final _loginController = StreamController<UserCredential>.broadcast();
  /// The controller for logout events
  final _logoutController = StreamController<void>.broadcast();
  /// The controller for auth state changes
  final _authStateController = StreamController<AuthStatus>.broadcast();
  /// The controller for setup profile events
  final _setupProfileController = StreamController<void>.broadcast();
  
  /// The list of login events
  final List<UserCredential> loginEvents = [];
  /// The list of logout events
  final List<void> logoutEvents = [];
  /// The list of auth state changes
  final List<AuthStatus> stateChangedEvents = [];
  /// The list of setup profile events
  final List<void> setupProfileEvents = [];
  
  // Control flag for auth state emission behavior
  bool shouldEmitAuthStateOnLogout = true;
  
  FakeAuthNotifier() {
    _loginController.stream.listen((user) => loginEvents.add(user));
    _logoutController.stream.listen((_) => logoutEvents.add(null));
    _authStateController.stream.listen((status) => stateChangedEvents.add(status));
    _setupProfileController.stream.listen((_) => setupProfileEvents.add(null));
  }
  
  @override
  Stream<UserCredential> get onLogin => _loginController.stream;
  
  @override
  Stream<void> get onLogout => _logoutController.stream;
  
  @override
  Stream<AuthStatus> get onAuthStateChanged => _authStateController.stream;
  
  @override
  void emitLogin(UserCredential user) {
    _loginController.add(user);
    _authStateController.add(AuthStatus.authenticated);
  }
  
  @override
  void emitLogout() {
    _logoutController.add(null);
  }
  
  @override
  void emitAuthStateChanged(AuthStatus status) {
    _authStateController.add(status);
  }
  
  @override
  void emitSetupProfile() {
    _setupProfileController.add(null);
    _authStateController.add(AuthStatus.authenticated);
  }
  
  @override
  Stream<void> get onSetupProfile => _setupProfileController.stream;
  
  /// Resets the notifier to its initial state
  void reset() {
    loginEvents.clear();
    logoutEvents.clear();
    stateChangedEvents.clear();
    setupProfileEvents.clear();
    shouldEmitAuthStateOnLogout = true;
  }
  
  @override
  void dispose() {
    _loginController.close();
    _logoutController.close();
    _authStateController.close();
    _setupProfileController.close();
  }
} 
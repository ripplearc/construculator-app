import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:flutter_modular/flutter_modular.dart';

class FakeAuthNotifier implements AuthNotifier, Disposable {
  final _loginController = StreamController<UserCredential>.broadcast();
  final _logoutController = StreamController<void>.broadcast();
  final _authStateController = StreamController<AuthStatus>.broadcast();
  final _setupProfileController = StreamController<void>.broadcast();
  
  // Test verification lists
  final List<UserCredential> loginEvents = [];
  final List<void> logoutEvents = [];
  final List<AuthStatus> stateChangedEvents = [];
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
import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'interfaces/auth_notifier.dart';

class AuthNotifierImpl implements IAuthNotifier, Disposable {
  final _loginController = StreamController<UserCredential>.broadcast();
  final _logoutController = StreamController<void>.broadcast();
  final _authStateController = StreamController<AuthStatus>.broadcast();
  final _setupProfileController = StreamController<void>.broadcast();
  @override
  Stream<UserCredential> get onLogin => _loginController.stream;

  @override
  Stream<void> get onSetupProfile => _setupProfileController.stream;

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
  void emitSetupProfile() {
    _setupProfileController.add(null);
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
  void dispose() {
    _loginController.close();
    _logoutController.close();
    _authStateController.close();
    _setupProfileController.close();
  }
} 
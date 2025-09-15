import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'interfaces/auth_notifier.dart';

class AuthNotifierImpl
    implements AuthNotifier, AuthNotifierController, Disposable {
  final _authStateController = StreamController<AuthState>.broadcast();
  final _profileStateController = StreamController<User?>.broadcast();
  @override
  Stream<AuthState> get onAuthStateChanged => _authStateController.stream;

  @override
  Stream<User?> get onUserProfileChanged => _profileStateController.stream;

  @override
  void emitAuthStateChanged(AuthState state) {
    _authStateController.add(state);
  }

  @override
  void dispose() {
    _profileStateController.close();
    _authStateController.close();
  }

  @override
  void emitUserProfileChanged(User? user) {
    _profileStateController.add(user);
  }
}

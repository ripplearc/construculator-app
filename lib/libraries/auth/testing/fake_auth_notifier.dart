import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// A fake implementation of [AuthNotifier] for testing purposes
class FakeAuthNotifier implements AuthNotifier, AuthNotifierController, Disposable {
  /// The controller for auth state changes
  final _authStateController = StreamController<AuthState>.broadcast();
  
  /// The controller for user profile changes
  final _userProfileController = StreamController<User?>.broadcast();
  
  /// The list of auth state changes
  final List<AuthState> stateChangedEvents = [];
  
  /// The list of user profile changes
  final List<User?> userProfileChangedEvents = [];
  
  /// Creates a new [FakeAuthNotifier]
  FakeAuthNotifier() {
    _authStateController.stream.listen((state) => stateChangedEvents.add(state));
    _userProfileController.stream.listen((user) => userProfileChangedEvents.add(user));
  }
  
  @override
  Stream<AuthState> get onAuthStateChanged => _authStateController.stream;
  
  @override
  Stream<User?> get onUserProfileChanged => _userProfileController.stream;
  
  @override
  void emitAuthStateChanged(AuthState state) {
    _authStateController.add(state);
  }
  
  @override
  void emitUserProfileChanged(User? user) {
    _userProfileController.add(user);
  }
  
  /// Resets the notifier to its initial state
  void reset() {
    stateChangedEvents.clear();
    userProfileChangedEvents.clear();
  }
  
  @override
  void dispose() {
    _authStateController.close();
    _userProfileController.close();
  }
} 
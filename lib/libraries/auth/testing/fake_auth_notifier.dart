import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier_controller.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// A fake implementation of [AuthNotifier] for testing purposes.
///
/// Records what it emits itself rather than through a listener of its own,
/// so [hasAuthStateListeners] and [hasUserProfileListeners] report the
/// code under test alone.
class FakeAuthNotifier
    implements AuthNotifier, AuthNotifierController, Disposable {
  final _authStateController = StreamController<AuthState>.broadcast();
  final _userProfileController = StreamController<User?>.broadcast();

  /// The list of auth state changes
  final List<AuthState> stateChangedEvents = [];

  /// The list of user profile changes
  final List<User?> userProfileChangedEvents = [];

  /// Whether anything still listens to [onAuthStateChanged]; false once
  /// every listener has cancelled, as a disposed consumer must.
  bool get hasAuthStateListeners => _authStateController.hasListener;

  /// Whether anything still listens to [onUserProfileChanged]; false once
  /// every listener has cancelled, as a disposed consumer must.
  bool get hasUserProfileListeners => _userProfileController.hasListener;

  @override
  Stream<AuthState> get onAuthStateChanged => _authStateController.stream;

  @override
  Stream<User?> get onUserProfileChanged => _userProfileController.stream;

  @override
  void emitAuthStateChanged(AuthState state) {
    stateChangedEvents.add(state);
    _authStateController.add(state);
  }

  @override
  void emitUserProfileChanged(User? user) {
    userProfileChangedEvents.add(user);
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

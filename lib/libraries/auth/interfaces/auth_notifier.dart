import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

/// Provides a way to notify other parts of the app about auth state changes.
///
/// [onLogin] is emitted when a user logs in.
/// [onLogout] is emitted when a user logs out.
/// [onAuthStateChanged] is emitted when the auth state changes.
/// [onSetupProfile] is emitted when a user needs to setup their profile.
/// [emitLogin] is used to emit a login event.
/// [emitLogout] is used to emit a logout event.
abstract class AuthNotifier {
  Stream<UserCredential> get onLogin;
  Stream<void> get onLogout;
  Stream<AuthStatus> get onAuthStateChanged;
  Stream<void> get onSetupProfile;
  void emitLogin(UserCredential user);
  void emitLogout();
  void emitAuthStateChanged(AuthStatus status);
  void emitSetupProfile();
} 
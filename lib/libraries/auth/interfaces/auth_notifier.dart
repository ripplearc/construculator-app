import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

/// Provides a way to notify other parts of the app about auth state changes.
abstract class AuthNotifier {
  /// Stream that emits a [UserCredential] when a user logs in.
  Stream<UserCredential> get onLogin;

  /// Stream that emits a [void] when a user logs out.
  Stream<void> get onLogout;

  /// Stream that emits a [AuthStatus] when the auth state changes.
  Stream<AuthStatus> get onAuthStateChanged;

  /// Stream that emits a [void] when a user needs to setup their profile.
  Stream<void> get onSetupProfile;

  /// Emits a login event.
  void emitLogin(UserCredential user);

  /// Emits a logout event.
  void emitLogout();

  /// Emits an auth state change event.
  void emitAuthStateChanged(AuthStatus status);
  
  /// Emits a setup profile event.
  void emitSetupProfile();
} 
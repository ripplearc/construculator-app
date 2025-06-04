import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

// Provides a way to notify other parts of the app about auth state changes.
abstract class AuthNotifier {
  Stream<UserCredential> get onLogin;
  Stream<void> get onLogout;
  Stream<AuthStatus> get onAuthStateChanged;
  // Consumers can listen to this stream to redirect to setup profile screen.
  Stream<void> get onSetupProfile;
  
  void emitLogin(UserCredential user);
  void emitLogout();
  void emitAuthStateChanged(AuthStatus status);
  // Sometimes creating a user profile might fail, if the auth library tries to read the profile info and fails, 
  // the consumers must be notified to setup their profile.
  void emitSetupProfile();
} 
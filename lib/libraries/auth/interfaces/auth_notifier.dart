import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

abstract class IAuthNotifier {
  Stream<UserCredential> get onLogin;
  Stream<void> get onLogout;
  Stream<AuthStatus> get onAuthStateChanged;
  Stream<void> get onSetupProfile;
  
  void emitLogin(UserCredential user);
  void emitLogout();
  void emitAuthStateChanged(AuthStatus status);
  void emitSetupProfile();
} 
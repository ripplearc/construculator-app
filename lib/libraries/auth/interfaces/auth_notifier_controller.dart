import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';

/// Provides a way to notify other parts of the app about auth state changes.
abstract class AuthNotifierController extends AuthNotifier {
  /// Emits an auth state change event.
  void emitAuthStateChanged(AuthState state);

  /// Emits a user profile changed event.
  void emitUserProfileChanged(User? user);
}

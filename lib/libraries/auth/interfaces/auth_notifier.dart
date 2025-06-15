import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

/// Provides a way to notify other parts of the app about auth state changes.
abstract class AuthNotifier {
  /// Stream that emits a [AuthState] when the auth state changes.
  /// When the user is authenticated, the [user] field will be populated with [UserCredential].
  /// If not, the [user] field will be null.
  /// Listners can log the user out if the [status] is [AuthStatus.unauthenticated].
  Stream<AuthState> get onAuthStateChanged;

  /// Stream that emits a [User] when user profle is updated
  /// If the user is not found, the stream will emit a null value.
  /// Listners can update user details if the user is found, else navigate to the profile setup screen.
  Stream<User?> get onUserProfileChanged;

  /// Emits an auth state change event.
  void emitAuthStateChanged(AuthState state);

  /// Emits a user profile changed event.
  void emitUserProfileChanged(User? user);
} 
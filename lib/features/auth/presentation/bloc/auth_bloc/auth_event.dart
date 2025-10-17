import 'package:construculator/libraries/auth/data/models/auth_user.dart';

/// Base class for all authentication events
sealed class AuthEvent {
  const AuthEvent();
}

/// Event triggered when authentication state changes
class AuthStateChanged extends AuthEvent {
  const AuthStateChanged();
}

/// Event triggered when user profile changes
class AuthUserProfileChanged extends AuthEvent {
  final User? user;
  
  const AuthUserProfileChanged(this.user);
}

/// Event triggered to initialize authentication state
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

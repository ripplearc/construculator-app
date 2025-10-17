import 'package:construculator/libraries/auth/data/models/auth_user.dart';

/// Base class for all authentication states
sealed class AuthState {
  const AuthState();
}

/// Initial state when the auth bloc is first created
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when authentication is in progress
class AuthLoadInProgress extends AuthState {
  const AuthLoadInProgress();
}

/// State when user is authenticated with profile data
class AuthLoadSuccess extends AuthState {
  final User? user;
  final String? avatarUrl;
  
  const AuthLoadSuccess({
    required this.user,
    this.avatarUrl,
  });
}

/// State when user is not authenticated
class AuthLoadUnauthenticated extends AuthState {
  const AuthLoadUnauthenticated();
}

/// State when authentication fails
class AuthLoadFailure extends AuthState {
  final String message;
  
  const AuthLoadFailure(this.message);
}

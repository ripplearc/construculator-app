import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

/// Represents the current authentication state of the application.
/// 
/// This model encapsulates the authentication status and user information
/// at any given point in time. It is used throughout the authentication
/// flow to track whether a user is authenticated or unauthenticated.
/// 
/// The [AuthState] is typically managed by authentication managers and
/// notifiers to provide a centralized way to track user authentication
/// status across the application.
/// 
/// Example usage:
/// ```dart
/// final authState = AuthState(
///   status: AuthStatus.authenticated,
///   user: UserCredential(...),
/// );
/// ```
class AuthState {
  /// The current authentication status indicating the state of the user.
  /// 
  /// This can be one of the following values:
  /// - [AuthStatus.authenticated]: User is successfully logged in
  /// - [AuthStatus.unauthenticated]: User is not logged in
  /// - [AuthStatus.connectionError]: Authentication process is in progress
  final AuthStatus status;

  /// The user credential information if the user is authenticated.
  /// 
  /// This contains user details such as email, user ID, and other
  /// authentication-related information. Will be null when the user
  /// is not authenticated or during loading states.
  final UserCredential? user;

  /// Creates an [AuthState] instance.
  /// 
  /// [status] is required and must be provided to indicate the current
  /// authentication state. [user] is optional and should only be provided
  /// when the user is authenticated.
  /// 
  /// Parameters:
  /// - [status]: The current authentication status
  /// - [user]: Optional user credential information
  AuthState({required this.status, this.user});
}
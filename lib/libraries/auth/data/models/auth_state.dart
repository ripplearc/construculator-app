// coverage:ignore-file
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

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
@freezed
sealed class AuthState with _$AuthState {
  /// Allows defining custom getters/methods
  const AuthState._();

  /// Creates an [AuthState] instance.
  ///
  /// [status] is required and must be provided to indicate the current
  /// authentication state. [user] is optional and should only be provided
  /// when the user is authenticated.
  ///
  /// Parameters:
  /// - [status]: The current authentication status
  /// - [user]: Optional user credential information
  const factory AuthState({
    /// The current authentication status indicating the state of the user.
    ///
    /// This can be one of the following values:
    /// - [AuthStatus.authenticated]: User is successfully logged in
    /// - [AuthStatus.unauthenticated]: User is not logged in
    /// - [AuthStatus.connectionError]: Authentication process is in progress
    required AuthStatus status,

    /// The user credential information if the user is authenticated.
    ///
    /// This contains user details such as email, user ID, and other
    /// authentication-related information. Will be null when the user
    /// is not authenticated or during loading states.
    UserCredential? user,
  }) = _AuthState;

  /// Creates an [AuthState] from a JSON object
  factory AuthState.fromJson(Map<String, dynamic> json) =>
      _$AuthStateFromJson(json);
}

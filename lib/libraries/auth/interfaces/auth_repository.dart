import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';

/// Interface that abstracts authentication provider operations.
/// This allows the auth service to work with any authentication backend.
abstract class AuthRepository {
  /// Used to get the current user's credentials
  UserCredential? getCurrentCredentials();

  /// Used to update the user's email
  ///
  /// [email] - The user's new email address.
  ///
  /// Returns an [UserCredential] with the updated user credentials.
  Future<UserCredential?> updateUserEmail(String email);

  /// Used to update the user's password
  ///
  /// [password] - The user's new password.
  ///
  /// Returns an [UserCredential] with the updated user credentials.
  Future<UserCredential?> updateUserPassword(String password);

  /// Used to get the user profile
  ///
  /// [credentialId] - The credential ID of the user.
  ///
  /// Returns an [User] with the user profile or null if the user is not found.
  Future<User?> getUserProfile(String credentialId);

  /// Used to create a new user profile
  ///
  /// [user] - The user profile to create.
  ///
  /// Returns an [User] with the created user profile.
  Future<User?> createUserProfile(User user);

  /// Used to update the user profile
  ///
  /// [user] - The user profile to update.
  ///
  /// Returns an [User] with the updated user profile.
  Future<User?> updateUserProfile(User user);
}

import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

/// Interface that abstracts authentication provider operations.
/// This allows the auth service to work with any authentication backend.
abstract class AuthRepository {
  /// Used to get the current user's credentials
  UserCredential? getCurrentCredentials();

  /// Used to get the user profile
  Future<AuthResult<User>> getUserProfile(String credentialId);

  /// Used to create a new user profile
  Future<AuthResult<User>> createUserProfile(User user);

  /// Used to update the user profile
  Future<AuthResult<User>> updateUserProfile(User user);
}
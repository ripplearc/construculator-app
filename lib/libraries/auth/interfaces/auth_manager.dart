import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/models/professional_role.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';

/// Interface for shared auth library, provides functionality
/// for user authentication and basic profile management.
abstract class AuthManager {
  /// Used to get the current user's credentials
  ///
  /// Returns an [AuthResult] of [UserCredential] with the current user's credentials.
  AuthResult<UserCredential?> getCurrentCredentials();

  /// Used to get the user profile
  ///
  /// [credentialId] - The credential ID of the user.
  ///
  /// Returns an [AuthResult] of [User] with the user profile or null if the user is not found.
  Future<AuthResult<User?>> getUserProfile(String credentialId);

  /// Used to create a new user profile
  ///
  /// [user] - The user profile to create.
  ///
  /// Returns an [AuthResult] of [User] with the created user profile.
  Future<AuthResult<User?>> createUserProfile(User user);

  /// Used to update the user profile
  ///
  /// [user] - The user profile to update.
  ///
  /// Returns an [AuthResult] of [User] with the updated user profile.
  Future<AuthResult<User?>> updateUserProfile(User user);

  /// Used to update the user password
  ///
  /// [password] - The new password of the user.
  ///
  /// Returns an [AuthResult] of [UserCredential] with the updated user password.
  Future<AuthResult<UserCredential?>> updateUserPassword(String password);

  /// Used to update the user email
  ///
  /// [email] - The new email of the user.
  ///
  /// Returns an [AuthResult] of [UserCredential] with the updated user email.
  Future<AuthResult<UserCredential?>> updateUserEmail(String email);

  /// Logs in a user with email and password.
  ///
  /// [email] - The email of the user.
  /// [password] - The password of the user.
  ///
  /// Returns an [AuthResult] of [UserCredential] with the result of the login.
  Future<AuthResult<UserCredential>> loginWithEmail(
    String email,
    String password,
  );

  /// Registers a new user with email and password.
  ///
  /// [email] - The email of the user.
  /// [password] - The password of the user.
  ///
  /// Returns an [AuthResult] of [UserCredential] with the result of the registration.
  Future<AuthResult<UserCredential>> registerWithEmail(
    String email,
    String password,
  );

  /// Sends a 6-digit OTP (One-Time Password) to the specified address.
  ///
  /// [address] - The address(email or phone) to send the OTP to.
  /// [receiver] - The receiver of the OTP of type [OtpReceiver].
  ///
  /// Returns an [AuthResult] with the status of the OTP sending.
  Future<AuthResult> sendOtp(String address, OtpReceiver receiver);

  /// Verifies an OTP code sent to an address.
  ///
  /// [address] - The address(email or phone) to send the OTP to.
  /// [otp] - The OTP code to verify.
  /// [receiver] - The receiver of the OTP of type [OtpReceiver].
  ///
  /// Returns an [AuthResult] of [UserCredential] with the result of the OTP verification.
  Future<AuthResult<UserCredential>> verifyOtp(
    String address,
    String otp,
    OtpReceiver receiver,
  );

  /// Sends a password reset email to the user.
  ///
  /// [email] - The email of the user.
  ///
  /// Returns a bool [AuthResult] with the result of the password reset.
  Future<AuthResult<bool>> resetPassword(String email);

  /// Checks if an email is already registered.
  ///
  /// [email] - The email of the user.
  ///
  /// Returns a bool [AuthResult] with the result of the email registration check.
  Future<AuthResult<bool>> isEmailRegistered(String email);

  /// Logs out the current user.
  Future<AuthResult<void>> logout();

  /// Checks if a user is currently authenticated.
  bool isAuthenticated();

  /// Returns an [AuthResult] of [List<ProfessionalRole>] with the list of professional roles.
  Future<AuthResult<List<ProfessionalRole>>> getProfessionalRoles();
}

// ignore_for_file: no_direct_instantiation
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/models/professional_role.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';

const String kStubTestUserId = 'test-user-id';

class StubAuthManager implements AuthManager {
  final String? userId;

  const StubAuthManager({this.userId = kStubTestUserId});

  @override
  AuthResult<UserCredential?> getCurrentCredentials() {
    if (userId == null) return const AuthResult.success(null);
    return AuthResult.success(
      UserCredential(
        id: userId!,
        email: 'test@example.com',
        metadata: const {},
        createdAt: DateTime(2025, 1, 1),
      ),
    );
  }

  @override
  Future<AuthResult<UserCredential>> loginWithEmail(
    String email,
    String password,
  ) => throw UnimplementedError();

  @override
  Future<AuthResult<UserCredential>> registerWithEmail(
    String email,
    String password,
  ) => throw UnimplementedError();

  @override
  Future<AuthResult> sendOtp(String address, OtpReceiver receiver) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<UserCredential>> verifyOtp(
    String address,
    String otp,
    OtpReceiver receiver,
  ) => throw UnimplementedError();

  @override
  Future<AuthResult<bool>> resetPassword(String email) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<bool>> isEmailRegistered(String email) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<void>> logout() => throw UnimplementedError();

  @override
  bool isAuthenticated() => userId != null;

  @override
  Future<AuthResult<User?>> getUserProfile(String credentialId) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<User?>> createUserProfile(User user) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<User?>> updateUserProfile(User user) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<UserCredential?>> updateUserPassword(String password) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<UserCredential?>> updateUserEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<AuthResult<List<ProfessionalRole>>> getProfessionalRoles() =>
      throw UnimplementedError();
}

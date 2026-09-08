import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/models/professional_role.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/router/guards/no_auth_guard.dart';
import 'package:construculator/libraries/router/routes/shell_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubAuthManager implements AuthManager {
  bool authenticated;
  _StubAuthManager({required this.authenticated});

  @override
  bool isAuthenticated() => authenticated;

  @override
  AuthResult<UserCredential?> getCurrentCredentials() => throw UnimplementedError();
  @override
  Future<AuthResult<User?>> getUserProfile(String credentialId) => throw UnimplementedError();
  @override
  Future<AuthResult<User?>> createUserProfile(User user) => throw UnimplementedError();
  @override
  Future<AuthResult<User?>> updateUserProfile(User user) => throw UnimplementedError();
  @override
  Future<AuthResult<UserCredential?>> updateUserPassword(String password) => throw UnimplementedError();
  @override
  Future<AuthResult<UserCredential?>> updateUserEmail(String email) => throw UnimplementedError();
  @override
  Future<AuthResult<UserCredential>> loginWithEmail(String email, String password) => throw UnimplementedError();
  @override
  Future<AuthResult<UserCredential>> registerWithEmail(String email, String password) => throw UnimplementedError();
  @override
  Future<AuthResult> sendOtp(String address, OtpReceiver receiver) => throw UnimplementedError();
  @override
  Future<AuthResult<UserCredential>> verifyOtp(String address, String otp, OtpReceiver receiver) => throw UnimplementedError();
  @override
  Future<AuthResult<bool>> resetPassword(String email) => throw UnimplementedError();
  @override
  Future<AuthResult<bool>> isEmailRegistered(String email) => throw UnimplementedError();
  @override
  Future<AuthResult<void>> logout() => throw UnimplementedError();
  @override
  Future<AuthResult<List<ProfessionalRole>>> getProfessionalRoles() => throw UnimplementedError();
}

class _NoAuthGuardTestModule extends Module {
  final bool isAuthenticated;
  _NoAuthGuardTestModule({required this.isAuthenticated});

  @override
  void binds(Injector i) {
    i.add<AuthManager>(() => _StubAuthManager(authenticated: isAuthenticated));
  }
}

void main() {
  // ignore: no_direct_instantiation
  final route = ChildRoute('/', child: (_) => const SizedBox());

  tearDown(Modular.destroy);

  group('NoAuthGuard', () {
    test('redirectTo is shellRoute', () {
      Modular.init(_NoAuthGuardTestModule(isAuthenticated: false));
      final guard = NoAuthGuard(() => Modular.get<AuthManager>());
      expect(guard.redirectTo, equals(shellRoute));
    });

    test('canActivate returns true when user is not authenticated', () async {
      Modular.init(_NoAuthGuardTestModule(isAuthenticated: false));
      final guard = NoAuthGuard(() => Modular.get<AuthManager>());
      expect(await guard.canActivate('/', route), isTrue);
    });

    test('canActivate returns false when user is authenticated', () async {
      Modular.init(_NoAuthGuardTestModule(isAuthenticated: true));
      final guard = NoAuthGuard(() => Modular.get<AuthManager>());
      expect(await guard.canActivate('/', route), isFalse);
    });
  });
}

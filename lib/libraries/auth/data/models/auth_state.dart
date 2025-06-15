import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

class AuthState {
  final AuthStatus status;
  final UserCredential? user;

  AuthState({required this.status, this.user});
}
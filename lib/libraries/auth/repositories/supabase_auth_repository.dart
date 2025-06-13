import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SupabaseAuthRepositoryImpl implements AuthRepository {
  final SupabaseWrapper supabaseWrapper;
  final _logger = AppLogger().tag('SupabaseAuthRepositoryImpl');

  SupabaseAuthRepositoryImpl({required this.supabaseWrapper});

  UserCredential _mapSupabaseUserToCredential(supabase.User user) {
    return UserCredential(
      id: user.id,
      email: user.email ?? '',
      metadata: {...user.appMetadata, ...user.userMetadata ?? {}},
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  AuthResult<T> _handleException<T>(dynamic error, String operation) {
    _logger.error('$operation failed with error', error);

    if (error is SocketException) {
      return AuthResult.failure(
        'Network connection failed. Please check your internet connection.',
        AuthErrorType.networkError,
      );
    }

    if (error is TimeoutException) {
      return AuthResult.failure(
        'Request timed out. Please try again.',
        AuthErrorType.timeout,
      );
    }

    if (error is supabase.AuthException) {
      final code = SupabaseAuthErrorCode.fromCode(error.code ?? 'unknown');
      return AuthResult.failure(code.message, authErrorCodeToType(code));
    }

    if (error is supabase.PostgrestException) {
      final code = PostgresErrorCode.fromCode(error.code ?? 'unknown');
      return AuthResult.failure(code.message, postgresErrorCodeToType(code));
    }

    return AuthResult.failure(error.toString(), AuthErrorType.serverError);
  }

  @override
  UserCredential? getCurrentCredentials() {
    final supaUser = supabaseWrapper.currentUser;
    if (supaUser == null) return null;
    return _mapSupabaseUserToCredential(supaUser);
  }

  @override
  Future<AuthResult<User>> getUserProfile(String credentialId) async {
    _logger.debug('Fetching user profile for credential ID: $credentialId');
    try {
      final response = await supabaseWrapper.selectSingle(
        table: 'users',
        filterColumn: 'credential_id',
        filterValue: credentialId,
      );

      if (response == null) {
        _logger.warning(
          'No user profile found for credential ID: $credentialId',
        );
        return AuthResult.failure(
          'User profile not found',
          AuthErrorType.userNotFound,
        );
      }

      _logger.debug('Successfully retrieved user profile');

      final userPreferences = _parseJsonBToMap(
        response['user_preferences'],
      );

      final user = User(
        id: response['id'].toString(),
        credentialId: response['credential_id'],
        email: response['email'],
        phone: response['phone'],
        firstName: response['first_name'],
        lastName: response['last_name'],
        professionalRole: response['professional_role'],
        profilePhotoUrl: response['profile_photo_url'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        userStatus:
            response['user_status'] == 'active'
                ? UserProfileStatus.active
                : UserProfileStatus.inactive,
        userPreferences: userPreferences,
      );

      return AuthResult.success(user);
    } catch (e) {
      return _handleException(e, 'Get user profile');
    }
  }

  @override
  Future<AuthResult<User>> createUserProfile(User user) async {
    _logger.info('Creating user profile for: ${user.email}');
    try {
      final userData = {
        'credential_id': user.credentialId,
        'email': user.email,
        'phone': user.phone,
        'first_name': user.firstName,
        'last_name': user.lastName,
        'professional_role': user.professionalRole,
        'profile_photo_url': user.profilePhotoUrl,
        'user_status':
            user.userStatus == UserProfileStatus.active ? 'active' : 'inactive',
        'user_preferences': user.userPreferences,
      };

      final response = await supabaseWrapper.insert(
        table: 'users',
        data: userData,
      );

      _logger.info('User profile created successfully');

      final createdUser = User(
        id: response['id'].toString(),
        credentialId: response['credential_id'],
        email: response['email'],
        phone: response['phone'],
        firstName: response['first_name'],
        lastName: response['last_name'],
        professionalRole: response['professional_role'],
        profilePhotoUrl: response['profile_photo_url'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        userStatus:
            response['user_status'] == 'active'
                ? UserProfileStatus.active
                : UserProfileStatus.inactive,
        userPreferences:
            response['user_preferences'] is Map
                ? Map<String, dynamic>.from(response['user_preferences'])
                : {},
      );

      return AuthResult.success(createdUser);
    } catch (e) {
      return _handleException(e, 'Create user profile');
    }
  }

  @override
  Future<AuthResult<User>> updateUserProfile(User user) async {
    _logger.info('Updating user profile for: ${user.email}');
    try {
      final userData = {
        'email': user.email,
        'phone': user.phone,
        'first_name': user.firstName,
        'last_name': user.lastName,
        'professional_role': user.professionalRole,
        'profile_photo_url': user.profilePhotoUrl,
        'user_status':
            user.userStatus == UserProfileStatus.active ? 'active' : 'inactive',
        'user_preferences': user.userPreferences,
      };

      final response = await supabaseWrapper.update(
        table: 'users',
        data: userData,
        filterColumn: 'credential_id',
        filterValue: user.credentialId,
      );

      _logger.info('User profile updated successfully');

      final updatedUser = User(
        id: response['id'].toString(),
        credentialId: response['credential_id'],
        email: response['email'],
        phone: response['phone'],
        firstName: response['first_name'],
        lastName: response['last_name'],
        professionalRole: response['professional_role'],
        profilePhotoUrl: response['profile_photo_url'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        userStatus:
            response['user_status'] == 'active'
                ? UserProfileStatus.active
                : UserProfileStatus.inactive,
        userPreferences:
            response['user_preferences'] is Map
                ? Map<String, dynamic>.from(response['user_preferences'])
                : {},
      );

      return AuthResult.success(updatedUser);
    } catch (e) {
      return _handleException(e, 'Update user profile');
    }
  }

  Map<String, dynamic> _parseJsonBToMap(jsonB) {
    Map<String, dynamic> jsonMap = {};
    if (jsonB != null) {
      if (jsonB is Map) {
        jsonMap = Map<String, dynamic>.from(jsonB);
      } else if (jsonB is String) {
        jsonMap = jsonDecode(jsonB);
      }
    }
    return jsonMap;
  }
}

import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SupabaseRepositoryImpl implements AuthRepository {
  final SupabaseWrapper supabaseWrapper;
  final _logger = AppLogger().tag('SupabaseRepositoryImpl');

  SupabaseRepositoryImpl({required this.supabaseWrapper});

  UserCredential _mapSupabaseUserToCredential(supabase.User user) {
    return UserCredential(
      id: user.id,
      email: user.email ?? '',
      metadata: {...user.appMetadata, ...user.userMetadata ?? {}},
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  @override
  UserCredential? getCurrentCredentials() {
    final supaUser = supabaseWrapper.currentUser;
    if (supaUser == null) return null;
    return _mapSupabaseUserToCredential(supaUser);
  }

  @override
  Future<User?> getUserProfile(String credentialId) async {
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
        return null;
      }

      _logger.debug('Successfully retrieved user profile');
      final user = User.fromJson(response);

      return user;
    } catch (e) {
      _logger.error('Error getting user profile: $e');
      rethrow;
    }
  }

  @override
  Future<User?> createUserProfile(User user) async {
    _logger.info('Creating user profile for: ${user.email}');
    try {
      final response = await supabaseWrapper.insert(
        table: 'users',
        data: user.toJson(),
      );

      _logger.info('User profile created successfully');

      final createdUser = User.fromJson(response);

      return createdUser;
    } catch (e) {
      _logger.error('Error creating user profile: $e');
      rethrow;
    }
  }

  @override
  Future<User?> updateUserProfile(User user) async {
    _logger.info('Updating user profile for: ${user.email}');
    try {
      final response = await supabaseWrapper.update(
        table: 'users',
        data: user.toJson(),
        filterColumn: 'credential_id',
        filterValue: user.credentialId,
      );

      _logger.info('User profile updated successfully');

      return User.fromJson(response);
    } catch (e) {
      _logger.error('Error updating user profile: $e');
      rethrow;
    }
  }

  @override
  Future<UserCredential?> updateUserEmail(String email) async {
    _logger.info('Updating user email to: $email');
    try {
      final response = await supabaseWrapper.updateUser(
        supabase.UserAttributes(email: email),
      );
      final user = response.user;
      if (user == null) {
        _logger.warning('No user found for email update: $email');
        return null;
      }
      return _mapSupabaseUserToCredential(user);
    } catch (e) {
      _logger.error('Error updating user email: $e');
      rethrow;
    }
  }

  @override
  Future<UserCredential?> updateUserPassword(String password) async {
    _logger.info('Updating user password');
    try {
      final response = await supabaseWrapper.updateUser(
        supabase.UserAttributes(password: password),
      );
      final user = response.user;
      if (user == null) {
        _logger.warning('No user found for password update');
        return null;
      }
      return _mapSupabaseUserToCredential(user);
    } catch (e) {
      _logger.error('Error updating user password: $e');
      rethrow;
    }
  }
}

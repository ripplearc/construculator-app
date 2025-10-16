import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:stack_trace/stack_trace.dart';

/// A fake implementation of AuthRepository for testing purposes.
class FakeAuthRepository implements AuthRepository {
  // Currently authenticated user
  UserCredential? _currentUser;

  // Map of user profiles, keyed by credentialId
  final Map<String, User> _userProfiles = {};

  // Error message to be returned on exceptions
  String? _errorMessage;

  // Flag to control if the auth should succeed
  bool _authShouldSucceed = true;

  /// Flag to control if a null user profile should be returned
  bool returnNullUserProfile = false;

  /// Flag to control if a get user profile should throw an exception
  bool shouldThrowOnGetUserProfile = false;

  /// Exception message to be returned on exceptions
  String exceptionMessage = 'Test exception';

  /// List of get user profile calls
  final List<String> getUserProfileCalls = [];

  /// List of create profile calls
  final List<User> createProfileCalls = [];

  /// List of update profile calls
  final List<User> updateProfileCalls = [];

  /// List of update email calls
  final List<String> updateEmailCalls = [];

  /// List of update password calls
  final List<String> updatePasswordCalls = [];

  /// Count of get current user calls
  int getCurrentUserCallCount = 0;

  final Clock _clock;

  /// Constructor for fake auth repository
  FakeAuthRepository({required Clock clock}) : _clock = clock;

  /// Sets the current user credentials for testing
  void setCurrentCredentials(UserCredential credentials) {
    _currentUser = credentials;
  }

  /// Configures the response behavior for the auth operations
  void setAuthResponse({bool succeed = true, String? errorMessage}) {
    _authShouldSucceed = succeed;
    _errorMessage = errorMessage;
  }

  /// Sets up fake user profiles for testing
  void setUserProfile(User user) {
    final credentialId = user.credentialId;
    if (credentialId == null) {
      throw ServerException(
        Trace.current(),
        Exception('Credential ID is required'),
      );
    }
    _userProfiles[credentialId] = user;
  }

  @override
  UserCredential? getCurrentCredentials() {
    if (!_authShouldSucceed) {
      throw ServerException(Trace.current(), Exception(exceptionMessage));
    }
    getCurrentUserCallCount++;
    return _currentUser;
  }

  @override
  Future<UserCredential?> updateUserEmail(String email) async {
    updateEmailCalls.add(email);

    if (!_authShouldSucceed) {
      throw ServerException(Trace.current(), Exception(_errorMessage));
    }

    if (_currentUser == null) {
      return null;
    }

    final updatedCredential = UserCredential(
      id: _currentUser?.id ?? '',
      email: email,
      metadata: _currentUser?.metadata ?? {},
      createdAt: _currentUser?.createdAt ?? _clock.now(),
    );

    _currentUser = updatedCredential;
    return updatedCredential;
  }

  @override
  Future<UserCredential?> updateUserPassword(String password) async {
    updatePasswordCalls.add(password);

    if (!_authShouldSucceed) {
      throw ServerException(Trace.current(), Exception(_errorMessage));
    }

    if (_currentUser == null) {
      return null;
    }

    final metadata = Map<String, dynamic>.from(_currentUser?.metadata ?? {});
    metadata['password'] = password;

    final updatedCredential = UserCredential(
      id: _currentUser?.id ?? '',
      email: _currentUser?.email ?? '',
      metadata: metadata,
      createdAt: _currentUser?.createdAt ?? _clock.now(),
    );

    _currentUser = updatedCredential;
    return updatedCredential;
  }

  @override
  Future<User?> getUserProfile(String userId) async {
    getUserProfileCalls.add(userId);

    if (shouldThrowOnGetUserProfile) {
      throw ServerException(Trace.current(), Exception(exceptionMessage));
    }

    if (returnNullUserProfile) {
      return null;
    }

    return _userProfiles[userId];
  }

  @override
  Future<User?> createUserProfile(User user) async {
    createProfileCalls.add(user);

    if (!_authShouldSucceed) {
      throw ServerException(Trace.current(), Exception(_errorMessage));
    }

    final createdUser = user.copyWith(
      id: 'profile-${user.email.split('@')[0]}',
      createdAt: _clock.now(),
      updatedAt: _clock.now(),
    );

    final credentialId = user.credentialId;
    if (credentialId == null) {
      throw ServerException(
        Trace.current(),
        Exception('Credential ID is required'),
      );
    }
    _userProfiles[credentialId] = createdUser;
    return createdUser;
  }

  @override
  Future<User?> updateUserProfile(User user) async {
    updateProfileCalls.add(user);

    if (!_authShouldSucceed && _errorMessage != null) {
      throw ServerException(Trace.current(), Exception(_errorMessage));
    }

    final credentialId = user.credentialId;
    if (credentialId == null) {
      throw ServerException(
        Trace.current(),
        Exception('Credential ID is required'),
      );
    }

    if (!_userProfiles.containsKey(credentialId)) {
      return null;
    }

    final updatedUser = user.copyWith(updatedAt: _clock.now());
    _userProfiles[credentialId] = updatedUser;
    return updatedUser;
  }
}

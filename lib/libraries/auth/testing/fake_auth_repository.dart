import 'dart:async';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';

/// A fake implementation of AuthRepository for testing purposes.
class FakeAuthRepository implements AuthRepository {
  
  /// Currently authenticated user
  UserCredential? _currentUser;

  /// Map of user profiles, keyed by credentialId
  final Map<String, User> _userProfiles = {};

  /// Error message to be returned on exceptions
  String? _errorMessage;

  /// Flag to control if the auth should succeed
  bool _authShouldSucceed = true;

  /// Flag to control if a null user profile should be returned
  bool returnNullUserProfile = false;

  /// Flag to control if a success result with null data should be returned
  bool returnSuccessWithNullData = false;

  /// Flag to control if a success result with null user profile should be returned
  bool returnSuccessWithNullUserProfile = false;

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

  /// Count of get current user calls
  int getCurrentUserCallCount = 0;

  
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
    _userProfiles[user.credentialId] = user;
  }

  @override
  UserCredential? getCurrentCredentials() {
    getCurrentUserCallCount++;
    return _currentUser;
  }
  
  @override
  Future<AuthResult<User>> getUserProfile(String userId) async {
    getUserProfileCalls.add(userId);
    
    if (shouldThrowOnGetUserProfile) {
      throw Exception(exceptionMessage);
    }
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to get user profile', AuthErrorType.serverError);
    }
    
    if (returnSuccessWithNullUserProfile) {
      return AuthResult.success(null);
    }
    
    if (returnNullUserProfile) {
      return AuthResult.failure('User profile not found', AuthErrorType.userNotFound);
    }
    
    final profile = _userProfiles[userId];
    
    if (profile != null) {
      return AuthResult.success(profile);
    } else {
      return AuthResult.failure('User profile not found', AuthErrorType.userNotFound);
    }
  }
  
  @override
  Future<AuthResult<User>> createUserProfile(User user) async {
    createProfileCalls.add(user);
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to create user profile', AuthErrorType.serverError);
    }
    
    final createdUser = User(
      id: 'profile-${user.email.split('@')[0]}',
      credentialId: user.credentialId,
      email: user.email,
      phone: user.phone,
      firstName: user.firstName,
      lastName: user.lastName,
      professionalRole: user.professionalRole,
      profilePhotoUrl: user.profilePhotoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userStatus: user.userStatus,
      userPreferences: user.userPreferences,
    );
    
    _userProfiles[user.credentialId] = createdUser;
    return AuthResult.success(createdUser);
  }
  
  @override
  Future<AuthResult<User>> updateUserProfile(User user) async {
    updateProfileCalls.add(user);
    
    if (!_authShouldSucceed) {
      return AuthResult.failure(_errorMessage ?? 'Failed to update user profile', AuthErrorType.serverError);
    }
    
    if (!_userProfiles.containsKey(user.credentialId)) {
      return AuthResult.failure('User profile not found', AuthErrorType.userNotFound);
    }
    
    final updatedUser = User(
      id: user.id,
      credentialId: user.credentialId,
      email: user.email,
      phone: user.phone,
      firstName: user.firstName,
      lastName: user.lastName,
      professionalRole: user.professionalRole,
      profilePhotoUrl: user.profilePhotoUrl,
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
      userStatus: user.userStatus,
      userPreferences: user.userPreferences,
    );
    
    _userProfiles[user.credentialId] = updatedUser;
    return AuthResult.success(updatedUser);
  }
} 
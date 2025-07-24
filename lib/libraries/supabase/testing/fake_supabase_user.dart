// coverage:ignore-file

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:construculator/libraries/annotations/data_model.dart';

/// A fake implementation of [supabase.User] for testing purposes
@dataModel
class FakeUser implements supabase.User {
  /// The supabase user id
  @override
  final String id;
  
  /// The supabase user email
  @override
  final String? email;
  
  /// The supabase user created at
  @override
  final String createdAt;
  
  /// The supabase user app metadata
  @override
  final Map<String, dynamic> appMetadata;
  
  /// The supabase user metadata
  @override
  final Map<String, dynamic>? userMetadata;

  /// Creates a new [FakeUser]
  FakeUser({
    required this.id,
    this.email,
    required this.createdAt,
    this.appMetadata = const {},
    this.userMetadata,
  });

  /// Creates a new [FakeUser] with the given properties
  FakeUser copyWith({
    String? id,
    String? email,
    String? createdAt,
    Map<String, dynamic>? appMetadata,
    Map<String, dynamic>? userMetadata,
  }) {
    return FakeUser(
      id: id ?? this.id,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      appMetadata: appMetadata ?? this.appMetadata,
      userMetadata: userMetadata ?? this.userMetadata,
    );
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
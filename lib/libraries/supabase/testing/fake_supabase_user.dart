// coverage:ignore-file

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:construculator/libraries/annotations/data_model.dart';

/// Fake implementation of supabase.User
@dataModel
class FakeUser implements supabase.User {
  @override
  final String id;
  
  @override
  final String? email;
  
  @override
  final String createdAt;
  
  @override
  final Map<String, dynamic> appMetadata;
  
  @override
  final Map<String, dynamic>? userMetadata;

  FakeUser({
    required this.id,
    this.email,
    required this.createdAt,
    this.appMetadata = const {},
    this.userMetadata,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
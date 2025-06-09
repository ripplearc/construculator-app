import 'package:construculator/libraries/supabase/testing/fake_supabase_client.dart';
import 'package:construculator/libraries/config/interfaces/supabase_initializer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake implementation of SupabaseInitializer for testing
class FakeSupabaseInitializer implements SupabaseInitializer {
  bool shouldThrowOnInitialize = false;
  String? initializeErrorMessage;
  String? lastUrl;
  String? lastAnonKey;
  bool? lastDebugFlag;
  late FakeSupabaseClient _fakeClient;

  FakeSupabaseInitializer() {
    _fakeClient = FakeSupabaseClient();
  }

  @override
  Future<SupabaseClient> initialize({
    required String url,
    required String anonKey,
    bool debug = false,
  }) async {
    if (shouldThrowOnInitialize) {
      throw Exception(initializeErrorMessage ?? 'Failed to initialize Supabase');
    }

    lastUrl = url;
    lastAnonKey = anonKey;
    lastDebugFlag = debug;

    return _fakeClient;
  }

  // Test helper methods
  void reset() {
    shouldThrowOnInitialize = false;
    initializeErrorMessage = null;
    lastUrl = null;
    lastAnonKey = null;
    lastDebugFlag = null;
  }

  FakeSupabaseClient get fakeClient => _fakeClient;
}
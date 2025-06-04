import 'package:construculator/libraries/supabase/testing/fake_supabase_client.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_initializer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('FakeSupabaseInitializer', () {
    late FakeSupabaseInitializer fakeInitializer;

    setUp(() {
      fakeInitializer = FakeSupabaseInitializer();
    });

    test('initial state is correct', () {
      expect(fakeInitializer.lastUrl, isNull);
      expect(fakeInitializer.lastAnonKey, isNull);
      expect(fakeInitializer.lastDebugFlag, isNull);
      expect(fakeInitializer.shouldThrowOnInitialize, isFalse);
      expect(fakeInitializer.initializeErrorMessage, isNull);
      expect(fakeInitializer.fakeClient, isA<FakeSupabaseClient>());
    });

    test('initialize() sets properties and returns client', () async {
      const url = 'https://test.supabase.co';
      const anonKey = 'test-anon-key';
      const debug = true;

      final client = await fakeInitializer.initialize(url: url, anonKey: anonKey, debug: debug);

      expect(fakeInitializer.lastUrl, equals(url));
      expect(fakeInitializer.lastAnonKey, equals(anonKey));
      expect(fakeInitializer.lastDebugFlag, equals(debug));
      expect(client, isA<SupabaseClient>());
      expect(client, same(fakeInitializer.fakeClient)); // Ensure it returns the internal client
    });

    test('initialize() updates properties on multiple calls', () async {
      await fakeInitializer.initialize(url: 'url1', anonKey: 'key1');
      expect(fakeInitializer.lastUrl, 'url1');
      expect(fakeInitializer.lastAnonKey, 'key1');

      await fakeInitializer.initialize(url: 'url2', anonKey: 'key2', debug: true);
      expect(fakeInitializer.lastUrl, 'url2'); 
      expect(fakeInitializer.lastAnonKey, 'key2');
      expect(fakeInitializer.lastDebugFlag, true);
    });
    
    test('initialize() throws when shouldThrowOnInitialize is true', () async {
      fakeInitializer.shouldThrowOnInitialize = true;
      fakeInitializer.initializeErrorMessage = 'Custom error';
      const url = 'https://test.supabase.co';
      const anonKey = 'test-anon-key';

      expect(
        () async => await fakeInitializer.initialize(url: url, anonKey: anonKey),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Custom error'))),
      );
      // Properties should NOT be updated if it throws before setting them.
      // Based on current FakeSupabaseInitializer, it throws *before* setting them.
      expect(fakeInitializer.lastUrl, isNull); 
      expect(fakeInitializer.lastAnonKey, isNull);
    });

     test('initialize() throws default message if no custom error message is set', () async {
      fakeInitializer.shouldThrowOnInitialize = true;
      // initializeErrorMessage is null by default
      const url = 'https://test.supabase.co';
      const anonKey = 'test-anon-key';

      expect(
        () async => await fakeInitializer.initialize(url: url, anonKey: anonKey),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to initialize Supabase'))),
      );
    });

    test('reset() resets all properties', () async {
      // Modify some properties
      await fakeInitializer.initialize(url: 'https://url.com', anonKey: 'key');
      fakeInitializer.shouldThrowOnInitialize = true;
      fakeInitializer.initializeErrorMessage = 'Error after init';
      
      // Ensure they are modified
      expect(fakeInitializer.lastUrl, 'https://url.com');
      expect(fakeInitializer.shouldThrowOnInitialize, isTrue);
      expect(fakeInitializer.initializeErrorMessage, 'Error after init');

      fakeInitializer.reset();

      // Check if reset to initial state
      expect(fakeInitializer.lastUrl, isNull);
      expect(fakeInitializer.lastAnonKey, isNull);
      expect(fakeInitializer.lastDebugFlag, isNull);
      expect(fakeInitializer.shouldThrowOnInitialize, isFalse);
      expect(fakeInitializer.initializeErrorMessage, isNull);
      expect(fakeInitializer.fakeClient, isA<FakeSupabaseClient>());
    });

    test('initialize() uses default debug value (false) if not provided', () async {
      const url = 'https://test.supabase.co';
      const anonKey = 'test-anon-key';

      await fakeInitializer.initialize(url: url, anonKey: anonKey); // debug not provided

      expect(fakeInitializer.lastDebugFlag, isFalse); // Default in SupabaseInitializer interface is false
    });
  });
}

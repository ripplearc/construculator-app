import 'package:construculator/libraries/supabase/testing/fake_supabase_client.dart';
import 'package:construculator/libraries/config/testing/fake_supabase_initializer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('FakeSupabaseInitializer', () {
    late FakeSupabaseInitializer fakeInitializer;

    setUp(() {
      fakeInitializer = FakeSupabaseInitializer();
    });

    tearDown(() {
      fakeInitializer.reset();
    });

    test('has correct initial state for properties', () {
      expect(fakeInitializer.lastUrl, isNull, reason: "Initial lastUrl should be null");
      expect(fakeInitializer.lastAnonKey, isNull, reason: "Initial lastAnonKey should be null");
      expect(fakeInitializer.lastDebugFlag, isNull, reason: "Initial lastDebugFlag should be null (or default false after first init)");
      expect(fakeInitializer.shouldThrowOnInitialize, isFalse, reason: "Initial shouldThrowOnInitialize should be false");
      expect(fakeInitializer.initializeErrorMessage, isNull, reason: "Initial initializeErrorMessage should be null");
      expect(fakeInitializer.fakeClient, isA<FakeSupabaseClient>(), reason: "Should have a fakeClient instance");
    });

    group('initialize()', () {
      const testUrl = 'https://test.supabase.co';
      const testAnonKey = 'test-anon-key';

      test('succeeds and stores provided URL, key, and debug flag', () async {
        const debug = true;
        final client = await fakeInitializer.initialize(url: testUrl, anonKey: testAnonKey, debug: debug);

        expect(fakeInitializer.lastUrl, equals(testUrl));
        expect(fakeInitializer.lastAnonKey, equals(testAnonKey));
        expect(fakeInitializer.lastDebugFlag, equals(debug));
        expect(client, isA<SupabaseClient>());
        expect(client, same(fakeInitializer.fakeClient), reason: "Should return the internal fake client instance");
      });

      test('uses default debug value (false) if not provided', () async {
        await fakeInitializer.initialize(url: testUrl, anonKey: testAnonKey); // debug not provided
        expect(fakeInitializer.lastDebugFlag, isFalse, reason: "Debug flag should default to false");
      });

      test('updates properties correctly on multiple calls', () async {
        await fakeInitializer.initialize(url: 'url1', anonKey: 'key1');
        expect(fakeInitializer.lastUrl, 'url1');
        expect(fakeInitializer.lastAnonKey, 'key1');
        expect(fakeInitializer.lastDebugFlag, false, reason: "Debug flag defaults to false");

        await fakeInitializer.initialize(url: 'url2', anonKey: 'key2', debug: true);
        expect(fakeInitializer.lastUrl, 'url2');
        expect(fakeInitializer.lastAnonKey, 'key2');
        expect(fakeInitializer.lastDebugFlag, true);
      });

      test('throws exception when shouldThrowOnInitialize is true with custom message', () async {
        fakeInitializer.shouldThrowOnInitialize = true;
        fakeInitializer.initializeErrorMessage = 'Custom init error';

        expect(
          () async => await fakeInitializer.initialize(url: testUrl, anonKey: testAnonKey),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Custom init error'))),
        );
        // Properties should NOT be updated if it throws.
        expect(fakeInitializer.lastUrl, isNull, reason: "lastUrl should remain null after a failed init");
        expect(fakeInitializer.lastAnonKey, isNull, reason: "lastAnonKey should remain null after a failed init");
      });

      test('throws default exception message if no custom message is set and shouldThrowOnInitialize is true', () async {
        fakeInitializer.shouldThrowOnInitialize = true;
        // initializeErrorMessage is null by default after reset or initially

        expect(
          () async => await fakeInitializer.initialize(url: testUrl, anonKey: testAnonKey),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to initialize Supabase'))),
        );
      });
      
      test('does not store parameters when throwing an exception during initialization', () async {
        fakeInitializer.shouldThrowOnInitialize = true;

        try {
          await fakeInitializer.initialize(url: 'url-fail', anonKey: 'key-fail');
        } catch (_) {
          // Expected to throw
        }

        expect(fakeInitializer.lastUrl, isNull);
        expect(fakeInitializer.lastAnonKey, isNull);
        expect(fakeInitializer.lastDebugFlag, isNull);
      });
    });

    group('reset()', () {
      test('resets all properties and configurations to their initial states', () async {
        // Modify some properties first
        await fakeInitializer.initialize(url: 'https://url.com', anonKey: 'key', debug: true);
        fakeInitializer.shouldThrowOnInitialize = true;
        fakeInitializer.initializeErrorMessage = 'Error after init';
        
        // Ensure they are modified
        expect(fakeInitializer.lastUrl, 'https://url.com');
        expect(fakeInitializer.lastDebugFlag, true);
        expect(fakeInitializer.shouldThrowOnInitialize, isTrue);
        expect(fakeInitializer.initializeErrorMessage, 'Error after init');

        fakeInitializer.reset();

        // Check if reset to initial state (as defined in the 'has correct initial state' test)
        expect(fakeInitializer.lastUrl, isNull);
        expect(fakeInitializer.lastAnonKey, isNull);
        expect(fakeInitializer.lastDebugFlag, isNull);
        expect(fakeInitializer.shouldThrowOnInitialize, isFalse);
        expect(fakeInitializer.initializeErrorMessage, isNull);
        expect(fakeInitializer.fakeClient, isA<FakeSupabaseClient>()); 
      });

      test('allows normal initialization after a reset from a throwing state', () async {
        fakeInitializer.shouldThrowOnInitialize = true;
        fakeInitializer.initializeErrorMessage = 'Will be reset';
        fakeInitializer.reset(); // Reset the throwing behavior

        expect(
          () async => await fakeInitializer.initialize(
            url: 'https://reset.supabase.co',
            anonKey: 'reset_key',
          ),
          returnsNormally,
          reason: "Initialization should succeed after reset"
        );
        // Also check if properties are set correctly after successful init
        expect(fakeInitializer.lastUrl, equals('https://reset.supabase.co'));
        expect(fakeInitializer.lastAnonKey, equals('reset_key'));
      });
    });

    group('Edge Cases for initialize()', () {
      test('handles empty string for URL and anonKey', () async {
        await fakeInitializer.initialize(url: '', anonKey: '');
        expect(fakeInitializer.lastUrl, equals(''));
        expect(fakeInitializer.lastAnonKey, equals(''));
        expect(fakeInitializer.lastDebugFlag, equals(false), reason: "Debug flag defaults to false");
      });

      test('handles very long strings for URL and anonKey', () async {
        final longUrl = 'https://${'a' * 1000}.supabase.co';
        final longKey = 'key_${'b' * 1000}';

        await fakeInitializer.initialize(url: longUrl, anonKey: longKey);
        expect(fakeInitializer.lastUrl, equals(longUrl));
        expect(fakeInitializer.lastAnonKey, equals(longKey));
      });
    });
  });
}

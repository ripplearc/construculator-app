import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('FakeSupabaseWrapper Authentication State', () {
    late FakeSupabaseWrapper fakeWrapper;

    setUp(() {
      fakeWrapper = FakeSupabaseWrapper();
    });

    tearDown(() {
      fakeWrapper.reset();
    });

    test('currentUser returns the currently signed-in user', () async {
      await fakeWrapper.signInWithPassword(
        email: 'current@example.com',
        password: 'password',
      );

      final user = fakeWrapper.currentUser;
      expect(user, isNotNull);
      expect(user!.email, equals('current@example.com'));
    });

    test('currentUser returns null when no user is signed in', () {
      final user = fakeWrapper.currentUser;
      expect(user, isNull);
    });

    test('isAuthenticated reflects the current sign-in status', () async {
      // Initially not authenticated
      expect(fakeWrapper.isAuthenticated, isFalse, reason: "Should not be authenticated initially");

      await fakeWrapper.signInWithPassword(
        email: 'user@example.com',
        password: 'password',
      );
      expect(fakeWrapper.isAuthenticated, isTrue, reason: "Should be authenticated after sign-in");

      await fakeWrapper.signOut();
      expect(fakeWrapper.isAuthenticated, isFalse, reason: "Should not be authenticated after sign-out");
    });

    test('onAuthStateChange emits events for sign-in and sign-out', () async {
      final authStates = <supabase.AuthState>[];
      final subscription = fakeWrapper.onAuthStateChange.listen(authStates.add);

      await fakeWrapper.signInWithPassword(
        email: 'user@example.com',
        password: 'password',
      );
      // Allow time for the stream to emit
      await Future.delayed(Duration(milliseconds: 10));

      await fakeWrapper.signOut();
      // Allow time for the stream to emit
      await Future.delayed(Duration(milliseconds: 10));

      expect(authStates.length, greaterThanOrEqualTo(2), reason: "Should have at least two auth states: signedIn and signedOut");
      expect(authStates.first.event, equals(supabase.AuthChangeEvent.signedIn));
      expect(authStates.first.session?.user.email, equals('user@example.com'));
      expect(authStates.last.event, equals(supabase.AuthChangeEvent.signedOut));
      expect(authStates.last.session, isNull);

      await subscription.cancel();
    });

    test('dispose closes the authStateController', () async {
      // Listen to the stream before disposing
      final subscription = fakeWrapper.onAuthStateChange.listen((_) {}, onError: (_) {});
      
      fakeWrapper.dispose();

      // Attempting to add an event to a closed controller should throw a StateError
      expect(
        () => fakeWrapper.simulateAuthStreamError('This should fail'), 
        throwsA(isA<StateError>()),
        reason: "Simulating auth stream error after dispose should throw StateError because the controller is closed."
      );
      await subscription.cancel(); 
    });

    test('simulateAuthStreamError emits an error on onAuthStateChange stream', () async {
      final expectedErrorMessage = 'Simulated auth stream error!';
      
      // Expect an error to be emitted
      expectLater(
        fakeWrapper.onAuthStateChange,
        emitsError(isA<Exception>().having((e) => e.toString(), 'message', contains(expectedErrorMessage)))
      );
      
      fakeWrapper.simulateAuthStreamError(expectedErrorMessage);
    });

    test('emitAuthStateError (alias) emits an error on onAuthStateChange stream', () async {
      final expectedErrorMessage = 'Alias simulated auth stream error!';
      
      // Expect an error to be emitted
      expectLater(
        fakeWrapper.onAuthStateChange,
        emitsError(isA<Exception>().having((e) => e.toString(), 'message', contains(expectedErrorMessage)))
      );
      
      fakeWrapper.emitAuthStateError(expectedErrorMessage);
    });
  });
} 
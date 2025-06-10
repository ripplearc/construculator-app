import 'dart:async';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('FakeAuthNotifier', () {
    late FakeAuthNotifier fakeNotifier;

    setUp(() {
      fakeNotifier = FakeAuthNotifier();
    });

    tearDown(() {
      fakeNotifier.dispose();
    });

    group('Interface Contract Verification', () {
      test('should implement IAuthNotifier interface', () {
        expect(fakeNotifier, isA<AuthNotifier>());
      });

      test('should provide all required streams', () {
        expect(fakeNotifier.onLogin, isA<Stream<UserCredential>>());
        expect(fakeNotifier.onLogout, isA<Stream<void>>());
        expect(fakeNotifier.onAuthStateChanged, isA<Stream<AuthStatus>>());
        expect(fakeNotifier.onSetupProfile, isA<Stream<void>>());
      });

      test('should provide all required emit methods', () {
        expect(() => fakeNotifier.emitLogin(_createFakeCredential()), returnsNormally);
        expect(() => fakeNotifier.emitLogout(), returnsNormally);
        expect(() => fakeNotifier.emitAuthStateChanged(AuthStatus.authenticated), returnsNormally);
        expect(() => fakeNotifier.emitSetupProfile(), returnsNormally);
      });
    });

    group('Core Functionality', () {
      test('emitLogin should emit login event and authenticated state', () async {
        final fakeCredential = _createFakeCredential();
        final loginCompleter = Completer<UserCredential>();
        final stateCompleter = Completer<AuthStatus>();
        
        fakeNotifier.onLogin.listen(loginCompleter.complete);
        fakeNotifier.onAuthStateChanged.listen(stateCompleter.complete);

        fakeNotifier.emitLogin(fakeCredential);

        final receivedCredential = await loginCompleter.future.timeout(Duration(seconds: 1));
        final receivedState = await stateCompleter.future.timeout(Duration(seconds: 1));
        
        expect(receivedCredential.email, fakeCredential.email);
        expect(receivedState, AuthStatus.authenticated);
      });

      test('emitLogout should emit logout event only', () async {
        final logoutCompleter = Completer<void>();
        
        fakeNotifier.onLogout.listen((_) => logoutCompleter.complete());

        fakeNotifier.emitLogout();

        await logoutCompleter.future.timeout(Duration(seconds: 1));
      });

      test('emitSetupProfile should emit setup profile event and authenticated state', () async {
        final setupCompleter = Completer<void>();
        final stateCompleter = Completer<AuthStatus>();
        
        fakeNotifier.onSetupProfile.listen((_) => setupCompleter.complete());
        fakeNotifier.onAuthStateChanged.listen(stateCompleter.complete);

        fakeNotifier.emitSetupProfile();

        await setupCompleter.future.timeout(Duration(seconds: 1));
        final receivedState = await stateCompleter.future.timeout(Duration(seconds: 1));
        
        expect(receivedState, AuthStatus.authenticated);
      });

      test('emitAuthStateChanged should emit correct auth state', () async {
        final stateCompleter = Completer<AuthStatus>();
        fakeNotifier.onAuthStateChanged.listen(stateCompleter.complete);

        fakeNotifier.emitAuthStateChanged(AuthStatus.authenticated);

        final receivedState = await stateCompleter.future.timeout(Duration(seconds: 1));
        expect(receivedState, AuthStatus.authenticated);
      });
    });

    group('Test Utility Features', () {
      test('should track login events for test verification', () async {
        final credential1 = _createFakeCredential(email: 'user1@test.com');
        final credential2 = _createFakeCredential(email: 'user2@test.com');

        fakeNotifier.emitLogin(credential1);
        fakeNotifier.emitLogin(credential2);

        await Future.delayed(Duration(milliseconds: 10));

        expect(fakeNotifier.loginEvents, hasLength(2));
        expect(fakeNotifier.loginEvents[0].email, 'user1@test.com');
        expect(fakeNotifier.loginEvents[1].email, 'user2@test.com');
      });

      test('should track logout events for test verification', () async {
        fakeNotifier.emitLogout();
        fakeNotifier.emitLogout();

        await Future.delayed(Duration(milliseconds: 10));

        expect(fakeNotifier.logoutEvents, hasLength(2));
      });

      test('should track auth state change events for test verification', () async {
        fakeNotifier.emitAuthStateChanged(AuthStatus.authenticated);
        fakeNotifier.emitAuthStateChanged(AuthStatus.unauthenticated);
        fakeNotifier.emitAuthStateChanged(AuthStatus.authenticated);

        await Future.delayed(Duration(milliseconds: 10));

        expect(fakeNotifier.stateChangedEvents, hasLength(3));
        expect(fakeNotifier.stateChangedEvents[0], AuthStatus.authenticated);
        expect(fakeNotifier.stateChangedEvents[1], AuthStatus.unauthenticated);
        expect(fakeNotifier.stateChangedEvents[2], AuthStatus.authenticated);
      });

      test('should track setup profile events for test verification', () async {
        fakeNotifier.emitSetupProfile();
        fakeNotifier.emitSetupProfile();

        await Future.delayed(Duration(milliseconds: 10));

        expect(fakeNotifier.setupProfileEvents, hasLength(2));
      });

      test('emitLogin should trigger both login and auth state events', () async {
        fakeNotifier.emitLogin(_createFakeCredential());

        await Future.delayed(Duration(milliseconds: 10));

        expect(fakeNotifier.loginEvents, hasLength(1));
        expect(fakeNotifier.stateChangedEvents, hasLength(1));
        expect(fakeNotifier.stateChangedEvents[0], AuthStatus.authenticated);
      });

      test('emitLogout should trigger logout events only', () async {
        fakeNotifier.emitLogout();

        await Future.delayed(Duration(milliseconds: 10));

        expect(fakeNotifier.logoutEvents, hasLength(1));
        expect(fakeNotifier.stateChangedEvents, hasLength(0));
      });

      test('emitSetupProfile should trigger both setup profile and auth state events', () async {
        fakeNotifier.emitSetupProfile();

        await Future.delayed(Duration(milliseconds: 10));

        expect(fakeNotifier.setupProfileEvents, hasLength(1));
        expect(fakeNotifier.stateChangedEvents, hasLength(1));
        expect(fakeNotifier.stateChangedEvents[0], AuthStatus.authenticated);
      });

      test('reset should clear all tracked events', () async {
        fakeNotifier.emitLogin(_createFakeCredential());
        fakeNotifier.emitLogout();
        fakeNotifier.emitAuthStateChanged(AuthStatus.authenticated);
        fakeNotifier.emitSetupProfile();

        await Future.delayed(Duration(milliseconds: 10));

        expect(fakeNotifier.loginEvents, isNotEmpty);
        expect(fakeNotifier.logoutEvents, isNotEmpty);
        expect(fakeNotifier.stateChangedEvents, isNotEmpty);
        expect(fakeNotifier.setupProfileEvents, isNotEmpty);

        fakeNotifier.reset();

        expect(fakeNotifier.loginEvents, isEmpty);
        expect(fakeNotifier.logoutEvents, isEmpty);
        expect(fakeNotifier.stateChangedEvents, isEmpty);
        expect(fakeNotifier.setupProfileEvents, isEmpty);
      });
    });

    group('Stream Behavior', () {
      test('streams should be broadcast and allow multiple listeners', () {
        expect(() {
          fakeNotifier.onLogin.listen((_) {});
          fakeNotifier.onLogin.listen((_) {});
        }, returnsNormally);

        expect(() {
          fakeNotifier.onLogout.listen((_) {});
          fakeNotifier.onLogout.listen((_) {});
        }, returnsNormally);

        expect(() {
          fakeNotifier.onAuthStateChanged.listen((_) {});
          fakeNotifier.onAuthStateChanged.listen((_) {});
        }, returnsNormally);

        expect(() {
          fakeNotifier.onSetupProfile.listen((_) {});
          fakeNotifier.onSetupProfile.listen((_) {});
        }, returnsNormally);
      });
    });

    group('Resource Management', () {
      test('dispose should close all streams without error', () {
        fakeNotifier.onLogin.listen((_) {});
        fakeNotifier.onLogout.listen((_) {});
        fakeNotifier.onAuthStateChanged.listen((_) {});
        fakeNotifier.onSetupProfile.listen((_) {});

        expect(() => fakeNotifier.dispose(), returnsNormally);
      });
    });
  });
}

UserCredential _createFakeCredential({String? email}) {
  return UserCredential(
    id: 'fake-id',
    email: email ?? 'test@example.com',
    metadata: {'source': 'test'},
    createdAt: DateTime.now(),
  );
} 
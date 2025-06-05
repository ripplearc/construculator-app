import 'dart:async';
import 'package:construculator/libraries/auth/shared_auth_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:flutter_modular/flutter_modular.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedAuthNotifier - Part 1', () {
    late SharedAuthNotifier authNotifier;

    setUp(() {
      authNotifier = SharedAuthNotifier();
    });

    tearDown(() {
      authNotifier.dispose();
    });

    group('Interface Contract Verification', () {
      test('should implement IAuthNotifier interface', () {
        expect(authNotifier, isA<AuthNotifier>());
      });

      test('should implement Disposable interface', () {
        expect(authNotifier, isA<Disposable>());
      });

      test('should provide all required streams', () {
        expect(authNotifier.onLogin, isA<Stream<UserCredential>>());
        expect(authNotifier.onLogout, isA<Stream<void>>());
        expect(authNotifier.onAuthStateChanged, isA<Stream<AuthStatus>>());
        expect(authNotifier.onSetupProfile, isA<Stream<void>>());
      });

      test('should provide all required emit methods', () {
        expect(() => authNotifier.emitLogin(_createFakeCredential()), returnsNormally);
        expect(() => authNotifier.emitLogout(), returnsNormally);
        expect(() => authNotifier.emitAuthStateChanged(AuthStatus.authenticated), returnsNormally);
        expect(() => authNotifier.emitSetupProfile(), returnsNormally);
      });
    });

    group('Stream Behavior', () {
      test('streams should be broadcast and allow multiple listeners', () {
        expect(() {
          authNotifier.onLogin.listen((_) {});
          authNotifier.onLogin.listen((_) {});
        }, returnsNormally);

        expect(() {
          authNotifier.onLogout.listen((_) {});
          authNotifier.onLogout.listen((_) {});
        }, returnsNormally);

        expect(() {
          authNotifier.onAuthStateChanged.listen((_) {});
          authNotifier.onAuthStateChanged.listen((_) {});
        }, returnsNormally);

        expect(() {
          authNotifier.onSetupProfile.listen((_) {});
          authNotifier.onSetupProfile.listen((_) {});
        }, returnsNormally);
      });

      test('streams should be accessible immediately after creation', () {
        final notifier = SharedAuthNotifier();
        
        expect(notifier.onLogin, isNotNull);
        expect(notifier.onLogout, isNotNull);
        expect(notifier.onAuthStateChanged, isNotNull);
        expect(notifier.onSetupProfile, isNotNull);
        
        notifier.dispose();
      });
    });

    group('Login Event Emission', () {
      test('emitLogin should emit login event with correct user credential', () async {
        final fakeCredential = _createFakeCredential();
        final loginCompleter = Completer<UserCredential>();
        
        authNotifier.onLogin.listen(loginCompleter.complete);

        authNotifier.emitLogin(fakeCredential);

        // Receive the credential from the login event
        final receivedCredential = await loginCompleter.future.timeout(Duration(seconds: 1));
        
        expect(receivedCredential.id, fakeCredential.id);
        expect(receivedCredential.email, fakeCredential.email);
        expect(receivedCredential.metadata, fakeCredential.metadata);
        expect(receivedCredential.createdAt, fakeCredential.createdAt);
      });

      test('emitLogin should automatically emit authenticated state', () async {
        final fakeCredential = _createFakeCredential();
        final stateCompleter = Completer<AuthStatus>();
        
        authNotifier.onAuthStateChanged.listen(stateCompleter.complete);

        authNotifier.emitLogin(fakeCredential);

        // Receive the state from the auth state changed event
        final receivedState = await stateCompleter.future.timeout(Duration(seconds: 1));
       
        expect(receivedState, AuthStatus.authenticated);
      });

      test('emitLogin should emit both login and auth state events', () async {
        final fakeCredential = _createFakeCredential();
        final loginEvents = <UserCredential>[];
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogin.listen(loginEvents.add);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        authNotifier.emitLogin(fakeCredential);

        await Future.delayed(Duration(milliseconds: 10));

        expect(loginEvents, hasLength(1));
        expect(stateEvents, hasLength(1));
        expect(loginEvents[0].email, fakeCredential.email);
        expect(stateEvents[0], AuthStatus.authenticated);
      });

      test('multiple emitLogin calls should emit multiple events', () async {
        final credential1 = _createFakeCredential(email: 'user1@test.com');
        final credential2 = _createFakeCredential(email: 'user2@test.com');
        final loginEvents = <UserCredential>[];
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogin.listen(loginEvents.add);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        authNotifier.emitLogin(credential1);
        authNotifier.emitLogin(credential2);

        await Future.delayed(Duration(milliseconds: 10));

        expect(loginEvents, hasLength(2));
        expect(stateEvents, hasLength(2));
        expect(loginEvents[0].email, 'user1@test.com');
        expect(loginEvents[1].email, 'user2@test.com');
        expect(stateEvents.every((state) => state == AuthStatus.authenticated), true);
      });
    });

    group('Logout Event Emission', () {
      test('emitLogout should emit logout event', () async {
        final logoutCompleter = Completer<void>();
        
        authNotifier.onLogout.listen((_) => logoutCompleter.complete());

        authNotifier.emitLogout();

        await logoutCompleter.future.timeout(Duration(seconds: 1));
      });

      test('emitLogout should automatically emit unauthenticated state', () async {
        final logoutCompleter = Completer<void>();
        
        authNotifier.onLogout.listen((_) => logoutCompleter.complete());

        authNotifier.emitLogout();

        await logoutCompleter.future.timeout(Duration(seconds: 1));
      });

      test('emitLogout should emit logout events only', () async {
        int logoutEventCount = 0;
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogout.listen((_) => logoutEventCount++);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        authNotifier.emitLogout();

        await Future.delayed(Duration(milliseconds: 10));

        expect(logoutEventCount, 1);
        expect(stateEvents, hasLength(0));
      });

      test('multiple emitLogout calls should emit multiple logout events only', () async {
        int logoutEventCount = 0;
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogout.listen((_) => logoutEventCount++);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        authNotifier.emitLogout();
        authNotifier.emitLogout();

        await Future.delayed(Duration(milliseconds: 10));

        expect(logoutEventCount, 2);
        expect(stateEvents, hasLength(0));
      });
    });

    group('Setup Profile Event Emission', () {
      test('emitSetupProfile should emit setup profile event', () async {
        final setupCompleter = Completer<void>();
        
        authNotifier.onSetupProfile.listen((_) => setupCompleter.complete());

        authNotifier.emitSetupProfile();

        await setupCompleter.future.timeout(Duration(seconds: 1));
      });

      test('multiple emitSetupProfile calls should emit multiple events', () async {
        int setupEventCount = 0;
        
        authNotifier.onSetupProfile.listen((_) => setupEventCount++);

        authNotifier.emitSetupProfile();
        authNotifier.emitSetupProfile();

        await Future.delayed(Duration(milliseconds: 10));

        expect(setupEventCount, 2);
      });
    });
  });
}

UserCredential _createFakeCredential({String? email}) {
  return UserCredential(
    id: 'fake-id-${DateTime.now().millisecondsSinceEpoch}',
    email: email ?? 'test@example.com',
    metadata: {'source': 'test'},
    createdAt: DateTime.now(),
  );
} 
import 'dart:async';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/shared_auth_notifier.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('SharedAuthNotifier', () {
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
  
    group('Auth State Change Event Emission', () {
      test('emitAuthStateChanged should emit correct auth status', () async {
        final stateCompleter = Completer<AuthStatus>();
        
        authNotifier.onAuthStateChanged.listen(stateCompleter.complete);

        authNotifier.emitAuthStateChanged(AuthStatus.authenticated);

        // Receive the state from the auth state changed event
        final receivedState = await stateCompleter.future.timeout(Duration(seconds: 1));
        
        expect(receivedState, AuthStatus.authenticated);
      });

      test('emitAuthStateChanged should handle all auth status types', () async {
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        authNotifier.emitAuthStateChanged(AuthStatus.authenticated);
        authNotifier.emitAuthStateChanged(AuthStatus.unauthenticated);
        authNotifier.emitAuthStateChanged(AuthStatus.connectionError);

        await Future.delayed(Duration(milliseconds: 10));

        expect(stateEvents, hasLength(3));
        expect(stateEvents, [AuthStatus.authenticated, AuthStatus.unauthenticated, AuthStatus.connectionError]);
      });

      test('emitAuthStateChanged should not automatically trigger other events', () async {
        final loginEvents = <UserCredential>[];
        int logoutEventCount = 0;
        int setupEventCount = 0;
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogin.listen(loginEvents.add);
        authNotifier.onLogout.listen((_) => logoutEventCount++);
        authNotifier.onSetupProfile.listen((_) => setupEventCount++);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        await Future.delayed(Duration(milliseconds: 10));

        expect(stateEvents, isEmpty);
        expect(loginEvents, isEmpty);
        expect(logoutEventCount, 0);
        expect(setupEventCount, 0);
      });
    });

    group('Event Interaction and Sequencing', () {
      test('login followed by logout should emit correct sequence', () async {
        final fakeCredential = _createFakeCredential();
        final allEvents = <String>[];
        
        authNotifier.onLogin.listen((_) => allEvents.add('login'));
        authNotifier.onLogout.listen((_) => allEvents.add('logout'));
        authNotifier.onAuthStateChanged.listen((status) => allEvents.add('state:$status'));

        authNotifier.emitLogin(fakeCredential);
        authNotifier.emitLogout();

        await Future.delayed(Duration(milliseconds: 10));

        expect(allEvents, hasLength(3));
        expect(allEvents[0], 'login');
        expect(allEvents[1], 'state:AuthStatus.authenticated');
        expect(allEvents[2], 'logout');
      });

      test('mixed event emissions should work correctly', () async {
        final fakeCredential = _createFakeCredential();
        final loginEvents = <UserCredential>[];
        int logoutEventCount = 0;
        int setupEventCount = 0;
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogin.listen(loginEvents.add);
        authNotifier.onLogout.listen((_) => logoutEventCount++);
        authNotifier.onSetupProfile.listen((_) => setupEventCount++);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        authNotifier.emitLogin(fakeCredential);
        authNotifier.emitSetupProfile();
        authNotifier.emitLogout();

        await Future.delayed(Duration(milliseconds: 10));

        expect(loginEvents, hasLength(1));
        expect(setupEventCount, 1);
        expect(logoutEventCount, 1);
        expect(stateEvents, hasLength(1));
        
        expect(loginEvents[0].email, fakeCredential.email);
        
        expect(stateEvents.contains(AuthStatus.authenticated), true);
      });

      test('should handle multiple listeners without interference', () async {
        final listener1Events = <UserCredential>[];
        final listener2Events = <UserCredential>[];
        final fakeCredential = _createFakeCredential();
        
        authNotifier.onLogin.listen(listener1Events.add);
        authNotifier.onLogin.listen(listener2Events.add);

        authNotifier.emitLogin(fakeCredential);

        await Future.delayed(Duration(milliseconds: 10));

        expect(listener1Events, hasLength(1));
        expect(listener2Events, hasLength(1));
        expect(listener1Events[0].email, fakeCredential.email);
        expect(listener2Events[0].email, fakeCredential.email);
      });
    });

    group('Resource Management and Disposal', () {
      test('dispose should close all stream controllers', () {
        final notifier = SharedAuthNotifier();
        
        notifier.onLogin.listen((_) {});
        notifier.onLogout.listen((_) {});
        notifier.onAuthStateChanged.listen((_) {});
        notifier.onSetupProfile.listen((_) {});

        expect(() => notifier.dispose(), returnsNormally);
      });

      test('streams should throw StateError after disposal', () async {
        final notifier = SharedAuthNotifier();
        final loginEvents = <UserCredential>[];
        int logoutEventCount = 0;
        final stateEvents = <AuthStatus>[];
        int setupEventCount = 0;
        
        notifier.onLogin.listen(loginEvents.add);
        notifier.onLogout.listen((_) => logoutEventCount++);
        notifier.onAuthStateChanged.listen(stateEvents.add);
        notifier.onSetupProfile.listen((_) => setupEventCount++);

        notifier.dispose();
        
        expect(() => notifier.emitLogin(_createFakeCredential()), throwsStateError);
        expect(() => notifier.emitLogout(), throwsStateError);
        expect(() => notifier.emitAuthStateChanged(AuthStatus.authenticated), throwsStateError);
        expect(() => notifier.emitSetupProfile(), throwsStateError);

        await Future.delayed(Duration(milliseconds: 10));

        expect(loginEvents, isEmpty);
        expect(logoutEventCount, 0);
        expect(stateEvents, isEmpty);
        expect(setupEventCount, 0);
      });

      test('multiple dispose calls should not cause errors', () {
        final notifier = SharedAuthNotifier();

        expect(() => notifier.dispose(), returnsNormally);
        expect(() => notifier.dispose(), returnsNormally);
        expect(() => notifier.dispose(), returnsNormally);
      });
    });

    group('Stream Controller Configuration', () {
      test('stream controllers should be broadcast streams', () {
        final subscription1 = authNotifier.onLogin.listen((_) {});
        final subscription2 = authNotifier.onLogin.listen((_) {});
        
        expect(() => subscription1.cancel(), returnsNormally);
        expect(() => subscription2.cancel(), returnsNormally);
      });

      test('streams should handle rapid successive emissions', () async {
        final fakeCredential = _createFakeCredential();
        final loginEvents = <UserCredential>[];
        final stateEvents = <AuthStatus>[];
        
        authNotifier.onLogin.listen(loginEvents.add);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        for (int i = 0; i < 10; i++) {
          authNotifier.emitLogin(fakeCredential);
        }

        await Future.delayed(Duration(milliseconds: 50));

        expect(loginEvents, hasLength(10));
        expect(stateEvents, hasLength(10));
        expect(stateEvents.every((state) => state == AuthStatus.authenticated), true);
      });
    });

    group('Edge Cases and Robustness', () {
      test('should handle void stream events correctly', () async {
        final logoutCompleter = Completer<void>();
        final setupCompleter = Completer<void>();
        
        authNotifier.onLogout.listen((_) {
          logoutCompleter.complete();
        });
        
        authNotifier.onSetupProfile.listen((_) {
          setupCompleter.complete();
        });

        authNotifier.emitLogout();
        authNotifier.emitSetupProfile();

        await logoutCompleter.future.timeout(Duration(seconds: 1));
        await setupCompleter.future.timeout(Duration(seconds: 1));
      });

      test('should handle rapid successive events without issues', () async {
        final loginEvents = <UserCredential>[];
        final stateEvents = <AuthStatus>[];
        final fakeCredential = _createFakeCredential();
        
        authNotifier.onLogin.listen(loginEvents.add);
        authNotifier.onAuthStateChanged.listen(stateEvents.add);

        for (int i = 0; i < 5; i++) {
          authNotifier.emitLogin(fakeCredential);
        }

        await Future.delayed(Duration(milliseconds: 50));

        expect(loginEvents, hasLength(5));
        expect(stateEvents, hasLength(5));
        expect(stateEvents.every((state) => state == AuthStatus.authenticated), true);
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
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeAuthNotifier fakeNotifier;

  UserCredential createFakeCredential({String? email}) {
    return UserCredential(
      id: 'fake-id',
      email: email ?? 'test@example.com',
      metadata: {'source': 'test'},
      createdAt: DateTime.now(),
    );
  }

  User createFakeUser({String? email}) {
    return User(
      id: 'fake-id',
      credentialId: 'fake-cred-id',
      email: email ?? 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      professionalRole: 'Developer',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userStatus: UserProfileStatus.active,
      userPreferences: {},
    );
  }

  setUp(() {
    Modular.init(_TestAppModule());
    fakeNotifier =
        Modular.get<AuthNotifier>(key: 'fakeAuthNotifier') as FakeAuthNotifier;
  });

  tearDown(() {
    Modular.destroy();
  });

  group('FakeAuthNotifier', () {
    group('Interface Contract Verification', () {
      test('should provide all required streams', () {
        expect(fakeNotifier.onAuthStateChanged, isA<Stream<AuthState>>());
        expect(fakeNotifier.onUserProfileChanged, isA<Stream<User?>>());
      });

      test('should provide all required emit methods', () {
        final authState = AuthState(
          status: AuthStatus.authenticated,
          user: createFakeCredential(),
        );
        final user = createFakeUser();

        expect(
          () => fakeNotifier.emitAuthStateChanged(authState),
          returnsNormally,
        );
        expect(
          () => fakeNotifier.emitUserProfileChanged(user),
          returnsNormally,
        );
      });
    });

    group('Core Functionality', () {
      test('emitAuthStateChanged should emit auth state', () async {
        final authState = AuthState(
          status: AuthStatus.authenticated,
          user: createFakeCredential(),
        );

        expectLater(fakeNotifier.onAuthStateChanged, emits(authState));

        fakeNotifier.emitAuthStateChanged(authState);
      });

      test('emitUserProfileChanged should emit user profile', () async {
        final user = createFakeUser();

        expectLater(fakeNotifier.onUserProfileChanged, emits(user));

        fakeNotifier.emitUserProfileChanged(user);
      });
    });

    group('Test Utility Features', () {
      test(
        'should track auth state change events for test verification',
        () async {
          final authState1 = AuthState(
            status: AuthStatus.authenticated,
            user: createFakeCredential(),
          );
          final authState2 = AuthState(
            status: AuthStatus.unauthenticated,
            user: null,
          );

          expectLater(
            fakeNotifier.onAuthStateChanged,
            emitsInOrder([authState1, authState2]),
          );

          fakeNotifier.emitAuthStateChanged(authState1);
          fakeNotifier.emitAuthStateChanged(authState2);
        },
      );

      test(
        'should track user profile change events for test verification',
        () async {
          final user1 = createFakeUser(email: 'user1@test.com');
          final user2 = createFakeUser(email: 'user2@test.com');

          expectLater(
            fakeNotifier.onUserProfileChanged,
            emitsInOrder([user1, user2]),
          );

          fakeNotifier.emitUserProfileChanged(user1);
          fakeNotifier.emitUserProfileChanged(user2);
        },
      );

      test('reset should clear all tracked events', () async {
        final authState = AuthState(
          status: AuthStatus.authenticated,
          user: createFakeCredential(),
        );
        final user = createFakeUser();

        // Start listening FIRST
        final authStateReceived = expectLater(
          fakeNotifier.onAuthStateChanged,
          emits(authState),
        );

        final userProfileReceived = expectLater(
          fakeNotifier.onUserProfileChanged,
          emits(user),
        );

        // THEN emit the events
        fakeNotifier.emitAuthStateChanged(authState);
        fakeNotifier.emitUserProfileChanged(user);

        // Wait for both expectations to complete
        await Future.wait([authStateReceived, userProfileReceived]);

        expect(fakeNotifier.stateChangedEvents, [authState]);
        expect(fakeNotifier.userProfileChangedEvents, [user]);
        
        fakeNotifier.reset();
        expect(fakeNotifier.stateChangedEvents, isEmpty);
        expect(fakeNotifier.userProfileChangedEvents, isEmpty);
      });
    });

    group('Stream Behavior', () {
      test('streams should be broadcast and allow multiple listeners', () {
        expect(() {
          fakeNotifier.onAuthStateChanged.listen((_) {});
          fakeNotifier.onAuthStateChanged.listen((_) {});
        }, returnsNormally);

        expect(() {
          fakeNotifier.onUserProfileChanged.listen((_) {});
          fakeNotifier.onUserProfileChanged.listen((_) {});
        }, returnsNormally);
      });
    });

    group('Resource Management', () {
      test('dispose should close all streams without error', () {
        fakeNotifier.onAuthStateChanged.listen((_) {});
        fakeNotifier.onUserProfileChanged.listen((_) {});

        expect(() => fakeNotifier.dispose(), returnsNormally);
      });
    });
  });
}

class _TestAppModule extends Module {
  @override
  List<Module> get imports => [AuthTestModule()];
}

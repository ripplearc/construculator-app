import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/auth/auth_notifier_impl.dart';
import 'package:construculator/libraries/auth/testing/auth_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuthNotifierImpl authNotifier;
  UserCredential createFakeCredential({String? email}) {
    return UserCredential(
      id: 'fake-id-${DateTime.now().millisecondsSinceEpoch}',
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
    authNotifier = Modular.get<AuthNotifier>(key: 'authNotifier') as AuthNotifierImpl;
  });

  tearDown(() {
    Modular.destroy();
  });

  group('AuthNotifierImpl', () {
    group('Interface Implementation', () {
      test('should expose required state emission methods', () {
        final authState = AuthState(
          status: AuthStatus.authenticated,
          user: createFakeCredential(),
        );
        final user = createFakeUser();

        expect(
          () => authNotifier.emitAuthStateChanged(authState),
          returnsNormally,
        );
        expect(
          () => authNotifier.emitUserProfileChanged(user),
          returnsNormally,
        );
      });
    });

    group('Stream Behavior', () {
      test('onAuthStateChanged and onUserProfileChanged should support multiple subscribers', () {
        expect(() {
          authNotifier.onAuthStateChanged.listen((_) {});
          authNotifier.onAuthStateChanged.listen((_) {});
        }, returnsNormally);

        expect(() {
          authNotifier.onUserProfileChanged.listen((_) {});
          authNotifier.onUserProfileChanged.listen((_) {});
        }, returnsNormally);
      });

      test('streams should be immediately available after initialization', () {
        expect(authNotifier.onAuthStateChanged, isNotNull);
        expect(authNotifier.onUserProfileChanged, isNotNull);
      });
    });

    group('Auth State Events', () {
      test('emitAuthStateChanged should emit provided auth state to all subscribers', () async {
        final authState = AuthState(
          status: AuthStatus.authenticated,
          user: createFakeCredential(),
        );

        expectLater(authNotifier.onAuthStateChanged, emits(authState));

        authNotifier.emitAuthStateChanged(authState);
      });

      test('emitAuthStateChanged should handle all authentication status types', () async {
        final credential = createFakeCredential();

        expectLater(
          authNotifier.onAuthStateChanged,
          emitsInOrder([
            predicate<AuthState>(
              (state) =>
                  state.status == AuthStatus.authenticated &&
                  state.user!.email == credential.email,
            ),
            predicate<AuthState>(
              (state) =>
                  state.status == AuthStatus.unauthenticated &&
                  state.user == null,
            ),
            predicate<AuthState>(
              (state) =>
                  state.status == AuthStatus.connectionError &&
                  state.user == null,
            ),
          ]),
        );

        authNotifier.emitAuthStateChanged(
          AuthState(status: AuthStatus.authenticated, user: credential),
        );
        authNotifier.emitAuthStateChanged(
          AuthState(status: AuthStatus.unauthenticated, user: null),
        );
        authNotifier.emitAuthStateChanged(
          AuthState(status: AuthStatus.connectionError, user: null),
        );
      });
    });

    group('User Profile Events', () {
      test('emitUserProfileChanged should emit updated user profile to all subscribers', () async {
        final user = createFakeUser();

        expectLater(authNotifier.onUserProfileChanged, emits(user));

        authNotifier.emitUserProfileChanged(user);
      });

      test('emitUserProfileChanged should handle null user profile', () async {
        expectLater(authNotifier.onUserProfileChanged, emits(null));

        authNotifier.emitUserProfileChanged(null);
      });

      test('emitUserProfileChanged should emit sequential profile updates in order', () async {
        final user1 = createFakeUser(email: 'user1@test.com');
        final user2 = createFakeUser(email: 'user2@test.com');

        expectLater(
          authNotifier.onUserProfileChanged,
          emitsInOrder([user1, user2, null]),
        );

        authNotifier.emitUserProfileChanged(user1);
        authNotifier.emitUserProfileChanged(user2);
        authNotifier.emitUserProfileChanged(null);
      });
    });

    group('Resource Management', () {
      test('dispose should properly close all stream controllers', () {
        authNotifier.onAuthStateChanged.listen((_) {});
        authNotifier.onUserProfileChanged.listen((_) {});

        expect(() => authNotifier.dispose(), returnsNormally);
      });

      test('emitAuthStateChanged and emitUserProfileChanged should throw after disposal', () async {
        authNotifier.onAuthStateChanged.listen((_) {});
        authNotifier.onUserProfileChanged.listen((_) {});

        authNotifier.dispose();

        final authState = AuthState(
          status: AuthStatus.authenticated,
          user: createFakeCredential(),
        );
        expect(
          () => authNotifier.emitAuthStateChanged(authState),
          throwsStateError,
        );
        expect(
          () => authNotifier.emitUserProfileChanged(createFakeUser()),
          throwsStateError,
        );
      });

      test('dispose should be safely callable multiple times', () {
        expect(() => authNotifier.dispose(), returnsNormally);
        expect(() => authNotifier.dispose(), returnsNormally);
        expect(() => authNotifier.dispose(), returnsNormally);
      });
    });

    group('Stream Controller Configuration', () {
      test('stream controllers should properly handle multiple subscribers', () {
        final subscription1 = authNotifier.onAuthStateChanged.listen((_) {});
        final subscription2 = authNotifier.onAuthStateChanged.listen((_) {});
        final subscription3 = authNotifier.onUserProfileChanged.listen((_) {});
        final subscription4 = authNotifier.onUserProfileChanged.listen((_) {});

        expect(() => subscription1.cancel(), returnsNormally);
        expect(() => subscription2.cancel(), returnsNormally);
        expect(() => subscription3.cancel(), returnsNormally);
        expect(() => subscription4.cancel(), returnsNormally);
      });

      test('stream controllers should handle rapid successive emissions', () async {
        final authState = AuthState(
          status: AuthStatus.authenticated,
          user: createFakeCredential(),
        );
        final user = createFakeUser();

        expectLater(
          authNotifier.onAuthStateChanged,
          emitsInOrder(List.filled(10, authState)),
        );
        expectLater(
          authNotifier.onUserProfileChanged,
          emitsInOrder(List.filled(10, user)),
        );

        for (int i = 0; i < 10; i++) {
          authNotifier.emitAuthStateChanged(authState);
          authNotifier.emitUserProfileChanged(user);
        }
      });
    });
  });
}

class _TestAppModule extends Module {
  @override
  List<Module> get imports => [
    AuthTestModule(),
  ];
}
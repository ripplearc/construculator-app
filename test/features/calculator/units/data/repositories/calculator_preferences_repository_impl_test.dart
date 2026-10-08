import 'dart:async';

import 'package:construculator/features/calculator/data/models/calculator_preferences_dto.dart';
import 'package:construculator/features/calculator/data/repositories/calculator_preferences_repository_impl.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_state.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_manager.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_notifier.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeAuthNotifier authNotifier;
  late FakeAuthRepository authRepository;
  late FakeAuthManager authManager;
  late CalculatorPreferencesRepositoryImpl repository;

  const metric = CalculatorPreferences(
    system: MeasurementSystem.metric,
    fractionResolution: FractionResolution.half,
    metreDisplay: MetreDisplay.threeDecimals,
    tonDefinition: TonDefinition.longTon,
    densityUnit: DensityUnit.kilogramsPerCubicMetre,
  );

  final hasMetricSystem = isA<CalculatorPreferences>().having(
    (preferences) => preferences.system,
    'system',
    MeasurementSystem.metric,
  );

  User userWith(
    Map<String, dynamic> preferences, {
    String credentialId = 'cred-1',
  }) => User(
    id: 'user-$credentialId',
    credentialId: credentialId,
    email: '$credentialId@example.com',
    firstName: 'Jane',
    lastName: 'Smith',
    professionalRole: 'Estimator',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    userStatus: UserProfileStatus.active,
    userPreferences: preferences,
  );

  Failure? failureOf(Either<Failure, CalculatorPreferences> result) =>
      result.fold((failure) => failure, (_) => null);

  CalculatorPreferences? savedOf(
    Either<Failure, CalculatorPreferences> result,
  ) => result.fold((_) => null, (saved) => saved);

  // A profile already signed in before the repository is created, as it is
  // when the calculator opens after login: the notifier announces nothing.
  void signIn(User user) {
    authRepository.setUserProfile(user);
    authManager.setCurrentCredential(
      UserCredential(
        id: user.credentialId ?? '',
        email: user.email,
        metadata: {},
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }

  // Announces a profile change and returns once every listener, the
  // repository among them, has received it: a broadcast stream delivers to
  // its listeners in the order they subscribed, and the repository
  // subscribes on its first watch or save, before this call.
  Future<void> announce(User? user) async {
    final delivered = authNotifier.onUserProfileChanged.first;
    authNotifier.emitUserProfileChanged(user);
    await delivered;
  }

  // Runs [change] and returns once every listener has received the auth
  // state it emits, on the same ordering as announce().
  Future<void> announcingAuthState(FutureOr<void> Function() change) async {
    final delivered = authNotifier.onAuthStateChanged.first;
    await change();
    await delivered;
  }

  // Signs out through the auth manager, which announces no profile, as the
  // app's logout does; the auth state is the only word of it.
  Future<void> signOut() => announcingAuthState(authManager.logout);

  // Signs [user] in and starts a watcher, returning once the repository has
  // fetched the profile: the auth manager announces what it fetched as it
  // returns, after the repository has applied it.
  Future<void> watchSignedIn(User user) async {
    signIn(user);
    repository.watchPreferences().listen((_) {});
    await authNotifier.onUserProfileChanged.first;
  }

  setUp(() {
    final clock = FakeClockImpl();
    authNotifier = FakeAuthNotifier();
    authRepository = FakeAuthRepository(clock: clock);
    authManager = FakeAuthManager(
      authNotifier: authNotifier,
      authRepository: authRepository,
      wrapper: FakeSupabaseWrapper(clock: clock),
      clock: clock,
    );
    // The subject under test; resolving it through Modular would test the
    // module binding instead.
    // ignore: no_direct_instantiation
    repository = CalculatorPreferencesRepositoryImpl(
      authNotifier: authNotifier,
      authManager: authManager,
    );
  });

  tearDown(() {
    repository.dispose();
    authNotifier.dispose();
  });

  group('CalculatorPreferencesRepositoryImpl', () {
    group('watchPreferences', () {
      test('emits the defaults before any profile has arrived', () async {
        expect(
          await repository.watchPreferences().first,
          CalculatorPreferences.defaults,
        );
      });

      test(
        'starts on the profile already signed in, without waiting for a change',
        () async {
          signIn(
            userWith({
              'calculator': {'system': 'metric'},
            }),
          );

          await expectLater(
            repository.watchPreferences(),
            emitsInOrder([CalculatorPreferences.defaults, hasMetricSystem]),
          );
          expect(authRepository.getUserProfileCalls, ['cred-1']);
        },
      );

      test('does not fetch a profile for an empty credential id', () async {
        signIn(
          userWith({
            'calculator': {'system': 'metric'},
          }, credentialId: ''),
        );

        expect(
          await repository.watchPreferences().first,
          CalculatorPreferences.defaults,
        );
        final result = await repository.savePreferences(metric);

        expect(failureOf(result), isA<UserNotFoundFailure>());
        expect(authRepository.getUserProfileCalls, isEmpty);
      });

      test('emits the profile\'s settings when the profile changes', () async {
        final settings = expectLater(
          repository.watchPreferences(),
          emitsInOrder([CalculatorPreferences.defaults, metric]),
        );

        await announce(
          userWith({
            'calculator': {
              'system': 'metric',
              'fractional_resolution': 2,
              'metre_display': 3,
              'pounds_per_ton': 2240,
              'density_unit': 'kilogramsPerCubicMetre',
            },
          }),
        );

        await settings;
      });

      test('a new watcher gets the current settings at once', () async {
        final followed = expectLater(
          repository.watchPreferences(),
          emitsThrough(hasMetricSystem),
        );
        await announce(
          userWith({
            'calculator': {'system': 'metric'},
          }),
        );
        await followed;

        expect(await repository.watchPreferences().first, hasMetricSystem);
      });

      test(
        'collapses a profile change that leaves the settings as they were',
        () async {
          final settings = expectLater(
            repository.watchPreferences(),
            emitsInOrder([CalculatorPreferences.defaults, hasMetricSystem]),
          );

          await announce(userWith({'theme': 'dark'}));
          await announce(userWith({'theme': 'light'}));
          await announce(
            userWith({
              'calculator': {'system': 'metric'},
            }),
          );

          await settings;
        },
      );

      test('reads the prototype\'s keys off an old profile', () async {
        final settings = expectLater(
          repository.watchPreferences(),
          emitsInOrder([
            CalculatorPreferences.defaults,
            isA<CalculatorPreferences>().having(
              (preferences) => preferences.fractionResolution,
              'fractionResolution',
              FractionResolution.sixtyFourth,
            ),
          ]),
        );

        await announce(
          userWith({
            'calculator': {'fracRes': 64},
          }),
        );

        await settings;
      });

      test(
        'falls back to the defaults on sign-out, and the next user signed in '
        'on the device gets their own profile',
        () async {
          await watchSignedIn(
            userWith({
              'calculator': {'system': 'metric'},
            }),
          );
          final settings = expectLater(
            repository.watchPreferences(),
            emitsInOrder([
              hasMetricSystem,
              CalculatorPreferences.defaults,
              metric,
            ]),
          );

          await signOut();

          expect(
            await repository.watchPreferences().first,
            CalculatorPreferences.defaults,
          );
          expect(
            failureOf(await repository.savePreferences(metric)),
            isA<UserNotFoundFailure>(),
          );
          expect(authRepository.updateProfileCalls, isEmpty);

          await announcingAuthState(
            () => signIn(userWith({'theme': 'dark'}, credentialId: 'cred-2')),
          );
          final saved = await repository.savePreferences(metric);

          await settings;
          expect(savedOf(saved), metric);
          expect(authRepository.getUserProfileCalls, ['cred-1', 'cred-2']);
          final written = authRepository.updateProfileCalls.single;
          expect(written.credentialId, 'cred-2');
          expect(written.userPreferences['theme'], 'dark');
        },
      );

      test('forgets the previous user when another credential signs in, even '
          'before the auth state has arrived', () async {
        await watchSignedIn(
          userWith({
            'calculator': {'system': 'metric'},
          }),
        );
        signIn(userWith({'theme': 'dark'}, credentialId: 'cred-2'));

        final saved = await repository.savePreferences(metric);

        expect(savedOf(saved), metric);
        expect(authRepository.getUserProfileCalls, ['cred-1', 'cred-2']);
        final written = authRepository.updateProfileCalls.single;
        expect(written.credentialId, 'cred-2');
        expect(written.userPreferences['theme'], 'dark');
      });

      test('keeps the profile through a lost connection', () async {
        await watchSignedIn(
          userWith({
            'calculator': {'system': 'metric'},
          }),
        );

        await announcingAuthState(
          () => authNotifier.emitAuthStateChanged(
            const AuthState(status: AuthStatus.connectionError),
          ),
        );

        expect(await repository.watchPreferences().first, hasMetricSystem);
        expect(savedOf(await repository.savePreferences(metric)), metric);
        expect(authRepository.getUserProfileCalls, ['cred-1']);
      });

      test('drops a fetch still in flight when another user signs in, and '
          'shares that user\'s fetch', () async {
        signIn(
          userWith({
            'calculator': {'system': 'metric'},
          }),
        );
        final firstUserFetch = Completer<void>();
        authRepository.getUserProfileGate = firstUserFetch;
        final settings = expectLater(
          repository.watchPreferences(),
          emitsInOrder([CalculatorPreferences.defaults, metric]),
        );

        await announcingAuthState(
          () => signIn(userWith({'theme': 'dark'}, credentialId: 'cred-2')),
        );
        final nextUserFetch = Completer<void>();
        authRepository.getUserProfileGate = nextUserFetch;
        final firstSave = repository.savePreferences(metric);
        final firstUserEchoed = authNotifier.onUserProfileChanged.first;
        firstUserFetch.complete();
        await firstUserEchoed;
        final secondSave = repository.savePreferences(metric);
        nextUserFetch.complete();

        expect(savedOf(await firstSave), metric);
        expect(savedOf(await secondSave), metric);
        await settings;
        expect(authRepository.getUserProfileCalls, ['cred-1', 'cred-2']);
        expect(
          authRepository.updateProfileCalls.map((user) => user.credentialId),
          ['cred-2', 'cred-2'],
        );
        expect(
          authRepository.updateProfileCalls.first.userPreferences['theme'],
          'dark',
        );
      });

      test('a change announced during the first fetch wins over the older '
          'fetched profile', () async {
        signIn(
          userWith({
            'theme': 'light',
            'calculator': {'system': 'imperial'},
          }),
        );
        final gate = Completer<void>();
        authRepository.getUserProfileGate = gate;
        final settings = expectLater(
          repository.watchPreferences(),
          emitsInOrder([
            CalculatorPreferences.defaults,
            hasMetricSystem,
            emitsDone,
          ]),
        );
        final newer = userWith({
          'theme': 'dark',
          'calculator': {'system': 'metric'},
        });
        authRepository.setUserProfile(newer);

        await announce(newer);
        final echoed = authNotifier.onUserProfileChanged.first;
        gate.complete();
        await echoed;
        await repository.savePreferences(metric);
        repository.dispose();

        await settings;
        expect(authRepository.getUserProfileCalls, ['cred-1']);
        expect(
          authRepository.updateProfileCalls.single.userPreferences['theme'],
          'dark',
        );
      });

      test('takes the profile another fetch announces after signing in again, '
          'rather than dropping it as the first fetch\'s echo', () async {
        final user = userWith({
          'calculator': {'system': 'metric'},
        });
        await watchSignedIn(user);
        await signOut();
        final settings = expectLater(
          repository.watchPreferences(),
          emitsInOrder([CalculatorPreferences.defaults, hasMetricSystem]),
        );

        await announcingAuthState(() => signIn(user));
        await authManager.getUserProfile('cred-1');

        await settings;
      });

      test('does not follow the profile again after dispose', () async {
        signIn(
          userWith({
            'calculator': {'system': 'metric'},
          }),
        );
        repository.dispose();

        expect(
          await repository.watchPreferences().first,
          CalculatorPreferences.defaults,
        );
        expect(authRepository.getUserProfileCalls, isEmpty);
      });

      test('a profile that arrives after dispose is dropped', () async {
        signIn(
          userWith({
            'calculator': {'system': 'metric'},
          }),
        );
        final gate = Completer<void>();
        authRepository.getUserProfileGate = gate;
        repository.watchPreferences().listen((_) {});
        repository.dispose();

        final echoed = authNotifier.onUserProfileChanged.first;
        gate.complete();
        await echoed;

        expect(authRepository.getUserProfileCalls, ['cred-1']);
        expect(
          await repository.watchPreferences().first,
          CalculatorPreferences.defaults,
        );
      });

      test('ends the streams it handed out on dispose', () async {
        final ended = expectLater(
          repository.watchPreferences(),
          emitsInOrder([CalculatorPreferences.defaults, emitsDone]),
        );

        repository.dispose();

        await ended;
      });

      test('stops listening to the auth library on dispose', () async {
        repository.watchPreferences().listen((_) {});
        expect(authNotifier.hasUserProfileListeners, isTrue);
        expect(authNotifier.hasAuthStateListeners, isTrue);

        repository.dispose();

        expect(authNotifier.hasUserProfileListeners, isFalse);
        expect(authNotifier.hasAuthStateListeners, isFalse);
      });
    });

    group('savePreferences', () {
      test('fails when no profile is signed in', () async {
        final result = await repository.savePreferences(metric);
        expect(result, isA<Left<Failure, CalculatorPreferences>>());
        expect(failureOf(result), isA<UserNotFoundFailure>());
      });

      test('fails when the credentials cannot be read', () async {
        signIn(userWith({}));
        authManager.setAuthResponse(
          succeed: false,
          errorType: AuthErrorType.networkError,
        );

        final result = await repository.savePreferences(metric);

        expect(failureOf(result), isA<UserNotFoundFailure>());
        expect(authRepository.updateProfileCalls, isEmpty);
      });

      test('answers the fetch\'s failure when the credentials are read but the '
          'profile fetch fails', () async {
        signIn(userWith({}));
        authManager.getUserProfileErrorType = AuthErrorType.networkError;

        final result = await repository.savePreferences(metric);

        expect(
          failureOf(result),
          isA<AuthFailure>().having(
            (failure) => failure.errorType,
            'errorType',
            AuthErrorType.networkError,
          ),
        );
        expect(authRepository.updateProfileCalls, isEmpty);
      });

      test('fetches again on the next save after a failed fetch', () async {
        signIn(userWith({'theme': 'dark'}));
        authManager.getUserProfileErrorType = AuthErrorType.networkError;
        await repository.savePreferences(metric);
        authManager.getUserProfileErrorType = null;

        final result = await repository.savePreferences(metric);

        expect(savedOf(result), metric);
        expect(authRepository.getUserProfileCalls, ['cred-1']);
      });

      test('saves to the profile already signed in before any watcher, '
          'fetching it once', () async {
        signIn(userWith({'theme': 'dark'}));

        final result = await repository.savePreferences(metric);

        expect(savedOf(result), metric);
        expect(authRepository.getUserProfileCalls, ['cred-1']);
        final written =
            authRepository.updateProfileCalls.single.userPreferences;
        expect(written['theme'], 'dark');
        expect(
          written['calculator'],
          CalculatorPreferencesDto(metric).toJson(),
        );
      });

      test('writes the settings under the calculator key and keeps the other '
          'keys, without reading the profile again', () async {
        await watchSignedIn(
          userWith({
            'theme': 'dark',
            'calculator': {'fracRes': 8, 'lenFormat': 'std'},
          }),
        );

        final result = await repository.savePreferences(metric);

        expect(savedOf(result), metric);
        expect(authRepository.getUserProfileCalls, ['cred-1']);
        final written =
            authRepository.updateProfileCalls.single.userPreferences;
        expect(written['theme'], 'dark');
        expect(written['calculator'], {
          'system': 'metric',
          'fractional_resolution': 2,
          'metre_display': 3,
          'pounds_per_ton': 2240,
          'density_unit': 'kilogramsPerCubicMetre',
        });
      });

      test(
        'every watcher sees a save, through the profile it re-emits',
        () async {
          signIn(userWith({}));
          final settings = expectLater(
            repository.watchPreferences(),
            emitsInOrder([CalculatorPreferences.defaults, metric]),
          );

          await repository.savePreferences(metric);

          await settings;
        },
      );

      test('answers not found when the profile row is gone', () async {
        await watchSignedIn(userWith({}));
        authRepository.removeUserProfile('cred-1');

        final result = await repository.savePreferences(metric);

        expect(failureOf(result), isA<UserNotFoundFailure>());
      });

      test(
        'answers an auth failure when the profile cannot be updated',
        () async {
          await watchSignedIn(userWith({}));
          authManager.setAuthResponse(
            succeed: false,
            errorType: AuthErrorType.networkError,
          );

          final result = await repository.savePreferences(metric);

          expect(
            failureOf(result),
            isA<AuthFailure>().having(
              (failure) => failure.errorType,
              'errorType',
              AuthErrorType.networkError,
            ),
          );
        },
      );
    });
  });
}

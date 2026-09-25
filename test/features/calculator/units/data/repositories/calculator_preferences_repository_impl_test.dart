import 'package:construculator/features/calculator/data/models/calculator_preferences_dto.dart';
import 'package:construculator/features/calculator/data/repositories/calculator_preferences_repository_impl.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
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

  User userWith(Map<String, dynamic> preferences) => User(
    id: 'user-1',
    credentialId: 'cred-1',
    email: 'jane@example.com',
    firstName: 'Jane',
    lastName: 'Smith',
    professionalRole: 'Estimator',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    userStatus: UserProfileStatus.active,
    userPreferences: preferences,
  );

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
          final seen = <CalculatorPreferences>[];
          final subscription = repository.watchPreferences().listen(seen.add);
          addTearDown(subscription.cancel);
          await pumpEventQueue();

          expect(seen.last.system, MeasurementSystem.metric);
          expect(authRepository.getUserProfileCalls, ['cred-1']);
        },
      );

      test('emits the profile\'s settings when the profile changes', () async {
        final seen = <CalculatorPreferences>[];
        final subscription = repository.watchPreferences().listen(seen.add);
        addTearDown(subscription.cancel);
        authNotifier.emitUserProfileChanged(
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
        await pumpEventQueue();
        expect(seen, [CalculatorPreferences.defaults, metric]);
      });

      test('a new watcher gets the current settings at once', () async {
        repository.watchPreferences().listen((_) {});
        authNotifier.emitUserProfileChanged(
          userWith({
            'calculator': {'system': 'metric'},
          }),
        );
        await pumpEventQueue();
        final first = await repository.watchPreferences().first;
        expect(first.system, MeasurementSystem.metric);
      });

      test(
        'collapses a profile change that leaves the settings as they were',
        () async {
          final seen = <CalculatorPreferences>[];
          final subscription = repository.watchPreferences().listen(seen.add);
          addTearDown(subscription.cancel);
          authNotifier.emitUserProfileChanged(userWith({'theme': 'dark'}));
          authNotifier.emitUserProfileChanged(userWith({'theme': 'light'}));
          await pumpEventQueue();
          expect(seen, [CalculatorPreferences.defaults]);
        },
      );

      test('reads the prototype\'s keys off an old profile', () async {
        final seen = <CalculatorPreferences>[];
        final subscription = repository.watchPreferences().listen(seen.add);
        addTearDown(subscription.cancel);
        authNotifier.emitUserProfileChanged(
          userWith({
            'calculator': {'fracRes': 64},
          }),
        );
        await pumpEventQueue();
        expect(seen.last.fractionResolution, FractionResolution.sixtyFourth);
      });

      test('falls back to the defaults when the user signs out', () async {
        final seen = <CalculatorPreferences>[];
        final subscription = repository.watchPreferences().listen(seen.add);
        addTearDown(subscription.cancel);
        authNotifier.emitUserProfileChanged(
          userWith({
            'calculator': {'system': 'metric'},
          }),
        );
        authNotifier.emitUserProfileChanged(null);
        await pumpEventQueue();
        expect(seen.last, CalculatorPreferences.defaults);
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
        authNotifier.emitUserProfileChanged(
          userWith({
            'calculator': {'system': 'metric'},
          }),
        );
        await pumpEventQueue();

        expect(authRepository.getUserProfileCalls, isEmpty);
        expect(
          await repository.watchPreferences().first,
          CalculatorPreferences.defaults,
        );
      });

      test('a profile that arrives after dispose is dropped', () async {
        signIn(
          userWith({
            'calculator': {'system': 'metric'},
          }),
        );
        repository.watchPreferences().listen((_) {});
        repository.dispose();
        await pumpEventQueue();

        expect(authRepository.getUserProfileCalls, ['cred-1']);
        expect(
          await repository.watchPreferences().first,
          CalculatorPreferences.defaults,
        );
      });

      test('ends the streams it handed out on dispose', () async {
        var done = false;
        repository.watchPreferences().listen((_) {}, onDone: () => done = true);
        repository.dispose();
        await pumpEventQueue();
        expect(done, isTrue);
      });
    });

    group('savePreferences', () {
      test('fails when no profile is signed in', () async {
        final result = await repository.savePreferences(metric);
        expect(result, isA<Left<Failure, CalculatorPreferences>>());
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<UserNotFoundFailure>(),
        );
      });

      test('fails when the signed-in profile cannot be fetched', () async {
        signIn(userWith({}));
        authManager.setAuthResponse(
          succeed: false,
          errorType: AuthErrorType.networkError,
        );

        final result = await repository.savePreferences(metric);

        expect(
          result.fold((failure) => failure, (_) => null),
          isA<UserNotFoundFailure>(),
        );
        expect(authRepository.updateProfileCalls, isEmpty);
      });

      test(
        'saves to the profile already signed in before any watcher',
        () async {
          signIn(userWith({'theme': 'dark'}));

          final result = await repository.savePreferences(metric);

          expect(result.fold((_) => null, (saved) => saved), metric);
          final written =
              authRepository.updateProfileCalls.single.userPreferences;
          expect(written['theme'], 'dark');
          expect(
            written['calculator'],
            CalculatorPreferencesDto(metric).toJson(),
          );
        },
      );

      test(
        'writes the settings under the calculator key and keeps the other keys',
        () async {
          final user = userWith({
            'theme': 'dark',
            'calculator': {'fracRes': 8, 'lenFormat': 'std'},
          });
          authRepository.setUserProfile(user);
          repository.watchPreferences().listen((_) {});
          authNotifier.emitUserProfileChanged(user);
          await pumpEventQueue();

          final result = await repository.savePreferences(metric);

          expect(result.fold((_) => null, (saved) => saved), metric);
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
        },
      );

      test(
        'every watcher sees a save, through the profile it re-emits',
        () async {
          final seen = <CalculatorPreferences>[];
          final subscription = repository.watchPreferences().listen(seen.add);
          addTearDown(subscription.cancel);
          final user = userWith({});
          authRepository.setUserProfile(user);
          authNotifier.emitUserProfileChanged(user);
          await pumpEventQueue();

          await repository.savePreferences(metric);
          await pumpEventQueue();

          expect(seen.last, metric);
        },
      );

      test('answers not found when the profile row is gone', () async {
        repository.watchPreferences().listen((_) {});
        authNotifier.emitUserProfileChanged(userWith({}));
        await pumpEventQueue();

        final result = await repository.savePreferences(metric);

        expect(
          result.fold((failure) => failure, (_) => null),
          isA<UserNotFoundFailure>(),
        );
      });

      test(
        'answers an auth failure when the profile cannot be updated',
        () async {
          repository.watchPreferences().listen((_) {});
          authNotifier.emitUserProfileChanged(userWith({}));
          await pumpEventQueue();
          authManager.setAuthResponse(
            succeed: false,
            errorType: AuthErrorType.networkError,
          );

          final result = await repository.savePreferences(metric);

          expect(
            result.fold((failure) => failure, (_) => null),
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

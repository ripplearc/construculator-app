import 'package:bloc_test/bloc_test.dart';
import 'package:construculator/features/consent/presentation/bloc/consent_gate_bloc/consent_gate_bloc.dart';
import 'package:construculator/features/consent/testing/consent_test_module.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeConsentRepository repository;

  final requiredVersion = ConsentVersion(
    id: 'version-2',
    consentType: ConsentType.termsAndPrivacy,
    version: 2,
    documentUrl: 'https://example.com/terms/v2',
    publishedAt: DateTime.utc(2026, 8, 11),
  );

  setUp(() {
    Modular.init(ConsentTestModule());
    repository = Modular.get<ConsentRepository>() as FakeConsentRepository;
  });

  tearDown(Modular.destroy);

  ConsentGateBloc buildBloc() => Modular.get<ConsentGateBloc>();

  /// Drives the local read and the verification to the same answer.
  ///
  /// The common case: verification confirms what the cache already said, so
  /// the gate settles on one state. Tests that are about the verification
  /// phase set the two apart explicitly.
  void resolveTo(ConsentStatus status) => repository
    ..cachedStatusToReturn = status
    ..verifiedStatusToReturn = status;

  group('on start', () {
    blocTest<ConsentGateBloc, ConsentGateState>(
      'allows through when consent is current',
      setUp: () => resolveTo(const ConsentSatisfied(2)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsentGateStarted()),
      expect: () => const [ConsentGateAllowed(2)],
    );

    blocTest<ConsentGateBloc, ConsentGateState>(
      'allows through when the check failed but an acceptance exists',
      setUp: () => resolveTo(const ConsentUnverified(2)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsentGateStarted()),
      expect: () => const [ConsentGateUnverified(2)],
    );

    blocTest<ConsentGateBloc, ConsentGateState>(
      'blocks with the document when a newer version is published',
      setUp: () => resolveTo(
        ConsentOutdated(acceptedVersion: 1, requiredVersion: requiredVersion),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsentGateStarted()),
      expect: () => [ConsentGateBlocked(requiredVersion)],
    );

    blocTest<ConsentGateBloc, ConsentGateState>(
      'blocks with the document when nothing was ever accepted',
      setUp: () => resolveTo(ConsentNeverGiven(requiredVersion)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsentGateStarted()),
      expect: () => [ConsentGateBlocked(requiredVersion)],
    );

    blocTest<ConsentGateBloc, ConsentGateState>(
      'shows the retry screen, not a prompt, when the requirement is unknown',
      // There is no document to name, so there is nothing to agree to.
      setUp: () => resolveTo(const ConsentIndeterminate()),
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsentGateStarted()),
      expect: () => const [ConsentGateUnavailable()],
    );
  });

  group('on verification', () {
    blocTest<ConsentGateBloc, ConsentGateState>(
      'interrupts when the server names a version the cache had not seen',
      // The point of the phase: a stalled sync must not let a stale local
      // answer keep the user in the app.
      setUp: () => repository
        ..cachedStatusToReturn = const ConsentSatisfied(1)
        ..verifiedStatusToReturn = ConsentOutdated(
          acceptedVersion: 1,
          requiredVersion: requiredVersion,
        ),
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsentGateStarted()),
      expect: () => [
        const ConsentGateAllowed(1),
        ConsentGateBlocked(requiredVersion),
      ],
    );

    blocTest<ConsentGateBloc, ConsentGateState>(
      'falls open when verification fails but an acceptance is on file',
      // The only path that can report ConsentUnverified, and the half of the
      // matrix that was unreachable before the phase was dispatched.
      setUp: () => repository
        ..cachedStatusToReturn = const ConsentSatisfied(2)
        ..verifiedStatusToReturn = const ConsentUnverified(2),
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsentGateStarted()),
      expect: () => const [
        ConsentGateAllowed(2),
        ConsentGateUnverified(2),
      ],
    );

    blocTest<ConsentGateBloc, ConsentGateState>(
      'verifies the type the gate governs',
      setUp: () => resolveTo(const ConsentSatisfied(2)),
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsentGateStarted()),
      verify: (_) => expect(repository.verificationRequests, [
        ConsentType.termsAndPrivacy,
      ]),
    );
  });

  group('on accept', () {
    blocTest<ConsentGateBloc, ConsentGateState>(
      'shows the loading indicator then lets the user through',
      build: buildBloc,
      act: (bloc) => bloc.add(ConsentGateAccepted(requiredVersion)),
      expect: () => [
        ConsentGateSubmitting(requiredVersion),
        const ConsentGateAllowed(2),
      ],
    );

    blocTest<ConsentGateBloc, ConsentGateState>(
      'records the version the user was actually shown',
      build: buildBloc,
      act: (bloc) => bloc.add(ConsentGateAccepted(requiredVersion)),
      verify: (_) => expect(repository.recordedAcceptances, [
        (consentType: ConsentType.termsAndPrivacy, version: 2),
      ]),
    );

    blocTest<ConsentGateBloc, ConsentGateState>(
      'keeps the user on the page when the write fails',
      // Letting them through would mean running on consent never recorded.
      setUp: () => repository.acceptanceResultToReturn = const Left(
        ConsentFailure(errorType: ConsentErrorType.connectionError),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(ConsentGateAccepted(requiredVersion)),
      expect: () => [
        ConsentGateSubmitting(requiredVersion),
        ConsentGateSubmitFailed(requiredVersion),
      ],
    );
  });

  group('on watched status change', () {
    blocTest<ConsentGateBloc, ConsentGateState>(
      're-gates when a version is published mid-session',
      setUp: () {
        repository.cachedStatusToReturn = const ConsentSatisfied(1);
        repository.statusStreamToReturn = Stream.fromIterable([
          ConsentOutdated(
              acceptedVersion: 1,
              requiredVersion: requiredVersion,
            ),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsentGateStarted()),
      expect: () => [
        const ConsentGateAllowed(1),
        ConsentGateBlocked(requiredVersion),
      ],
    );

    blocTest<ConsentGateBloc, ConsentGateState>(
      'ignores repeated identical statuses',
      // An unrelated write to the consent history must not churn the UI.
      setUp: () {
        repository.cachedStatusToReturn = const ConsentSatisfied(1);
        repository.statusStreamToReturn = Stream.fromIterable(const [
          ConsentSatisfied(1),
          ConsentSatisfied(1),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsentGateStarted()),
      expect: () => const [ConsentGateAllowed(1)],
    );
  });

  group('on retry', () {
    blocTest<ConsentGateBloc, ConsentGateState>(
      're-resolves the status',
      setUp: () => resolveTo(const ConsentIndeterminate()),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ConsentGateStarted());
        // Wait for the first resolution to land before changing what the
        // repository reports, so the retry observes the new value.
        await bloc.stream.firstWhere((s) => s is ConsentGateUnavailable);
        resolveTo(const ConsentSatisfied(2));
        bloc.add(const ConsentGateRetryRequested());
      },
      expect: () => const [
        ConsentGateUnavailable(),
        ConsentGateChecking(),
        ConsentGateAllowed(2),
      ],
    );
  });
}

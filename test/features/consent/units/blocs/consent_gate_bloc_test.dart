import 'dart:async';

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
      expect: () => const [ConsentGateAllowed(2), ConsentGateUnverified(2)],
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

    blocTest<ConsentGateBloc, ConsentGateState>(
      'degrades to unverified rather than blocking when a verify tick is '
      'indeterminate after the cache already allowed the user through',
      // The status source (watch or verify) cannot tell "nothing to compare
      // against" apart from "a row was dropped as unreadable" -- but this
      // bloc already knows the user is standing on an acceptance, so it must
      // not revoke access on evidence that only means "could not check".
      setUp: () => repository
        ..cachedStatusToReturn = const ConsentSatisfied(2)
        ..verifiedStatusToReturn = const ConsentIndeterminate(),
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsentGateStarted()),
      expect: () => const [ConsentGateAllowed(2), ConsentGateUnverified(2)],
    );

    blocTest<ConsentGateBloc, ConsentGateState>(
      'does not overwrite an accept that completes during a slow verify '
      'with the verify\'s now-stale result',
      // verifyPublishedVersion reads the local acceptance before its round
      // trip, so an accept that starts and finishes entirely inside this
      // await is invisible to what it returns. Holding verify open lets the
      // accept flow run to completion first, proving the guard catches the
      // race rather than merely not needing to.
      setUp: () => repository
        ..cachedStatusToReturn = const ConsentSatisfied(1)
        ..verifiedStatusToReturn = ConsentOutdated(
          acceptedVersion: 1,
          requiredVersion: requiredVersion,
        )
        ..verificationCompleter = Completer<void>(),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const ConsentGateStarted());
        // Verify is now blocked on the completer; the cached read has
        // already landed and the accept flow is free to run to completion.
        await bloc.stream.firstWhere((s) => s is ConsentGateAllowed);
        bloc.add(ConsentGateAccepted(requiredVersion));
        await bloc.stream.firstWhere(
          (s) => s is ConsentGateAllowed && s.acceptedVersion == 2,
        );
        // Only now does the stale verify get to resolve.
        repository.verificationCompleter!.complete();
      },
      expect: () => [
        const ConsentGateAllowed(1),
        ConsentGateSubmitting(requiredVersion),
        const ConsentGateAllowed(2),
        // No further emission: the verify's ConsentGateBlocked(v2) result
        // must be discarded, not appended here.
      ],
    );
  });

  group('on watched status change, standing on an acceptance', () {
    blocTest<ConsentGateBloc, ConsentGateState>(
      'degrades to unverified rather than blocking on an indeterminate tick',
      setUp: () {
        repository.cachedStatusToReturn = const ConsentSatisfied(1);
        // Matches the cached read, so the verify phase's own emission
        // (already covered above) doesn't interfere with observing the
        // watch tick in isolation.
        repository.verifiedStatusToReturn = const ConsentSatisfied(1);
        repository.statusStreamToReturn = Stream<ConsentStatus>.fromIterable(
          const [ConsentIndeterminate()],
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsentGateStarted()),
      expect: () => const [
        ConsentGateAllowed(1), // cached read
        ConsentGateUnverified(1), // watch tick degrades, does not block
      ],
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
          ConsentOutdated(acceptedVersion: 1, requiredVersion: requiredVersion),
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
      setUp: () => repository
        ..cachedStatusToReturn = const ConsentIndeterminate()
        ..verifiedStatusToReturn = const ConsentIndeterminate()
        // Held open for the whole test and never completed. This test is
        // about retry re-running the cached-read phase (verify has its own
        // coverage above); with cached and verified set to the identical
        // status, the verify phase's own emission would be indistinguishable
        // from the cached-read's, and completing it at any point risks it
        // reading the repository's post-mutation value instead of the one it
        // started with -- the exact race this file's other race-protection
        // test is about. Leaving it permanently pending keeps both the
        // initial call's and the retry's verify phase from emitting at all.
        ..verificationCompleter = Completer<void>(),
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

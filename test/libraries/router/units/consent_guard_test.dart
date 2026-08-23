import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:construculator/libraries/router/guards/consent_guard.dart';
import 'package:construculator/libraries/router/routes/consent_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeConsentRepository repository;
  late ConsentGuard guard;

  final publishedVersion = ConsentVersion(
    id: 'version-2',
    consentType: ConsentType.termsAndPrivacy,
    version: 2,
    documentUrl: 'https://example.com/terms/v2',
    publishedAt: DateTime.utc(2026, 8, 11),
  );

  setUp(() {
    repository = FakeConsentRepository();
    guard = ConsentGuard(() => CheckConsentStatusUseCase(repository));
  });

  // ignore: no_direct_instantiation
  final route = ChildRoute('/', child: (_) => const SizedBox());

  Future<bool> canActivate() => guard.canActivate('/', route);

  group('ConsentGuard', () {
    test('admits a user whose consent is current', () async {
      repository.cachedStatusToReturn = const ConsentSatisfied(2);

      expect(await canActivate(), isTrue);
    });

    test(
      'admits a user whose check failed but who accepted previously',
      () async {
        // Failing open here is the design's single leniency, and it is what
        // keeps the app usable on a site with no signal.
        repository.cachedStatusToReturn = const ConsentUnverified(2);

        expect(await canActivate(), isTrue);
      },
    );

    test('blocks a user whose accepted version is superseded', () async {
      repository.cachedStatusToReturn = ConsentOutdated(
        acceptedVersion: 1,
        requiredVersion: publishedVersion,
      );

      expect(await canActivate(), isFalse);
    });

    test('blocks a user who has never accepted', () async {
      repository.cachedStatusToReturn = ConsentNeverGiven(publishedVersion);

      expect(await canActivate(), isFalse);
    });

    test('blocks when the requirement could not be established', () async {
      repository.cachedStatusToReturn = const ConsentIndeterminate();

      expect(await canActivate(), isFalse);
    });

    test('blocks a signed-in user with no internal user id, rather than '
        'reading the synthetic marker as an acceptance', () async {
      // AuthGuard running first only proves an auth session exists; it
      // says nothing about whether app_metadata.internal_user_id has
      // propagated to that session's JWT yet. The repository answers that
      // gap with ConsentSatisfied(noUserVersion) -- a synthetic "cannot
      // identify the user" marker, not a real acceptance -- and this is
      // the one production case where the guard receives it despite
      // AuthGuard having already passed.
      repository.cachedStatusToReturn = const ConsentSatisfied(
        ConsentRepository.noUserVersion,
      );

      expect(await canActivate(), isFalse);
    });

    // A genuinely-accepted ConsentSatisfied can never carry version 0 in
    // practice (published versions start at 1, enforced by
    // ConsentVersionDto.fromJson), so there is no case where this guard
    // needs to -- or could -- tell a real acceptance apart from the
    // synthetic marker: they are the identical value. That overload is the
    // known, documented limitation ConsentSatisfied's own dartdoc names;
    // resolving it needs a distinct sealed state upstream, not a guard-level
    // fix.

    test('asks only about terms and privacy', () async {
      // Analytics consent must never gate the app.
      await canActivate();

      expect(repository.cachedStatusRequests, [ConsentType.termsAndPrivacy]);
    });

    test('redirects to the consent gate', () {
      expect(guard.redirectTo, fullConsentGateRoute);
    });

    test('resolves the use case per call rather than holding one', () async {
      // The guard is constructed at module-registration time, before the
      // injector can supply a use case, so it must resolve lazily.
      var resolutions = 0;
      final lazyGuard = ConsentGuard(() {
        resolutions++;
        return CheckConsentStatusUseCase(repository);
      });

      await lazyGuard.canActivate('/', route);
      await lazyGuard.canActivate('/', route);

      expect(resolutions, 2);
    });
  });
}

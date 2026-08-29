import 'dart:async';

import 'package:construculator/features/consent/presentation/bloc/consent_gate_bloc/consent_gate_bloc.dart';
import 'package:construculator/features/consent/presentation/pages/consent_gate_page.dart';
import 'package:construculator/features/consent/testing/consent_test_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 844);
  const ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeConsentRepository repository;

  final requiredVersion = ConsentVersion(
    id: 'version-2',
    consentType: ConsentType.termsAndPrivacy,
    version: 2,
    documentUrl: 'https://example.com/terms/v2',
    publishedAt: DateTime.utc(2026, 8, 11),
  );

  setUp(() async {
    await loadAppFonts();
    Modular.init(ConsentTestModule());
    repository = Modular.get<ConsentRepository>() as FakeConsentRepository;
  });

  tearDown(Modular.destroy);

  Future<void> pumpPage(
    WidgetTester tester, {
    bool documentLinksAvailable = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<ConsentGateBloc>(
          create: (_) =>
              Modular.get<ConsentGateBloc>()..add(const ConsentGateStarted()),
          child: ConsentGatePage(
            router: Modular.get<AppRouter>(),
            onOpenDocument: (_) {},
            documentLinksAvailable: documentLinksAvailable,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ConsentGatePage Screenshot Tests', () {
    testWidgets('renders the prompt when blocked on a new version', (
      tester,
    ) async {
      repository.resolveTo(
        ConsentOutdated(acceptedVersion: 1, requiredVersion: requiredVersion),
      );

      await pumpPage(tester);

      await expectLater(
        find.byType(ConsentGatePage),
        matchesGoldenFile(
          'goldens/consent_gate_page/${size.width}x${size.height}/consent_gate_page_blocked.png',
        ),
      );
    });

    testWidgets('renders the loading indicator while submitting', (
      tester,
    ) async {
      repository.resolveTo(ConsentNeverGiven(requiredVersion));
      final inFlight = Completer<void>();
      repository.acceptanceCompleter = inFlight;

      await pumpPage(tester);
      await tester.tap(find.byKey(const Key('consentGateAcceptButton')));
      // A single pump freezes the indicator's deterministic pre-load frame —
      // the Lottie composition loads asynchronously and never resolves inside
      // the fake-async zone, matching project_creation_screen_screenshot_test.
      // The golden therefore shows an empty band where the accept button was,
      // not a spinner: it asserts the button is gone and the indicator holds
      // its 80px of space. The indicator's presence is asserted in
      // consent_gate_page_test.dart instead.
      await tester.pump();

      await expectLater(
        find.byType(ConsentGatePage),
        matchesGoldenFile(
          'goldens/consent_gate_page/${size.width}x${size.height}/consent_gate_page_submitting.png',
        ),
      );

      inFlight.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('renders the inline error after a failed write', (
      tester,
    ) async {
      repository
        ..verifiedStatusToReturn = ConsentNeverGiven(requiredVersion)
        ..cachedStatusToReturn = ConsentNeverGiven(requiredVersion)
        ..acceptanceResultToReturn = const Left(
          ConsentFailure(errorType: ConsentErrorType.connectionError),
        );

      await pumpPage(tester);
      await tester.tap(find.byKey(const Key('consentGateAcceptButton')));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ConsentGatePage),
        matchesGoldenFile(
          'goldens/consent_gate_page/${size.width}x${size.height}/consent_gate_page_submit_failed.png',
        ),
      );
    });

    testWidgets('renders the prompt with the document links hidden', (
      tester,
    ) async {
      // The only configuration production ships today: consent_module.dart
      // passes documentLinksAvailable: false until the URL launcher lands
      // (CA-1024). Every other golden here renders with the default true, so
      // without this one nothing captures what a real user actually sees.
      repository.resolveTo(
        ConsentOutdated(acceptedVersion: 1, requiredVersion: requiredVersion),
      );

      await pumpPage(tester, documentLinksAvailable: false);

      await expectLater(
        find.byType(ConsentGatePage),
        matchesGoldenFile(
          'goldens/consent_gate_page/${size.width}x${size.height}/consent_gate_page_links_hidden.png',
        ),
      );
    });

    testWidgets('renders the retry screen when the requirement is unknown', (
      tester,
    ) async {
      // The state that matters most to get right and had zero pixel
      // coverage: it is what a user sees offline or on a version lookup
      // failure -- hard-blocked, single button, nothing else on screen --
      // and #547 maps ConsentIndeterminate here unconditionally whenever a
      // prior state doesn't exist, so it's reachable far more often than
      // "the backend is down."
      repository.resolveTo(
        const ConsentIndeterminate(ConsentType.termsAndPrivacy),
      );

      await pumpPage(tester);

      await expectLater(
        find.byType(ConsentGatePage),
        matchesGoldenFile(
          'goldens/consent_gate_page/${size.width}x${size.height}/consent_gate_page_unavailable.png',
        ),
      );
    });
  });
}

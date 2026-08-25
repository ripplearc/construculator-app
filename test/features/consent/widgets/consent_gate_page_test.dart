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
import 'package:construculator/libraries/router/routes/shell_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  late FakeConsentRepository repository;
  late FakeAppRouter router;

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
    // The fake router outlives Modular.destroy, so its history would
    // otherwise carry over from the previous test.
    router = Modular.get<AppRouter>() as FakeAppRouter..reset();
  });

  tearDown(Modular.destroy);

  /// Drives the local read and the verification to the same answer.
  ///
  /// The gate's third phase re-emits after confirming against the server, so a
  /// fixture that sets only the cached status would be superseded before the
  /// page finished rendering it.
  void resolveTo(ConsentStatus status) => repository
    ..cachedStatusToReturn = status
    ..verifiedStatusToReturn = status;


  Widget buildPage({ThemeData? theme, List<String> openedUrls = const []}) {
    return MaterialApp(
      theme: theme ?? createTestTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<ConsentGateBloc>(
        create: (_) =>
            Modular.get<ConsentGateBloc>()..add(const ConsentGateStarted()),
        child: ConsentGatePage(
          router: router,
          onOpenDocument: openedUrls.add,
        ),
      ),
    );
  }

  group('when a new version is published', () {
    setUp(
      () => resolveTo(
        ConsentOutdated(acceptedVersion: 1, requiredVersion: requiredVersion),
      ),
    );

    testWidgets('renders the prompt with both document links', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('consentGateTitle')), findsOneWidget);
      expect(find.byKey(const Key('consentGateTermsLink')), findsOneWidget);
      expect(find.byKey(const Key('consentGatePrivacyLink')), findsOneWidget);
      expect(find.byKey(const Key('consentGateAcceptButton')), findsOneWidget);
    });

    testWidgets('offers no back affordance', (tester) async {
      // A consent screen the user can dismiss is not a consent screen.
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('blocks the system back gesture', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      final popScope = tester.widget<PopScope<Object?>>(
        find.byType(PopScope<Object?>),
      );
      expect(popScope.canPop, isFalse);
    });

    testWidgets('swaps the button for a loading indicator while submitting', (
      tester,
    ) async {
      // Hold the write open, otherwise the submitting state resolves within
      // the same frame it is entered and there is nothing to observe.
      final inFlight = Completer<void>();
      repository.acceptanceCompleter = inFlight;

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('consentGateAcceptButton')));
      await tester.pump();

      expect(find.byType(CoreLoadingIndicator), findsOneWidget);
      expect(find.byKey(const Key('consentGateAcceptButton')), findsNothing);

      inFlight.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('leaves for the shell once the acceptance lands', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('consentGateAcceptButton')));
      await tester.pumpAndSettle();

      expect(router.navigationHistory.map((c) => c.route), contains(shellRoute));
    });
  });

  group('when the requirement cannot be established', () {
    setUp(
      () => resolveTo(const ConsentIndeterminate(ConsentType.termsAndPrivacy)),
    );

    testWidgets('renders a retry screen rather than a consent prompt', (
      tester,
    ) async {
      // There is no document to name, so there is nothing to agree to.
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('consentUnavailableTitle')), findsOneWidget);
      expect(
        find.byKey(const Key('consentUnavailableRetryButton')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('consentGateAcceptButton')), findsNothing);
      expect(find.byKey(const Key('consentGateTermsLink')), findsNothing);
    });
  });

  group('when the acceptance write fails', () {
    testWidgets('keeps the user on the page with an inline error', (
      tester,
    ) async {
      repository
        ..verifiedStatusToReturn = ConsentNeverGiven(requiredVersion)
        ..cachedStatusToReturn = ConsentNeverGiven(requiredVersion)
        ..acceptanceResultToReturn = const Left(
          ConsentFailure(errorType: ConsentErrorType.connectionError),
        );

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('consentGateAcceptButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('consentGateSubmitError')), findsOneWidget);
      expect(find.byKey(const Key('consentGateAcceptButton')), findsOneWidget);
      expect(router.navigationHistory.map((c) => c.route), isNot(contains(shellRoute)));
    });
  });

  group('when consent is already current', () {
    testWidgets('renders nothing and leaves for the shell', (tester) async {
      // Resolving from cache completes within a frame, so a spinner here would
      // only flash.
      resolveTo(const ConsentSatisfied(2));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(CoreLoadingIndicator), findsNothing);
      expect(router.navigationHistory.map((c) => c.route), contains(shellRoute));
    });
  });

  group('when verification fails but a prior acceptance is on file', () {
    testWidgets('renders nothing and leaves for the shell', (tester) async {
      // The fail-open path: nothing is wrong from the user's point of view,
      // so it must be indistinguishable from the fully-satisfied path here.
      resolveTo(const ConsentUnverified(2));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(CoreLoadingIndicator), findsNothing);
      expect(router.navigationHistory.map((c) => c.route), contains(shellRoute));
    });
  });
}

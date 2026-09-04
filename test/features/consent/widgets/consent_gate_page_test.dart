import 'dart:async';

import 'package:construculator/features/consent/presentation/bloc/consent_gate_bloc/consent_gate_bloc.dart';
import 'package:construculator/features/consent/presentation/pages/consent_gate_page.dart';
import 'package:construculator/features/consent/presentation/widgets/consent_document_links.dart';
import 'package:construculator/features/consent/testing/consent_test_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/router/guards/consent_guard.dart';
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

  Widget buildPage({
    ThemeData? theme,
    List<String> openedUrls = const [],
    bool documentLinksAvailable = true,
  }) {
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
          documentLinksAvailable: documentLinksAvailable,
        ),
      ),
    );
  }

  group('when a new version is published', () {
    setUp(
      () => repository.resolveTo(
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

  group('when the launcher cannot open a document', () {
    // The configuration production actually wires: consent_module.dart
    // passes documentLinksAvailable: false because onOpenDocument is a no-op
    // until CA-1024 lands. A link that announces as a link to a screen reader
    // and gives tap feedback but opens nothing is undetectable to the user,
    // so the gate hides the links rather than rendering them dead.
    setUp(
      () => repository.resolveTo(
        ConsentOutdated(acceptedVersion: 1, requiredVersion: requiredVersion),
      ),
    );

    testWidgets('hides both document links', (tester) async {
      await tester.pumpWidget(buildPage(documentLinksAvailable: false));
      await tester.pumpAndSettle();

      expect(find.byType(ConsentDocumentLinks), findsNothing);
      expect(find.byKey(const Key('consentGateTermsLink')), findsNothing);
      expect(find.byKey(const Key('consentGatePrivacyLink')), findsNothing);
    });

    testWidgets('leaves the way off the screen intact', (tester) async {
      // Hiding the links must not take the accept path with them; this is a
      // gate the user cannot otherwise leave.
      await tester.pumpWidget(buildPage(documentLinksAvailable: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('consentGateTitle')), findsOneWidget);
      expect(find.byKey(const Key('consentGateAcceptButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('consentGateAcceptButton')));
      await tester.pumpAndSettle();

      expect(router.navigationHistory.map((c) => c.route), contains(shellRoute));
    });

    testWidgets('keeps them hidden while an acceptance is in flight', (
      tester,
    ) async {
      // The flag forwards to all three ConsentPrompt call sites in the page,
      // not only the blocked one, so hiding must not depend on the state.
      final inFlight = Completer<void>();
      repository.acceptanceCompleter = inFlight;

      await tester.pumpWidget(buildPage(documentLinksAvailable: false));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('consentGateAcceptButton')));
      await tester.pump();

      expect(find.byType(ConsentDocumentLinks), findsNothing);

      inFlight.complete();
      await tester.pumpAndSettle();
    });
  });

  group('when the requirement cannot be established', () {
    setUp(
      () => repository.resolveTo(
        const ConsentIndeterminate(ConsentType.termsAndPrivacy),
      ),
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

    testWidgets('retrying re-runs the check and lifts the gate once it '
        'resolves', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      repository.resolveTo(const ConsentSatisfied(2));
      await tester.tap(
        find.byKey(const Key('consentUnavailableRetryButton')),
      );
      await tester.pumpAndSettle();

      expect(router.navigationHistory.map((c) => c.route), contains(shellRoute));
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
      repository.resolveTo(const ConsentSatisfied(2));

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
      repository.resolveTo(const ConsentUnverified(2));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(CoreLoadingIndicator), findsNothing);
      expect(router.navigationHistory.map((c) => c.route), contains(shellRoute));
    });
  });

  group('when the session carries no internal user id', () {
    // The one status the guard decides on its own rather than through
    // gatesAccess, so it is the one status the guard and this page can
    // disagree about. They are driven together here, against a single
    // repository, because either half read alone looks correct: the guard
    // blocking is right, and the page leaving for the shell is right for
    // every other ConsentSatisfied. Only the pair shows the loop.
    late ConsentGuard guard;

    setUp(() {
      repository.resolveTo(
        const ConsentSatisfied(ConsentRepository.noUserVersion),
      );
      guard = ConsentGuard(() => Modular.get<CheckConsentStatusUseCase>());
    });

    testWidgets('the guard blocks and the gate does not bounce back', (
      tester,
    ) async {
      expect(
        await guard.canActivate('/', _anyRoute),
        isFalse,
        reason: 'the shell must stay closed for an unidentified session',
      );

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      // If the page navigated here, the shell guard would redirect straight
      // back and the user would never reach a rendered frame.
      expect(
        router.navigationHistory.map((c) => c.route),
        isNot(contains(shellRoute)),
      );
    });

    testWidgets('the gate renders the retry screen, not an accept prompt', (
      tester,
    ) async {
      // There is no identified user to record an acceptance against, so the
      // dead end mirrors the guard rather than asking for consent that could
      // not be attributed. Retry re-reads the status, so a JWT that later
      // carries the claim still resolves.
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('consentUnavailableTitle')), findsOneWidget);
      expect(
        find.byKey(const Key('consentUnavailableRetryButton')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('consentGateAcceptButton')), findsNothing);
    });

    testWidgets('retrying leaves for the shell once the claim arrives', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      repository.resolveTo(const ConsentSatisfied(2));
      await tester.tap(find.byKey(const Key('consentUnavailableRetryButton')));
      await tester.pumpAndSettle();

      expect(await guard.canActivate('/', _anyRoute), isTrue);
      expect(router.navigationHistory.map((c) => c.route), contains(shellRoute));
    });
  });
}

// ignore: no_direct_instantiation
final _anyRoute = ChildRoute('/', child: (_) => const SizedBox());

import 'package:construculator/features/consent/presentation/bloc/consent_gate_bloc/consent_gate_bloc.dart';
import 'package:construculator/features/consent/presentation/pages/consent_gate_page.dart';
import 'package:construculator/features/consent/testing/consent_test_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

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

  Widget buildPage(ThemeData theme) => MaterialApp(
    theme: theme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<ConsentGateBloc>(
      create: (_) =>
          Modular.get<ConsentGateBloc>()..add(const ConsentGateStarted()),
      child: ConsentGatePage(
        router: Modular.get<AppRouter>(),
        onOpenDocument: (_) {},
      ),
    ),
  );

  group('ConsentGatePage accessibility', () {
    testWidgets('accept button meets tap target and label guidelines', (
      tester,
    ) async {
      await setupA11yTest(tester);
      repository.resolveTo(ConsentNeverGiven(requiredVersion));

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildPage,
        find.byKey(const Key('consentGateAcceptButton')),
      );
    });

    testWidgets('terms link meets tap target and label guidelines', (
      tester,
    ) async {
      // Underlined body text is well under 48dp on its own, so the link is
      // wrapped to reach the guideline rather than relying on text bounds.
      await setupA11yTest(tester);
      repository.resolveTo(ConsentNeverGiven(requiredVersion));

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildPage,
        find.byKey(const Key('consentGateTermsLink')),
      );
    });

    testWidgets('privacy link meets tap target and label guidelines', (
      tester,
    ) async {
      await setupA11yTest(tester);
      repository.resolveTo(ConsentNeverGiven(requiredVersion));

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildPage,
        find.byKey(const Key('consentGatePrivacyLink')),
      );
    });

    testWidgets('retry button meets tap target and label guidelines', (
      tester,
    ) async {
      await setupA11yTest(tester);
      repository.resolveTo(
        const ConsentIndeterminate(ConsentType.termsAndPrivacy),
      );

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildPage,
        find.byKey(const Key('consentUnavailableRetryButton')),
      );
    });
  });

  // Neither screen has a back affordance or app bar, so these buttons are
  // the only way off an unescapable page. Every check above runs at the
  // default text scale; this is the first test in the repo (per
  // `gh search code textScaler`, zero hits) asserting the primary action
  // survives the large end of the OS text-scale range instead.
  //
  // scrollUntilVisible, not a plain hitTestable() check: the scroll wrapper's
  // whole promise is that the button is *reachable*, not that it never needs
  // scrolling -- content genuinely may not fit above the fold at 2x scale,
  // and that is fine. What the old centred-Column-with-no-scroll layout
  // could not do at all is let the user scroll to it; that is the regression
  // this guards.
  group('ConsentGatePage at large text scale', () {
    testWidgets('accept button remains reachable at 2x text scale', (
      tester,
    ) async {
      await setupA11yTest(tester);
      repository.resolveTo(ConsentNeverGiven(requiredVersion));
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(buildPage(createTestTheme()));
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('consentGateAcceptButton'));
      await tester.scrollUntilVisible(
        button,
        100,
        scrollable: find.byType(Scrollable),
      );
      expect(button.hitTestable(), findsOneWidget);
    });

    testWidgets('retry button remains reachable at 2x text scale', (
      tester,
    ) async {
      await setupA11yTest(tester);
      repository.resolveTo(
        const ConsentIndeterminate(ConsentType.termsAndPrivacy),
      );
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(buildPage(createTestTheme()));
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('consentUnavailableRetryButton'));
      await tester.scrollUntilVisible(
        button,
        100,
        scrollable: find.byType(Scrollable),
      );
      expect(button.hitTestable(), findsOneWidget);
    });
  });
}

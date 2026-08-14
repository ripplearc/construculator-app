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

  /// Drives the local read and the verification to the same answer.
  ///
  /// The gate's third phase re-emits after confirming against the server, so a
  /// fixture that sets only the cached status would be superseded before the
  /// page finished rendering it.
  void resolveTo(ConsentStatus status) => repository
    ..cachedStatusToReturn = status
    ..verifiedStatusToReturn = status;


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
      resolveTo(ConsentNeverGiven(requiredVersion));

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
      resolveTo(ConsentNeverGiven(requiredVersion));

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
      resolveTo(ConsentNeverGiven(requiredVersion));

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
      resolveTo(const ConsentIndeterminate());

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        buildPage,
        find.byKey(const Key('consentUnavailableRetryButton')),
      );
    });
  });
}

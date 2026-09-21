import 'package:construculator/app/app_module.dart';
import 'package:construculator/app/shell/feature_unavailable_page.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/config/feature_availability.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/testing/fake_current_project_notifier.dart';
import 'package:construculator/libraries/project/testing/fake_project_ui_provider.dart';
import 'package:construculator/libraries/router/routes/calculator_routes.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';
import '../../../utils/feature_availability_scope.dart';

/// Exclusion tests for the calculator route (CA-930).
///
/// The team rule: every optional feature is forced on in [setUp] through
/// [enableAllFeaturesPerTest], and a single test flips one feature off with
/// [FeatureAvailability.overrideWith]. `ShellModule.routes` reads the override
/// while composing routes, so the flip must happen before [Modular.init].
void main() {
  enableAllFeaturesPerTest();

  final fakeClock = FakeClockImpl();
  final fakeSupabaseWrapper = FakeSupabaseWrapper(clock: fakeClock);
  final appBootstrap = FakeAppBootstrapFactory.create(
    supabaseWrapper: fakeSupabaseWrapper,
  );

  setUp(() {
    fakeSupabaseWrapper.reset();
    fakeSupabaseWrapper.setCurrentUser(
      FakeUser(id: 'fake-id', createdAt: fakeClock.now().toIso8601String()),
    );
    final fakeUser = User(
      id: '1',
      credentialId: 'fake-id',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      professionalRole: 'Engineer',
      createdAt: fakeClock.now(),
      updatedAt: fakeClock.now(),
      userStatus: UserProfileStatus.active,
      userPreferences: {},
    );
    fakeSupabaseWrapper.addTableData('users', [fakeUser.toJson()]);
  });

  tearDown(() {
    (Modular.routerConfig.routerDelegate as dynamic).currentConfiguration =
        null;
    Modular.destroy();
  });

  void initShell() {
    Modular.init(AppModule(appBootstrap));
    Modular.replaceInstance<CurrentProjectNotifier>(
      FakeCurrentProjectNotifier(),
    );
    Modular.replaceInstance<ProjectUIProvider>(FakeProjectUIProvider());
  }

  Widget makeApp() {
    return MaterialApp.router(
      routerConfig: Modular.routerConfig,
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  Future<void> pumpShellAndPush(WidgetTester tester, String route) async {
    await tester.pumpWidget(makeApp());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    Modular.to.pushNamed(route);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets(
    'deep link to /calculator renders CalculatorPage when the calculator '
    'feature is present',
    (tester) async {
      initShell();

      await pumpShellAndPush(tester, calculatorBaseRoute);

      expect(find.byType(CalculatorPage), findsOneWidget);
      expect(find.byType(FeatureUnavailablePage), findsNothing);
    },
  );

  testWidgets(
    'deep link to /calculator resolves to FeatureUnavailablePage when the '
    'calculator feature is excluded',
    (tester) async {
      FeatureAvailability.overrideWith((feature) => feature != Feature.calculator);
      initShell();

      await pumpShellAndPush(tester, calculatorBaseRoute);

      expect(find.byType(FeatureUnavailablePage), findsOneWidget);
      expect(find.byType(CalculatorPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

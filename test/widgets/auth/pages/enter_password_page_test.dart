import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/auth/presentation/bloc/enter_password_bloc/enter_password_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/enter_password_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class _EnterPasswordPageTestModule extends Module {
  final AppBootstrap appBootstrap;
  _EnterPasswordPageTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    ClockTestModule(),
    AuthModule(appBootstrap),
  ];
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  BuildContext? buildContext;
  const testEmail = 'test@example.com';

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    CoreToast.disableTimers();

    final appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: fakeSupabase,
    );

    Modular.init(_EnterPasswordPageTestModule(appBootstrap));
    Modular.replaceInstance<SupabaseWrapper>(fakeSupabase);
    router = Modular.get<AppRouter>() as FakeAppRouter;
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeSupabase.reset();
  });

  Widget makeTestableWidget({required Widget child}) {
    return BlocProvider<EnterPasswordBloc>(
      create: (context) => Modular.get<EnterPasswordBloc>(),
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            buildContext = context;
            return child;
          },
        ),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> renderPage(
    WidgetTester tester, {
    String email = testEmail,
  }) async {
    await tester.pumpWidget(
      makeTestableWidget(child: EnterPasswordPage(email: email)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterPassword(WidgetTester tester, String password) async {
    await tester.enterText(
      find.ancestor(
        of: find.text(l10n().passwordLabel),
        matching: find.byType(TextField),
      ),
      password,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapContinueButton(WidgetTester tester) async {
    await tester.tap(find.text(l10n().continueButton));
    await tester.pumpAndSettle();
  }

  bool isContinueButtonEnabled(WidgetTester tester) {
    final buttonFinder = find.ancestor(
      of: find.text(l10n().continueButton),
      matching: find.byType(CoreButton),
    );
    if (buttonFinder.evaluate().isEmpty) return false;
    final button = tester.widget<CoreButton>(buttonFinder);
    return !button.isDisabled;
  }

  group('User on EnterPasswordPage', () {
    testWidgets('sees password field, email, and continue button', (
      tester,
    ) async {
      await renderPage(tester);

      expect(find.text(l10n().passwordLabel), findsOneWidget);

      expect(find.textContaining(testEmail), findsOneWidget);

      expect(find.text(l10n().continueButton), findsOneWidget);
      expect(isContinueButtonEnabled(tester), isFalse);
    });

    testWidgets('can toggle password visibility', (tester) async {
      await renderPage(tester);

      await enterPassword(tester, 'SecretPass123!');

      final passwordField = find.ancestor(
        of: find.text(l10n().passwordLabel),
        matching: find.byType(TextField),
      );

      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      final toggleButton = find.descendant(
        of: find.ancestor(
          of: find.text(l10n().passwordLabel),
          matching: find.byType(CoreTextField),
        ),
        matching: find.byType(IconButton),
      );
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    });

    testWidgets('cannot submit with empty password', (tester) async {
      await renderPage(tester);

      await enterPassword(tester, '');

      expect(find.text(l10n().passwordRequiredError), findsOneWidget);
      expect(isContinueButtonEnabled(tester), isFalse);
    });

    testWidgets('sees success message after entering correct password', (
      tester,
    ) async {
      await renderPage(tester);

      await enterPassword(tester, '5i2Un@D8Y9!');
      expect(isContinueButtonEnabled(tester), isTrue);
      await tapContinueButton(tester);

      expect(find.textContaining(l10n().loginSuccessMessage), findsOneWidget);
    });

    testWidgets('sees error message with incorrect password', (tester) async {
      fakeSupabase.shouldThrowOnSignIn = true;
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.invalidCredentials;

      await renderPage(tester);

      await enterPassword(tester, 'WrongPassword123!');
      expect(isContinueButtonEnabled(tester), isTrue);
      await tapContinueButton(tester);

      expect(find.text(l10n().invalidCredentialsError), findsOneWidget);

      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
    });

    testWidgets('can navigate to forgot password page', (tester) async {
      await renderPage(tester, email: '');

      await tester.tap(find.text(l10n().forgotPasswordTitle));
      await tester.pumpAndSettle();

      expect(router.navigationHistory.first.route, fullForgotPasswordRoute);
    });

    testWidgets('can go back to edit email', (tester) async {
      await renderPage(tester);

      expect(find.textContaining(testEmail), findsOneWidget);

      final editLink = find.byKey(const Key('edit_link'));
      await tester.tap(editLink);
      await tester.pumpAndSettle();

      expect(router.popCalls, 1);
    });
  });
}

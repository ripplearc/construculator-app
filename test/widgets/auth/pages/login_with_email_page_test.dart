import 'dart:async';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/login_with_email_page.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/features/auth/presentation/bloc/login_with_email_bloc/login_with_email_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import '../../../screenshots/font_loader.dart';

class _LoginWithEmailPageTestModule extends Module {
  final AppBootstrap appBootstrap;
  _LoginWithEmailPageTestModule(this.appBootstrap);

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
  late Clock clock;
  BuildContext? buildContext;

  Widget makeTestableWidget({required Widget child}) {
    return BlocProvider<LoginWithEmailBloc>(
      create: (context) => Modular.get<LoginWithEmailBloc>(),
      child: MaterialApp(
        theme: createTestTheme(),
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

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    CoreToast.disableTimers();

    final appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: fakeSupabase,
    );

    Modular.init(_LoginWithEmailPageTestModule(appBootstrap));
    Modular.replaceInstance<SupabaseWrapper>(fakeSupabase);
    router = Modular.get<AppRouter>() as FakeAppRouter;
    clock = Modular.get<Clock>();
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeSupabase.reset();
  });

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> renderPage(WidgetTester tester, {String email = ''}) async {
    await tester.pumpWidget(
      makeTestableWidget(child: LoginWithEmailPage(email: email)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterEmail(WidgetTester tester, String email) async {
    await tester.enterText(
      find.ancestor(
        of: find.text(l10n().emailLabel),
        matching: find.byType(TextField),
      ),
      email,
    );
    await tester.pump();
  }

  Future<void> tapContinueButton(WidgetTester tester) async {
    await tester.tap(find.text(l10n().continueButton));
    await tester.pumpAndSettle();
  }

  group('User on LoginWithEmailPage', () {
    testWidgets('sees email input, continue button, and register link', (
      tester,
    ) async {
      await renderPage(tester);

      expect(find.text(l10n().emailLabel), findsOneWidget);

      expect(find.text(l10n().continueButton), findsOneWidget);

      expect(find.textContaining(l10n().register), findsOneWidget);
    });

    testWidgets('sees error when email is empty', (tester) async {
      await renderPage(tester);

      await enterEmail(tester, '');

      expect(find.text(l10n().emailRequiredError), findsOneWidget);
    });

    testWidgets('sees error when email format is invalid', (tester) async {
      await renderPage(tester);

      await enterEmail(tester, 'invalid-email');

      expect(find.text(l10n().invalidEmailError), findsOneWidget);
    });

    testWidgets('sees immediate error for pre-filled invalid email', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          child: const LoginWithEmailPage(email: 'invalid-email'),
        ),
      );
      await tester.pump();

      expect(find.text(l10n().invalidEmailError), findsOneWidget);
    });

    testWidgets(
      'can login with registered email and navigate to password page',
      (tester) async {
        const registeredEmail = 'registered@example.com';

        fakeSupabase.addTableData('users', [
          {
            'id': '1',
            'email': registeredEmail,
            'created_at': clock.now().toIso8601String(),
          },
        ]);

        await renderPage(tester);

        await enterEmail(tester, registeredEmail);
        await tapContinueButton(tester);

        expect(router.navigationHistory.first.route, fullEnterPasswordRoute);
        expect(router.navigationHistory.first.arguments, registeredEmail);
      },
    );

    testWidgets('cannot continue with invalid email format', (tester) async {
      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = Completer<void>();
      fakeSupabase.clearTableData('users');

      await renderPage(tester);

      await enterEmail(tester, 'newuserexample');

      expect(find.text(l10n().invalidEmailError), findsOneWidget);

      fakeSupabase.completer!.complete();
    });

    testWidgets('sees error and register option when email not registered', (
      tester,
    ) async {
      fakeSupabase.setRpcResponse('check_email_exists', false);
      await renderPage(tester);

      await enterEmail(tester, 'notregistered@example.com');

      expect(find.text(l10n().emailNotRegistered), findsOneWidget);

      expect(find.text(l10n().register), findsAtLeastNWidgets(1));
    });

    testWidgets('can navigate to register page from email not found message', (
      tester,
    ) async {
      fakeSupabase.setRpcResponse('check_email_exists', false);
      await renderPage(tester);

      const unregisteredEmail = 'notregistered@example.com';
      await enterEmail(tester, unregisteredEmail);

      final registerLink = find.byKey(Key(l10n().register));
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      expect(router.navigationHistory.first.route, fullRegisterRoute);
      expect(router.navigationHistory.first.arguments, unregisteredEmail);
    });

    testWidgets('sees server error message when backend fails', (tester) async {
      fakeSupabase.shouldThrowOnSelect = true;
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.invalidCredentials;

      await renderPage(tester);

      await enterEmail(tester, 'error@example.com');

      expect(find.textContaining(l10n().serverError), findsWidgets);
    });

    testWidgets('can navigate to register page from footer link', (
      tester,
    ) async {
      await renderPage(tester);

      final registerLink = find.byKey(const Key('auth_footer_link'));
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      expect(router.navigationHistory.first.route, fullRegisterRoute);
    });
  });
}

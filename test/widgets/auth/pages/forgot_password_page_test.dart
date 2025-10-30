import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/forgot_password_page.dart';
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
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _ForgotPasswordPageTestModule extends Module {
  final AppBootstrap appBootstrap;
  _ForgotPasswordPageTestModule(this.appBootstrap);

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

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    CoreToast.disableTimers();

    final appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: fakeSupabase,
    );

    Modular.init(_ForgotPasswordPageTestModule(appBootstrap));
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<ForgotPasswordBloc>(
          create: (context) => Modular.get<ForgotPasswordBloc>(),
        ),
        BlocProvider<OtpVerificationBloc>(
          create: (context) => Modular.get<OtpVerificationBloc>(),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            buildContext = context;
            return child;
          },
        ),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
      ),
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> renderPage(WidgetTester tester) async {
    await tester.pumpWidget(
      makeTestableWidget(child: const ForgotPasswordPage()),
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
    await tester.pumpAndSettle();
  }

  Future<void> tapContinueButton(WidgetTester tester) async {
    await tester.tap(find.text(l10n().continueButton));
    await tester.pumpAndSettle();
  }

  Future<void> enterOtp(WidgetTester tester, String otp) async {
    final pinInput = find.descendant(
      of: find.byKey(const Key('pin_input')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(pinInput, otp);
    await tester.pumpAndSettle();
  }

  Future<void> tapVerifyButton(WidgetTester tester) async {
    await tester.tap(find.text(l10n().verifyOtpButton));
    await tester.pumpAndSettle();
  }

  group('User on ForgotPasswordPage', () {
    testWidgets('sees email input and continue button', (tester) async {
      await renderPage(tester);

      expect(find.textContaining(l10n().forgotPasswordTitle), findsOneWidget);

      expect(find.text(l10n().emailLabel), findsOneWidget);

      expect(find.text(l10n().continueButton), findsOneWidget);
    });

    testWidgets('sees error when email is empty', (tester) async {
      await renderPage(tester);

      await enterEmail(tester, '');

      expect(find.textContaining(l10n().emailRequiredError), findsWidgets);
    });

    testWidgets('sees error when email format is invalid', (tester) async {
      await renderPage(tester);

      await enterEmail(tester, 'invalid-email');

      expect(find.textContaining(l10n().invalidEmailError), findsWidgets);
    });

    testWidgets('sees OTP verification modal after submitting valid email', (
      tester,
    ) async {
      await renderPage(tester);

      await enterEmail(tester, 'reset@example.com');
      await tapContinueButton(tester);

      expect(
        find.textContaining(l10n().authenticationCodeTitle),
        findsOneWidget,
      );
    });

    testWidgets('can complete OTP verification and navigate to set password', (
      tester,
    ) async {
      await renderPage(tester);

      await enterEmail(tester, 'reset@example.com');
      await tapContinueButton(tester);

      expect(
        find.textContaining(l10n().authenticationCodeTitle),
        findsOneWidget,
      );

      await enterOtp(tester, '123456');

      await tapVerifyButton(tester);

      expect(router.navigationHistory.first.route, fullSetNewPasswordRoute);
    });

    testWidgets('sees error message when OTP is incorrect', (tester) async {
      fakeSupabase.shouldThrowOnVerifyOtp = true;
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.invalidCredentials;

      await renderPage(tester);

      await enterEmail(tester, 'reset@example.com');
      await tapContinueButton(tester);

      await enterOtp(tester, '123456');
      await tapVerifyButton(tester);

      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
      expect(find.textContaining(l10n().invalidCredentialsError), findsWidgets);
    });

    testWidgets('sees error when backend request fails', (tester) async {
      fakeSupabase.shouldThrowOnResetPassword = true;
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.rateLimited;

      await renderPage(tester);

      await enterEmail(tester, 'error@example.com');
      await tapContinueButton(tester);

      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
      expect(find.textContaining(l10n().tooManyAttempts), findsWidgets);
    });

    testWidgets('can resend OTP code', (tester) async {
      await renderPage(tester);

      await enterEmail(tester, 'reset@example.com');
      await tapContinueButton(tester);

      final resendButton = find.text(l10n().resendButton);
      expect(resendButton, findsOneWidget);

      await tester.tap(resendButton);
      await tester.pumpAndSettle();

      expect(find.textContaining(l10n().otpResendSuccess), findsWidgets);
    });

    testWidgets('sees error when OTP resend fails', (tester) async {
      await renderPage(tester);

      await enterEmail(tester, 'reset@example.com');
      await tapContinueButton(tester);

      fakeSupabase.shouldThrowOnOtp = true;
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.rateLimited;

      final resendButton = find.text(l10n().resendButton);
      await tester.tap(resendButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
      expect(find.textContaining(l10n().tooManyAttempts), findsWidgets);
    });

    testWidgets('can edit email from OTP verification screen', (tester) async {
      await renderPage(tester);

      await enterEmail(tester, 'reset@example.com');
      await tapContinueButton(tester);

      expect(
        find.textContaining(l10n().authenticationCodeTitle),
        findsOneWidget,
      );

      final editButton = find.byKey(const Key('edit_contact_button'));
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.textContaining(l10n().authenticationCodeTitle), findsNothing);

      expect(find.text(l10n().emailLabel), findsOneWidget);
    });
  });
}

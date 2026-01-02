import 'dart:async';

import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/register_with_email_bloc/register_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/register_with_email_page.dart';
import 'package:construculator/features/auth/presentation/widgets/otp_quick_sheet/otp_verification_sheet.dart';
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
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class _RegisterWithEmailPageTestModule extends Module {
  final AppBootstrap appBootstrap;
  _RegisterWithEmailPageTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    ClockTestModule(),
    AuthModule(appBootstrap),
  ];
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late Clock clock;
  late FakeAppRouter router;
  BuildContext? buildContext;

  Widget makeTestableWidget({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegisterWithEmailBloc>(
          create: (context) => Modular.get<RegisterWithEmailBloc>(),
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

    Modular.init(_RegisterWithEmailPageTestModule(appBootstrap));
    Modular.replaceInstance<SupabaseWrapper>(fakeSupabase);
    router = Modular.get<AppRouter>() as FakeAppRouter;
    clock = Modular.get<Clock>();
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    router.reset();
    fakeSupabase.reset();
  });

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  Future<void> renderPage(WidgetTester tester, {String email = ''}) async {
    await tester.pumpWidget(
      makeTestableWidget(child: RegisterWithEmailPage(email: email)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterEmail(WidgetTester tester, String email) async {
    final emailField = find.ancestor(
      of: find.text(l10n().emailLabel),
      matching: find.byType(TextField),
    );
    await tester.enterText(emailField, email);
    await tester.pumpAndSettle();
  }

  Future<void> tapContinueButton(WidgetTester tester) async {
    await tester.tap(find.text(l10n().continueButton));
    await tester.pumpAndSettle();
  }

  Future<void> enterOtp(WidgetTester tester, String otp) async {
    final pinInput = find.byKey(const Key('pin_input'));
    await tester.enterText(pinInput, otp);
    await tester.pumpAndSettle();
  }

  Future<void> tapVerifyButton(WidgetTester tester) async {
    await tester.tap(find.text(l10n().verifyOtpButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapResendButton(WidgetTester tester) async {
    await tester.tap(find.textContaining('Resend'));
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

  group('User on RegisterWithEmailPage', () {
    testWidgets('sees email input, continue button, and welcome message', (
      tester,
    ) async {
      await renderPage(tester);

      expect(find.text(l10n().emailLabel), findsOneWidget);

      expect(find.text(l10n().continueButton), findsOneWidget);
      expect(isContinueButtonEnabled(tester), isFalse);

      expect(
        find.textContaining(l10n().heyEnterYourDetailsToRegisterWithUs),
        findsOneWidget,
      );
    });

    testWidgets('sees invalid email error message', (tester) async {
      await renderPage(tester);

      await enterEmail(tester, 'invalid-email');

      expect(find.textContaining(l10n().invalidEmailError), findsOneWidget);
      expect(isContinueButtonEnabled(tester), isFalse);
    });

    testWidgets('sees already registered error with login link', (
      tester,
    ) async {
      fakeSupabase.addTableData('users', [
        {
          'id': '1',
          'email': 'registered@example.com',
          'created_at': clock.now().toIso8601String(),
        },
      ]);

      await renderPage(tester);
      await enterEmail(tester, 'registered@example.com');

      expect(
        find.textContaining(l10n().emailAlreadyRegistered),
        findsOneWidget,
      );

      expect(isContinueButtonEnabled(tester), isFalse);

      final methodCalls = fakeSupabase.getMethodCallsFor('selectSingle');
      expect(methodCalls.length, 1);
    });

    testWidgets('can navigate to login from already registered link', (
      tester,
    ) async {
      fakeSupabase.addTableData('users', [
        {
          'id': '1',
          'email': 'registered@example.com',
          'created_at': clock.now().toIso8601String(),
        },
      ]);

      await renderPage(tester);
      const enteredEmail = 'registered@example.com';
      await enterEmail(tester, enteredEmail);

      final loginLink = find.byKey(Key(l10n().logginLink));
      expect(isContinueButtonEnabled(tester), isFalse);
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      expect(router.navigationHistory.first.route, fullLoginRoute);
      expect(router.navigationHistory.first.arguments, enteredEmail);
    });

    testWidgets('sees error toast when backend fails', (tester) async {
      fakeSupabase.shouldThrowOnSelect = true;

      await renderPage(tester);
      await enterEmail(tester, 'error@example.com');

      expect(find.text(l10n().serverError), findsOneWidget);
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
    });

    testWidgets('can proceed with valid unregistered email', (tester) async {
      fakeSupabase.clearTableData('users');

      await renderPage(tester);
      await enterEmail(tester, 'newuser@example.com');

      expect(isContinueButtonEnabled(tester), isTrue);
      expect(find.textContaining(l10n().invalidEmailError), findsNothing);
      expect(find.textContaining(l10n().emailAlreadyRegistered), findsNothing);
    });

    testWidgets('can use pre-filled valid email', (tester) async {
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(
          child: const RegisterWithEmailPage(email: 'newuser@example.com'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('newuser@example.com'), findsOneWidget);
      expect(isContinueButtonEnabled(tester), isTrue);
    });

    testWidgets('sees button text change when submitting email', (
      tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await renderPage(tester);
      await enterEmail(tester, 'newuser@example.com');

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(isContinueButtonEnabled(tester), isTrue);
      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = Completer<void>();

      await tester.tap(find.text(l10n().continueButton));
      await tester.pump();

      expect(find.text(l10n().sendingOtpButton), findsOneWidget);

      fakeSupabase.completer!.complete();
    });

    testWidgets('sees checking availability message during validation', (
      tester,
    ) async {
      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = Completer<void>();
      fakeSupabase.clearTableData('users');

      await renderPage(tester);

      await tester.enterText(
        find.ancestor(
          of: find.text(l10n().emailLabel),
          matching: find.byType(TextField),
        ),
        'newuser@example.com',
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n().checkingAvailabilityButton), findsOneWidget);

      fakeSupabase.completer!.complete();
    });

    testWidgets('cannot submit invalid email format', (tester) async {
      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = Completer<void>();
      fakeSupabase.clearTableData('users');

      await renderPage(tester);
      await enterEmail(tester, 'newuserexample');

      expect(find.textContaining(l10n().invalidEmailError), findsOneWidget);
      expect(isContinueButtonEnabled(tester), isFalse);

      fakeSupabase.completer!.complete();
    });

    testWidgets('sees OTP verification screen after submitting email', (
      tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await renderPage(tester);
      await enterEmail(tester, 'newuser@example.com');
      expect(isContinueButtonEnabled(tester), isTrue);
      await tapContinueButton(tester);

      expect(
        find.textContaining(l10n().authenticationCodeTitle),
        findsOneWidget,
      );

      expect(find.text(l10n().verifyOtpButton), findsOneWidget);
    });

    testWidgets('can enter OTP code in verification screen', (tester) async {
      fakeSupabase.clearTableData('users');

      await renderPage(tester);
      await enterEmail(tester, 'newuser@example.com');
      expect(isContinueButtonEnabled(tester), isTrue);
      await tapContinueButton(tester);

      await enterOtp(tester, '123456');

      expect(find.text(l10n().verifyOtpButton), findsOneWidget);
    });

    testWidgets('sees button text change when verifying OTP', (tester) async {
      fakeSupabase.clearTableData('users');

      await renderPage(tester);
      await enterEmail(tester, 'newuser@example.com');
      expect(isContinueButtonEnabled(tester), isTrue);
      await tapContinueButton(tester);

      await enterOtp(tester, '123456');

      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = Completer<void>();

      await tester.tap(find.text(l10n().verifyOtpButton));
      await tester.pump();

      expect(find.text(l10n().verifyingButtonLabel), findsOneWidget);

      fakeSupabase.completer!.complete();
    });

    testWidgets('can navigate to login from footer link', (tester) async {
      await renderPage(tester);

      final loginLink = find.byKey(const Key('auth_footer_link'));
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      expect(router.navigationHistory.first.route, fullLoginRoute);
    });

    testWidgets('handles rate limit error gracefully', (tester) async {
      fakeSupabase.shouldThrowOnOtp = true;
      fakeSupabase.otpErrorMessage = 'Rate limited';
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.rateLimited;

      await renderPage(tester);
      await enterEmail(tester, 'error@example.com');
      expect(isContinueButtonEnabled(tester), isTrue);
      await tapContinueButton(tester);

      expect(find.text(l10n().tooManyAttempts), findsOneWidget);
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
    });

    testWidgets('sees error when OTP verification fails', (tester) async {
      fakeSupabase.clearTableData('users');
      fakeSupabase.shouldThrowOnVerifyOtp = true;
      fakeSupabase.verifyOtpErrorMessage = 'Invalid OTP';
      fakeSupabase.authErrorCode = null;

      await renderPage(tester);
      await enterEmail(tester, 'newuser@example.com');
      expect(isContinueButtonEnabled(tester), isTrue);
      await tapContinueButton(tester);

      await enterOtp(tester, '123456');
      await tapVerifyButton(tester);

      expect(find.text(l10n().unknownError), findsOneWidget);
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
      expect(find.byType(OtpVerificationQuickSheet), findsOneWidget);
    });

    testWidgets('can resend OTP code and sees success toast', (tester) async {
      fakeSupabase.clearTableData('users');

      await renderPage(tester);
      await enterEmail(tester, 'newuser@example.com');
      expect(isContinueButtonEnabled(tester), isTrue);
      await tapContinueButton(tester);

      final resendButton = find.textContaining('Resend');
      expect(resendButton, findsOneWidget);

      await tapResendButton(tester);

      expect(find.text(l10n().otpResendSuccess), findsOneWidget);
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
      expect(find.byType(OtpVerificationQuickSheet), findsOneWidget);
    });

    testWidgets('sees error when OTP resend fails', (tester) async {
      fakeSupabase.clearTableData('users');

      await renderPage(tester);
      await enterEmail(tester, 'newuser@example.com');
      expect(isContinueButtonEnabled(tester), isTrue);
      await tapContinueButton(tester);

      fakeSupabase.shouldThrowOnOtp = true;
      fakeSupabase.otpErrorMessage = 'Network error';
      fakeSupabase.authErrorCode = null;

      await tapResendButton(tester);

      expect(find.text(l10n().unknownError), findsOneWidget);
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
      expect(find.byType(OtpVerificationQuickSheet), findsOneWidget);
    });

    testWidgets('can edit email from OTP verification screen', (tester) async {
      fakeSupabase.clearTableData('users');

      await renderPage(tester);
      await enterEmail(tester, 'newuser@example.com');
      expect(isContinueButtonEnabled(tester), isTrue);
      await tapContinueButton(tester);

      final editButton = find.byKey(const Key('edit_contact_button'));

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.byType(OtpVerificationQuickSheet), findsNothing);
    });

    testWidgets('sees error when OTP sending fails', (tester) async {
      fakeSupabase.shouldThrowOnOtp = true;
      fakeSupabase.otpErrorMessage = 'Network error';

      await renderPage(tester);
      await enterEmail(tester, 'error@example.com');
      expect(isContinueButtonEnabled(tester), isTrue);
      await tapContinueButton(tester);

      expect(find.text(l10n().unknownError), findsOneWidget);
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
      expect(
        find.widgetWithText(CoreTextField, l10n().emailLabel),
        findsOneWidget,
      );
    });
  });
}

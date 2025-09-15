import 'dart:async';

import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/features/auth/presentation/pages/register_with_email_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/features/auth/presentation/bloc/register_with_email_bloc/register_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/widgets/otp_quick_sheet/otp_verification_sheet.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:core_ui/core_ui.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late Clock clock;
  late FakeAppRouter router;
  BuildContext? buildContext;

  Widget makeTestableWidget({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegisterWithEmailBloc>.value(
          value: Modular.get<RegisterWithEmailBloc>(),
        ),
        BlocProvider<OtpVerificationBloc>.value(
          value: Modular.get<OtpVerificationBloc>(),
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

  setUp(() {
    CoreToast.disableTimers();
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
    clock = Modular.get<Clock>();
  });

  tearDown(() {
    router.reset();
    fakeSupabase.reset();
    Modular.destroy();
    CoreToast.enableTimers();
  });
  group('RegisterWithEmailPage', () {
    testWidgets('renders all page elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CoreTextField), findsOneWidget);

      expect(
        find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        ),
        findsOneWidget,
      );

      expect(
        find.textContaining(
          AppLocalizations.of(
            buildContext!,
          )!.heyEnterYourDetailsToRegisterWithUs,
        ),
        findsOneWidget,
      );
    });

    testWidgets('continue button is disabled on page load', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
    });

    testWidgets('shows error message when invalid email is entered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'invalid-email');
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.invalidEmailError,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows error with login link when entered email is already registered.',
      (WidgetTester tester) async {
        fakeSupabase.addTableData('users', [
          {
            'id': '1',
            'email': 'registered@example.com',
            'created_at': clock.now().toIso8601String(),
          },
        ]);

        await tester.pumpWidget(
          makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
        );

        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(CoreTextField),
          'registered@example.com',
        );
        await tester.pumpAndSettle();

        final methodCalls = fakeSupabase.getMethodCallsFor('selectSingle');

        expect(methodCalls.length, 1);
        expect(
          find.textContaining(
            AppLocalizations.of(buildContext!)!.emailAlreadyRegistered,
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(
            CoreButton,
            AppLocalizations.of(buildContext!)!.continueButton,
          ),
          findsOneWidget,
        );
      },
    );
    testWidgets(
      'already registered login link navigates to login page with registered email',
      (WidgetTester tester) async {
        fakeSupabase.addTableData('users', [
          {
            'id': '1',
            'email': 'registered@example.com',
            'created_at': clock.now().toIso8601String(),
          },
        ]);

        await tester.pumpWidget(
          makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
        );

        await tester.pumpAndSettle();
        final enteredEmail = 'registered@example.com';
        await tester.enterText(find.byType(CoreTextField), enteredEmail);
        await tester.pumpAndSettle();

        final loginLink = find.byKey(
          Key(AppLocalizations.of(buildContext!)!.logginLink),
        );
        await tester.tap(loginLink);
        await tester.pumpAndSettle();

        expect(router.navigationHistory.first.route, fullLoginRoute);
        expect(router.navigationHistory.first.arguments, enteredEmail);
      },
    );

    testWidgets('shows toast error when backend error occurs', (
      WidgetTester tester,
    ) async {
      fakeSupabase.shouldThrowOnSelect = true;

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'error@example.com');
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizations.of(buildContext!)!.serverError),
        findsOneWidget,
      );
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
    });

    testWidgets(
      'enables continue button when valid unregistered email is entered',
      (WidgetTester tester) async {
        fakeSupabase.clearTableData('users');

        await tester.pumpWidget(
          makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(CoreTextField),
          'newuser@example.com',
        );
        await tester.pumpAndSettle();

        final continueButton = find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        );
        expect(tester.widget<CoreButton>(continueButton).isDisabled, isFalse);
      },
    );

    testWidgets(
      'enables continue button on page load when valid email is pre-filled',
      (WidgetTester tester) async {
        fakeSupabase.clearTableData('users');

        await tester.pumpWidget(
          makeTestableWidget(
            child: const RegisterWithEmailPage(email: 'newuser@example.com'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        final continueButton = find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        );
        expect(tester.widget<CoreButton>(continueButton).isDisabled, isFalse);
      },
    );

    testWidgets('disables continue button when email is submited', (
      WidgetTester tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuser@example.com');
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );

      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = Completer<void>();

      await tester.tap(continueButton);
      await tester.pump();
      final loadingButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.sendingOtpButton,
      );
      expect(tester.widget<CoreButton>(loadingButton).isDisabled, isTrue);
      fakeSupabase.completer!.complete();
    });

    testWidgets('disables continue button when an invalid email is entered', (
      WidgetTester tester,
    ) async {
      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = Completer<void>();
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuserexample');
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
      fakeSupabase.completer!.complete();
    });

    testWidgets('displays OTP bottom sheet when continue button is pressed', (
      WidgetTester tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuser@example.com');
      await tester.pumpAndSettle();
      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.authenticationCodeTitle,
        ),
        findsOneWidget,
      );
      final verifyButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.verifyOtpButton,
      );
      expect(tester.widget<CoreButton>(verifyButton).isDisabled, isTrue);
    });

    testWidgets('enables verify button when OTP is entered', (
      WidgetTester tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuser@example.com');
      await tester.pumpAndSettle();
      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key('pin_input')), '123456');
      await tester.pumpAndSettle();
      final verifyButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.verifyOtpButton,
      );
      expect(tester.widget<CoreButton>(verifyButton).isDisabled, isFalse);
    });

    testWidgets('disables verify button when OTP is submitted', (
      WidgetTester tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuser@example.com');
      await tester.pumpAndSettle();
      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );

      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key('pin_input')), '123456');
      await tester.pumpAndSettle();

      final verifyButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.verifyOtpButton,
      );

      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = Completer<void>();

      await tester.tap(verifyButton);
      await tester.pump();
      final loadingButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.verifyingButtonLabel,
      );

      expect(tester.widget<CoreButton>(loadingButton).isDisabled, isTrue);
      fakeSupabase.completer!.complete();
    });
    testWidgets('footer login link pops page on tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: RegisterWithEmailPage(email: '')),
      );
      final loginLink = find.byKey(Key('auth_footer_link'));
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      expect(router.navigationHistory.first.route, fullLoginRoute);
    });

    testWidgets('handles AuthFailure with rateLimited error type correctly', (
      WidgetTester tester,
    ) async {
      fakeSupabase.shouldThrowOnOtp = true;
      fakeSupabase.otpErrorMessage = 'Rate limited';
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.rateLimited;

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'error@example.com');
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterWithEmailPage), findsOneWidget);
    });

    testWidgets('handles generic failure correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      final bloc = Modular.get<RegisterWithEmailBloc>();
      bloc.emit(
        RegisterWithEmailEmailCheckFailure(failure: UnexpectedFailure()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RegisterWithEmailPage), findsOneWidget);
    });

    testWidgets(
      'shows checking availability button text during email check loading',
      (WidgetTester tester) async {
        fakeSupabase.shouldDelayOperations = true;
        fakeSupabase.completer = Completer<void>();
        fakeSupabase.clearTableData('users');

        await tester.pumpWidget(
          makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(CoreTextField),
          'newuser@example.com',
        );
        await tester.pump(const Duration(milliseconds: 300));

        final buttonFinder = find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.checkingAvailabilityButton,
        );
        expect(buttonFinder, findsOneWidget);

        fakeSupabase.completer!.complete();
      },
    );

    testWidgets('handles OtpVerificationFailure state correctly', (
      WidgetTester tester,
    ) async {
      fakeSupabase.clearTableData('users');

      fakeSupabase.shouldThrowOnVerifyOtp = true;
      fakeSupabase.verifyOtpErrorMessage = 'Invalid OTP';

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuser@example.com');
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      final otpField = find.byKey(Key('pin_input'));
      await tester.enterText(otpField, '123456');
      await tester.pumpAndSettle();

      final verifyButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.verifyOtpButton,
      );
      await tester.tap(verifyButton);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterWithEmailPage), findsOneWidget);
    });

    testWidgets('handles OtpVerificationOtpResendSuccess state correctly', (
      WidgetTester tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuser@example.com');
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      final otpBloc = Modular.get<OtpVerificationBloc>();
      otpBloc.emit(OtpVerificationOtpResendSuccess());
      await tester.pumpAndSettle();

      expect(find.byType(RegisterWithEmailPage), findsOneWidget);
    });

    testWidgets('handles OtpVerificationResendFailure state correctly', (
      WidgetTester tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuser@example.com');
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      fakeSupabase.shouldThrowOnOtp = true;
      fakeSupabase.otpErrorMessage = 'Network error';

      final resendButton = find.textContaining('Resend');
      expect(resendButton, findsOneWidget);
      await tester.tap(resendButton);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterWithEmailPage), findsOneWidget);
    });

    testWidgets('triggers OTP resend when resend button is tapped', (
      WidgetTester tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuser@example.com');
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      final resendButton = find.textContaining('Resend');
      expect(resendButton, findsOneWidget);
      await tester.tap(resendButton);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterWithEmailPage), findsOneWidget);
    });

    testWidgets('triggers email edit when edit button is tapped in OTP sheet', (
      WidgetTester tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuser@example.com');
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      final editButton = find.byKey(Key('edit_contact_button'));
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.byType(OtpVerificationQuickSheet), findsNothing);
    });

    testWidgets('handles RegisterWithEmailOtpSendingFailure state correctly', (
      WidgetTester tester,
    ) async {
      fakeSupabase.shouldThrowOnOtp = true;
      fakeSupabase.otpErrorMessage = 'Network error';

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'error@example.com');
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterWithEmailPage), findsOneWidget);
    });

    testWidgets('handles RegisterWithEmailEditUserEmail state correctly', (
      WidgetTester tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuser@example.com');
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      final registerBloc = Modular.get<RegisterWithEmailBloc>();
      registerBloc.emit(RegisterWithEmailEditUserEmail());
      await tester.pumpAndSettle();

      expect(find.byType(RegisterWithEmailPage), findsOneWidget);
    });
  });
}

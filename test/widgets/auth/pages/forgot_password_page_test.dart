import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_ui/core_ui.dart';
import 'package:construculator/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:construculator/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  BuildContext? buildContext;
  setUp(() {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
  });

  tearDown(() {
    Modular.destroy();
  });

  Widget makeTestableWidget({required Widget child}) {
    final forgotBloc = Modular.get<ForgotPasswordBloc>();
    final otpBloc = Modular.get<OtpVerificationBloc>();
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: forgotBloc),
        BlocProvider.value(value: otpBloc),
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

  group('ForgotPasswordPage', () {
    testWidgets('renders email input and send reset code button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const ForgotPasswordPage()),
      );
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.forgotPasswordTitle,
        ),
        findsOneWidget,
      );
      final sendLinkButtonFinder = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.sendResetLinkButton,
      );
      expect(sendLinkButtonFinder, findsOneWidget);
      final CoreButton sendLinkButton = tester.widget(sendLinkButtonFinder);

      expect(sendLinkButton.isDisabled, isTrue);
    });

    testWidgets('shows validation errors for empty and invalid email', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const ForgotPasswordPage()),
      );
      final sendCodeButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.sendResetLinkButton,
      );
      await tester.enterText(find.byType(CoreTextField), '');
      await tester.pumpAndSettle();
      expect(tester.widget<CoreButton>(sendCodeButton).isDisabled, isTrue);
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.emailRequiredError,
        ),
        findsWidgets,
      );
      await tester.enterText(find.byType(CoreTextField), 'invalid-email');
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.invalidEmailError,
        ),
        findsWidgets,
      );
    });

    testWidgets('submiting a valid email shows otp bottom sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const ForgotPasswordPage()),
      );
      await tester.enterText(find.byType(CoreTextField), 'reset@example.com');
      await tester.pumpAndSettle();
      final sendCodeButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.sendResetLinkButton,
      );
      expect(tester.widget<CoreButton>(sendCodeButton).isDisabled, isFalse);
      await tester.tap(sendCodeButton);
      await tester.pumpAndSettle();
      // OTP bottom sheet should appear
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.authenticationCodeTitle,
        ),
        findsOneWidget,
      );
    });
    testWidgets('submiting a valid otp navigates to set new password page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const ForgotPasswordPage()),
      );
      await tester.enterText(find.byType(CoreTextField), 'reset@example.com');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.sendResetLinkButton,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.authenticationCodeTitle,
        ),
        findsOneWidget,
      );
      final verifyButtonFinder = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.verifyButtonLabel,
      );
      final CoreButton verifyButton = tester.widget(verifyButtonFinder);
      expect(verifyButton.isDisabled, isTrue);

      final editableText = find.descendant(
        of: find.byKey(const Key('pin_input')),
        matching: find.byType(EditableText),
      );
      expect(editableText, findsOneWidget);
      await tester.enterText(editableText, '123456');
      await tester.pumpAndSettle();

      final verifyButtonFinderAfter = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.verifyButtonLabel,
      );
      final CoreButton verifyButtonAfter = tester.widget(
        verifyButtonFinderAfter,
      );
      expect(verifyButtonAfter.isDisabled, isFalse);
      await tester.tap(verifyButtonFinder);
      expect(router.navigationHistory.first.route, fullSetNewPasswordRoute);
    });
    testWidgets('incorrect OTP shows error', (WidgetTester tester) async {
      fakeSupabase.shouldThrowOnVerifyOtp = true;
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.invalidCredentials;
      await tester.pumpWidget(
        makeTestableWidget(child: const ForgotPasswordPage()),
      );
      await tester.enterText(find.byType(CoreTextField), 'reset@example.com');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.sendResetLinkButton,
        ),
      );
      await tester.pumpAndSettle();

      final editableText = find.descendant(
        of: find.byKey(const Key('pin_input')),
        matching: find.byType(EditableText),
      );
      expect(editableText, findsOneWidget);
      await tester.enterText(editableText, '123456');
      await tester.pumpAndSettle();

      final verifyButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.verifyButtonLabel,
      );
      await tester.tap(verifyButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.invalidCredentialsError,
        ),
        findsWidgets,
      );
    });
    testWidgets('backend error shows error message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const ForgotPasswordPage()),
      );
      fakeSupabase.shouldThrowOnResetPassword = true;
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.rateLimited;

      await tester.enterText(find.byType(CoreTextField), 'error@example.com');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.sendResetLinkButton,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.tooManyAttempts,
        ),
        findsWidgets,
      );
    });
  });
}

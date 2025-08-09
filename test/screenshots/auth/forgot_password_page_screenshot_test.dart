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
import '../font_loader.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  BuildContext? buildContext;
  final size = const Size(392, 873);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    CoreToast.disableTimers();
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
    await loadAppFonts();
  });

  tearDown(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  Widget makeTestableWidget({required Widget child}) {
    final forgotBloc = ForgotPasswordBloc(resetPasswordUseCase: Modular.get());
    final otpBloc = OtpVerificationBloc(
      verifyOtpUseCase: Modular.get(),
      sendOtpUseCase: Modular.get(),
    );
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

  group('ForgotPasswordPage Screenshot Tests', () {
    testWidgets('renders email input and send reset code button', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await tester.pumpWidget(
        makeTestableWidget(child: const ForgotPasswordPage()),
      );
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.forgotPasswordTitle,
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

      // Take screenshot of default state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/forgot_password/${size.width}x${size.height}/forgot_password_default_state.png',
        ),
      );
    });

    testWidgets('shows validation errors for empty and invalid email', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await tester.pumpWidget(
        makeTestableWidget(child: const ForgotPasswordPage()),
      );
      await tester.enterText(find.byType(CoreTextField), '');
      await tester.pumpAndSettle();
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

      // Take screenshot of validation error state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/forgot_password/${size.width}x${size.height}/forgot_password_validation_error.png',
        ),
      );
    });

    testWidgets('submiting a valid email shows otp bottom sheet', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await tester.pumpWidget(
        makeTestableWidget(child: const ForgotPasswordPage()),
      );
      await tester.enterText(find.byType(CoreTextField), 'reset@example.com');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        ),
      );
      await tester.pumpAndSettle();
      // OTP bottom sheet should appear
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.authenticationCodeTitle,
        ),
        findsOneWidget,
      );

      // Take screenshot of OTP bottom sheet
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/forgot_password/${size.width}x${size.height}/forgot_password_otp_sheet.png',
        ),
      );
    });

    testWidgets('submiting a valid otp navigates to set new password page', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await tester.pumpWidget(
        makeTestableWidget(child: const ForgotPasswordPage()),
      );
      await tester.enterText(find.byType(CoreTextField), 'reset@example.com');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.authenticationCodeTitle,
        ),
        findsOneWidget,
      );

      final editableText = find.descendant(
        of: find.byKey(const Key('pin_input')),
        matching: find.byType(EditableText),
      );
      expect(editableText, findsOneWidget);
      await tester.enterText(editableText, '123456');
      await tester.pumpAndSettle();

      final verifyButtonFinder = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.verifyOtpButton,
      );
      final CoreButton verifyButton = tester.widget(verifyButtonFinder);
      expect(verifyButton.isDisabled, isFalse);
      await tester.tap(verifyButtonFinder);
      expect(router.navigationHistory.first.route, fullSetNewPasswordRoute);

      // Take screenshot of valid OTP state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/forgot_password/${size.width}x${size.height}/forgot_password_valid_otp.png',
        ),
      );
    });

    testWidgets('incorrect OTP shows error', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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
          AppLocalizations.of(buildContext!)!.continueButton,
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
        AppLocalizations.of(buildContext!)!.verifyOtpButton,
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

      // Take screenshot of incorrect OTP error
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/forgot_password/${size.width}x${size.height}/forgot_password_incorrect_otp.png',
        ),
      );
    });

    testWidgets('backend error shows error message', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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
          AppLocalizations.of(buildContext!)!.continueButton,
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

      // Take screenshot of backend error state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/forgot_password/${size.width}x${size.height}/forgot_password_backend_error.png',
        ),
      );
    });
  });
}

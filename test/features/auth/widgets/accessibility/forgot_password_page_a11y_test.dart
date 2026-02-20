import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
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

import '../../../../utils/a11y/a11y_guidelines.dart';
import '../../../../utils/screenshot/font_loader.dart';

class _ForgotPasswordPageA11yTestModule extends Module {
  final AppBootstrap appBootstrap;
  _ForgotPasswordPageA11yTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
        RouterTestModule(),
        ClockTestModule(),
        AuthModule(appBootstrap),
      ];
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  BuildContext? buildContext;

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    CoreToast.disableTimers();

    final appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: fakeSupabase,
    );

    Modular.init(_ForgotPasswordPageA11yTestModule(appBootstrap));
    Modular.replaceInstance<SupabaseWrapper>(fakeSupabase);
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeSupabase.reset();
  });

  Widget makeTestableWidget({required Widget child, ThemeData? theme}) {
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
        theme: theme ?? createTestTheme(),
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

  group('ForgotPasswordPage – accessibility', () {
    testWidgets('meets a11y guidelines for continue button in both themes',
        (tester) async {
      await setupA11yTest(tester);
      await renderPage(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: const ForgotPasswordPage(),
        ),
        find.text(l10n().continueButton),
        setupAfterPump: (t) async {
          await enterEmail(t, 'reset@example.com');
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets(
      'meets a11y guidelines when email required error shown in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await renderPage(tester);
        await enterEmail(tester, '');
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(
            theme: theme,
            child: const ForgotPasswordPage(),
          ),
          find.text(l10n().emailRequiredError),
        );
      },
    );

    testWidgets(
      'meets a11y guidelines when invalid email error shown in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await renderPage(tester);
        await enterEmail(tester, 'invalid-email');
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(
            theme: theme,
            child: const ForgotPasswordPage(),
          ),
          find.text(l10n().invalidEmailError),
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for verify OTP button in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await renderPage(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(
            theme: theme,
            child: const ForgotPasswordPage(),
          ),
          find.text(l10n().verifyOtpButton),
          setupAfterPump: (t) async {
            await enterEmail(t, 'reset@example.com');
            await tapContinueButton(t);
            await enterOtp(t, '123456');
            await t.pumpAndSettle();
          },
        );
      },
    );

    testWidgets(
      'meets a11y guidelines for edit contact button in OTP modal in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await renderPage(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(
            theme: theme,
            child: const ForgotPasswordPage(),
          ),
          find.byKey(const Key('edit_contact_button')),
          setupAfterPump: (t) async {
            await enterEmail(t, 'reset@example.com');
            await tapContinueButton(t);
            await t.pumpAndSettle();
          },
        );
      },
    );

    testWidgets(
      'meets a11y guidelines when OTP error toast shown in both themes',
      (tester) async {
        fakeSupabase.shouldThrowOnVerifyOtp = true;
        fakeSupabase.authErrorCode =
            SupabaseAuthErrorCode.invalidCredentials;
        await setupA11yTest(tester);
        await renderPage(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) {
            fakeSupabase.shouldThrowOnVerifyOtp = true;
            fakeSupabase.authErrorCode =
                SupabaseAuthErrorCode.invalidCredentials;
            return makeTestableWidget(
              theme: theme,
              child: const ForgotPasswordPage(),
            );
          },
          find.byKey(const Key('toast_close_button')),
          setupAfterPump: (t) async {
            await enterEmail(t, 'reset@example.com');
            await t.tap(find.descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.text(l10n().continueButton),
            ));
            await t.pumpAndSettle();
            await enterOtp(t, '123456');
            await tapVerifyButton(t);
          },
        );
      },
    );

    testWidgets(
      'meets a11y guidelines when backend error toast shown in both themes',
      (tester) async {
        fakeSupabase.shouldThrowOnResetPassword = true;
        fakeSupabase.authErrorCode = SupabaseAuthErrorCode.rateLimited;
        await setupA11yTest(tester);
        await renderPage(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) {
            fakeSupabase.shouldThrowOnResetPassword = true;
            fakeSupabase.authErrorCode = SupabaseAuthErrorCode.rateLimited;
            return makeTestableWidget(
              theme: theme,
              child: const ForgotPasswordPage(),
            );
          },
          find.byKey(const Key('toast_close_button')),
          setupAfterPump: (t) async {
            await enterEmail(t, 'error@example.com');
            await t.tap(find.descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.text(l10n().continueButton),
            ));
            await t.pumpAndSettle();
          },
        );
      },
    );
  });
}

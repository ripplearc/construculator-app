import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/register_with_email_bloc/register_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/register_with_email_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
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

class _RegisterWithEmailPageA11yTestModule extends Module {
  final AppBootstrap appBootstrap;
  _RegisterWithEmailPageA11yTestModule(this.appBootstrap);

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

    Modular.init(_RegisterWithEmailPageA11yTestModule(appBootstrap));
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
        BlocProvider<RegisterWithEmailBloc>(
          create: (context) => Modular.get<RegisterWithEmailBloc>(),
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

  group('RegisterWithEmailPage – accessibility', () {
    testWidgets('meets a11y guidelines for continue button in both themes',
        (tester) async {
      fakeSupabase.clearTableData('users');
      fakeSupabase.setRpcResponse('check_email_exists', false);
      await setupA11yTest(tester);

      await renderPage(tester, email: 'newuser@example.com');
      await enterEmail(tester, 'newuser@example.com');
      await tester.pumpAndSettle();

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) {
          fakeSupabase.clearTableData('users');
          fakeSupabase.setRpcResponse('check_email_exists', false);
          return makeTestableWidget(
            theme: theme,
            child: const RegisterWithEmailPage(email: 'newuser@example.com'),
          );
        },
        find.text(l10n().continueButton),
      );
    });

    testWidgets('meets a11y guidelines for login link in both themes',
        (tester) async {
      await setupA11yTest(tester);

      await renderPage(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: const RegisterWithEmailPage(email: ''),
        ),
        find.byKey(const Key('auth_footer_link')),
      );
    });

    testWidgets(
      'meets a11y guidelines when email already registered (error with login link) in both themes',
      (tester) async {
        fakeSupabase.setRpcResponse('check_email_exists', true);
        await setupA11yTest(tester);
        await renderPage(tester);
        await enterEmail(tester, 'registered@example.com');
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) {
            fakeSupabase.setRpcResponse('check_email_exists', true);
            return makeTestableWidget(
              theme: theme,
              child: const RegisterWithEmailPage(email: 'registered@example.com'),
            );
          },
          find.byKey(Key(l10n().logginLink)),
        );
      },
    );

    testWidgets(
      'meets a11y guidelines when validation error shown in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await renderPage(tester);
        await enterEmail(tester, 'invalid-email');
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(
            theme: theme,
            child: const RegisterWithEmailPage(email: 'invalid-email'),
          ),
          find.text(l10n().invalidEmailError),
        );
      },
    );

    testWidgets(
      'meets a11y guidelines when server error toast shown in both themes',
      (tester) async {
        fakeSupabase.shouldThrowOnSelect = true;
        await setupA11yTest(tester);
        await renderPage(tester);
        await enterEmail(tester, 'error@example.com');
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) {
            fakeSupabase.shouldThrowOnSelect = true;
            return makeTestableWidget(
              theme: theme,
              child: const RegisterWithEmailPage(email: 'error@example.com'),
            );
          },
          find.byKey(const Key('toast_close_button')),
        );
      },
    );
  });
}

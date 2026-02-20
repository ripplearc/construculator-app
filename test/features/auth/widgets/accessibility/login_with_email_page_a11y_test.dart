import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/auth/presentation/bloc/login_with_email_bloc/login_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/login_with_email_page.dart';
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

class _LoginWithEmailPageA11yTestModule extends Module {
  final AppBootstrap appBootstrap;
  _LoginWithEmailPageA11yTestModule(this.appBootstrap);

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

    Modular.init(_LoginWithEmailPageA11yTestModule(appBootstrap));
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
    return BlocProvider<LoginWithEmailBloc>(
      create: (context) => Modular.get<LoginWithEmailBloc>(),
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

  group('LoginWithEmailPage – accessibility', () {
    testWidgets('meets a11y guidelines for continue button in both themes',
        (tester) async {
      fakeSupabase.setRpcResponse('check_email_exists', true);
      await setupA11yTest(tester);

      await renderPage(tester, email: 'test@example.com');

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: const LoginWithEmailPage(email: 'test@example.com'),
        ),
        find.text(l10n().continueButton),
      );
    });

    testWidgets('meets a11y guidelines for register link in both themes',
        (tester) async {
      await setupA11yTest(tester);

      await renderPage(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: const LoginWithEmailPage(email: ''),
        ),
        find.byKey(const Key('auth_footer_link')),
      );
    });

    testWidgets(
      'meets a11y guidelines when email not registered (error with register link) in both themes',
      (tester) async {
        fakeSupabase.setRpcResponse('check_email_exists', false);
        await setupA11yTest(tester);
        await renderPage(tester);
        await enterEmail(tester, 'notregistered@example.com');
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) {
            fakeSupabase.setRpcResponse('check_email_exists', false);
            return makeTestableWidget(
              theme: theme,
              child: const LoginWithEmailPage(email: 'notregistered@example.com'),
            );
          },
          find.byKey(const Key('Register')),
        );
      },
    );

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
            child: const LoginWithEmailPage(email: ''),
          ),
          find.text('Email is required'),
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
            child: const LoginWithEmailPage(email: 'invalid-email'),
          ),
          find.text('Please enter a valid email address'),
        );
      },
    );

    testWidgets(
      'meets a11y guidelines when server error toast shown in both themes',
      (tester) async {
        fakeSupabase.shouldThrowOnRpc = true;
        await setupA11yTest(tester);
        await renderPage(tester);
        await enterEmail(tester, 'error@example.com');
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) {
            fakeSupabase.shouldThrowOnRpc = true;
            return makeTestableWidget(
              theme: theme,
              child: const LoginWithEmailPage(email: 'error@example.com'),
            );
          },
          find.text('Close'),
        );
      },
    );
  });
}

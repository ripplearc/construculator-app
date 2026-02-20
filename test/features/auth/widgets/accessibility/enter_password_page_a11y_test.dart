import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/auth/presentation/bloc/enter_password_bloc/enter_password_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/enter_password_page.dart';
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

class _EnterPasswordPageA11yTestModule extends Module {
  final AppBootstrap appBootstrap;
  _EnterPasswordPageA11yTestModule(this.appBootstrap);

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
  const testEmail = 'test@example.com';

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    CoreToast.disableTimers();

    final appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: fakeSupabase,
    );

    Modular.init(_EnterPasswordPageA11yTestModule(appBootstrap));
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
    return BlocProvider<EnterPasswordBloc>(
      create: (context) => Modular.get<EnterPasswordBloc>(),
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

  group('EnterPasswordPage – accessibility', () {
    testWidgets('meets a11y guidelines for continue button in both themes',
        (tester) async {
      await setupA11yTest(tester);
      await renderPage(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: EnterPasswordPage(email: testEmail),
        ),
        find.text(l10n().continueButton),
        setupAfterPump: (t) async {
          await enterPassword(t, 'Password123!');
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('meets a11y guidelines for forgot password link in both themes',
        (tester) async {
      await setupA11yTest(tester);
      await renderPage(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: EnterPasswordPage(email: ''),
        ),
        find.text(l10n().forgotPasswordTitle),
      );
    });

    testWidgets('meets a11y guidelines for edit link in both themes',
        (tester) async {
      await setupA11yTest(tester);
      await renderPage(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: EnterPasswordPage(email: testEmail),
        ),
        find.byKey(const Key('edit_link')),
      );
    });

    testWidgets(
      'meets a11y guidelines when password required error shown in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await renderPage(tester);
        await enterPassword(tester, '');
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(
            theme: theme,
            child: EnterPasswordPage(email: testEmail),
          ),
          find.text(l10n().passwordRequiredError),
        );
      },
    );

    testWidgets(
      'meets a11y guidelines when invalid credentials toast shown in both themes',
      (tester) async {
        fakeSupabase.shouldThrowOnSignIn = true;
        fakeSupabase.authErrorCode = SupabaseAuthErrorCode.invalidCredentials;
        await setupA11yTest(tester);
        await renderPage(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) {
            fakeSupabase.shouldThrowOnSignIn = true;
            fakeSupabase.authErrorCode =
                SupabaseAuthErrorCode.invalidCredentials;
            return makeTestableWidget(
              theme: theme,
              child: EnterPasswordPage(email: testEmail),
            );
          },
          find.byKey(const Key('toast_close_button')),
          setupAfterPump: (t) async {
            await enterPassword(t, 'WrongPassword123!');
            await t.tap(find.descendant(
              of: find.byType(ListView),
              matching: find.text(l10n().continueButton),
            ));
            await t.pumpAndSettle();
          },
        );
      },
    );
  });
}

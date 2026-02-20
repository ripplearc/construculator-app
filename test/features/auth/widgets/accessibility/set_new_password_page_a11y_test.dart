import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/auth/presentation/bloc/set_new_password_bloc/set_new_password_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/set_new_password_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
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

class _SetNewPasswordPageA11yTestModule extends Module {
  final AppBootstrap appBootstrap;
  _SetNewPasswordPageA11yTestModule(this.appBootstrap);

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

  FakeUser createFakeUser(String email) {
    return FakeUser(
      id: 'fake-user-${email.hashCode}',
      email: email,
      createdAt: DateTime.now().toIso8601String(),
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

    Modular.init(_SetNewPasswordPageA11yTestModule(appBootstrap));
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
    return BlocProvider<SetNewPasswordBloc>(
      create: (context) => Modular.get<SetNewPasswordBloc>(),
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
      makeTestableWidget(child: SetNewPasswordPage(email: email)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterNewPassword(WidgetTester tester, String password) async {
    final passwordField = find.ancestor(
      of: find.text(l10n().newPasswordLabel),
      matching: find.byType(TextField),
    );
    await tester.enterText(passwordField, password);
    await tester.pump();
  }

  Future<void> enterConfirmPassword(
    WidgetTester tester,
    String password,
  ) async {
    final confirmPasswordField = find.ancestor(
      of: find.text(l10n().confirmPasswordLabel),
      matching: find.byType(TextField),
    );
    await tester.enterText(confirmPasswordField, password);
    await tester.pump();
  }

  Future<void> tapSetPasswordButton(WidgetTester tester) async {
    await tester.tap(find.text(l10n().setPasswordButton));
    await tester.pumpAndSettle();
  }

  group('SetNewPasswordPage – accessibility', () {
    testWidgets('meets a11y guidelines for set password button in both themes',
        (tester) async {
      const email = 'email@example.com';
      fakeSupabase.setCurrentUser(createFakeUser(email));
      await setupA11yTest(tester);
      await renderPage(tester, email: email);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) {
          fakeSupabase.setCurrentUser(createFakeUser(email));
          return makeTestableWidget(
            theme: theme,
            child: SetNewPasswordPage(email: email),
          );
        },
        find.text(l10n().setPasswordButton),
        setupAfterPump: (t) async {
          await enterNewPassword(t, '@Password123!');
          await enterConfirmPassword(t, '@Password123!');
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('meets a11y guidelines for new password label in both themes',
        (tester) async {
      await setupA11yTest(tester);
      await renderPage(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: SetNewPasswordPage(email: ''),
        ),
        find.text(l10n().newPasswordLabel),
      );
    });

    testWidgets('meets a11y guidelines for confirm password label in both themes',
        (tester) async {
      await setupA11yTest(tester);
      await renderPage(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: SetNewPasswordPage(email: ''),
        ),
        find.text(l10n().confirmPasswordLabel),
      );
    });

    testWidgets(
      'meets a11y guidelines when password too short error shown in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await renderPage(tester);
        await enterNewPassword(tester, '123');
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(
            theme: theme,
            child: SetNewPasswordPage(email: ''),
          ),
          find.text(l10n().passwordTooShortError),
        );
      },
    );

    testWidgets(
      'meets a11y guidelines when passwords do not match error shown in both themes',
      (tester) async {
        await setupA11yTest(tester);
        await renderPage(tester);
        await enterNewPassword(tester, 'Password123!');
        await enterConfirmPassword(tester, 'Password321!');
        await tester.pumpAndSettle();

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) => makeTestableWidget(
            theme: theme,
            child: SetNewPasswordPage(email: ''),
          ),
          find.text(l10n().passwordsDoNotMatchError),
        );
      },
    );

    testWidgets(
      'meets a11y guidelines when backend error toast shown in both themes',
      (tester) async {
        fakeSupabase.shouldThrowOnUpdate = true;
        await setupA11yTest(tester);
        await renderPage(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) {
            fakeSupabase.shouldThrowOnUpdate = true;
            return makeTestableWidget(
              theme: theme,
              child: SetNewPasswordPage(email: ''),
            );
          },
          find.byKey(const Key('toast_close_button')),
          setupAfterPump: (t) async {
            await enterNewPassword(t, 'Password123!');
            await enterConfirmPassword(t, 'Password123!');
            await tapSetPasswordButton(t);
          },
        );
      },
    );
  });
}

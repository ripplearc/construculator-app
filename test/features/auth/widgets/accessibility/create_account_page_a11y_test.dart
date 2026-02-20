import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/create_account_page.dart';
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

class _CreateAccountPageA11yTestModule extends Module {
  final AppBootstrap appBootstrap;
  _CreateAccountPageA11yTestModule(this.appBootstrap);

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
  const testRole = 'Engineer';

  setUpAll(() {
    fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
    CoreToast.disableTimers();

    final appBootstrap = AppBootstrap(
      config: FakeAppConfig(),
      envLoader: FakeEnvLoader(),
      supabaseWrapper: fakeSupabase,
    );

    Modular.init(_CreateAccountPageA11yTestModule(appBootstrap));
    Modular.replaceInstance<SupabaseWrapper>(fakeSupabase);
  });

  tearDownAll(() {
    Modular.destroy();
    CoreToast.enableTimers();
  });

  setUp(() {
    fakeSupabase.reset();
    fakeSupabase.addTableData('professional_roles', [
      {'id': 'uuid', 'name': testRole},
    ]);
  });

  Widget makeTestableWidget({required Widget child, ThemeData? theme}) {
    return BlocProvider<CreateAccountBloc>(
      create: (context) => Modular.get<CreateAccountBloc>(),
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
      makeTestableWidget(child: CreateAccountPage(email: email)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterFirstName(WidgetTester tester, String value) async {
    await tester.enterText(
      find.ancestor(
        of: find.text(l10n().firstNameLabel),
        matching: find.byType(TextField),
      ),
      value,
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterLastName(WidgetTester tester, String value) async {
    await tester.enterText(
      find.ancestor(
        of: find.text(l10n().lastNameLabel),
        matching: find.byType(TextField),
      ),
      value,
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterPassword(WidgetTester tester, String value) async {
    await tester.enterText(
      find.ancestor(
        of: find.text(l10n().passwordLabel),
        matching: find.byType(TextField),
      ),
      value,
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterConfirmPassword(WidgetTester tester, String value) async {
    await tester.enterText(
      find.ancestor(
        of: find.text(l10n().confirmPasswordLabel),
        matching: find.byType(TextField),
      ),
      value,
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectRole(WidgetTester tester, String roleName) async {
    await tester.tap(find.text(l10n().roleLabel), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text(roleName).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapContinueButton(WidgetTester tester) async {
    final button = find.text(l10n().agreeAndContinueButton);
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(button, 100, scrollable: scrollable);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> fillValidForm(WidgetTester tester) async {
    await enterFirstName(tester, 'John');
    await enterLastName(tester, 'Doe');
    await selectRole(tester, testRole);
    await enterPassword(tester, 'Password123!');
    await enterConfirmPassword(tester, 'Password123!');
  }

  group('CreateAccountPage – accessibility', () {
    testWidgets('meets a11y guidelines for continue button in both themes',
        (tester) async {
      await renderPage(tester);
      final buttonLabel = l10n().agreeAndContinueButton;
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: CreateAccountPage(email: testEmail),
        ),
        find.text(buttonLabel),
        setupAfterPump: (t) async {
          await fillValidForm(t);
          await t.pumpAndSettle();
          final button = find.text(buttonLabel);
          final scrollable = find.byType(Scrollable).first;
          await t.scrollUntilVisible(button, 100, scrollable: scrollable);
        },
      );
    });

    testWidgets('meets a11y guidelines for terms and services link in both themes',
        (tester) async {
      await renderPage(tester);
      final termsLink = l10n().termsAndServicesLink;
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: CreateAccountPage(email: testEmail),
        ),
        find.text(termsLink),
      );
    });

    testWidgets('meets a11y guidelines for role selector in both themes',
        (tester) async {
      await renderPage(tester);
      final roleLabelText = l10n().roleLabel;
      await setupA11yTest(tester);

      await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
        tester,
        (theme) => makeTestableWidget(
          theme: theme,
          child: CreateAccountPage(email: testEmail),
        ),
        find.text(roleLabelText),
      );
    });

    testWidgets(
      'meets a11y guidelines when account creation fails (toast close button) in both themes',
      (tester) async {
        fakeSupabase.shouldThrowOnInsert = true;
        fakeSupabase.authErrorCode = SupabaseAuthErrorCode.invalidCredentials;
        await renderPage(tester);
        await setupA11yTest(tester);

        await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
          tester,
          (theme) {
            fakeSupabase.shouldThrowOnInsert = true;
            fakeSupabase.authErrorCode = SupabaseAuthErrorCode.invalidCredentials;
            return makeTestableWidget(
              theme: theme,
              child: CreateAccountPage(email: testEmail),
            );
          },
          find.byKey(const Key('toast_close_button')),
          setupAfterPump: (t) async {
            await fillValidForm(t);
            await tapContinueButton(t);
          },
        );
      },
    );
  });
}

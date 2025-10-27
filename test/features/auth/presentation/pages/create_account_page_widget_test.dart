import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/auth/auth_module.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/create_account_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/config/testing/fake_app_config.dart';
import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/router/testing/router_test_module.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

class _CreateAccountPageTestModule extends Module {
  final AppBootstrap appBootstrap;
  _CreateAccountPageTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),
    ClockTestModule(),
    AuthModule(appBootstrap),
  ];
}

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  late Clock clock;
  const testEmail = 'test@example.com';
  const testRole = 'Engineer';

  BuildContext? buildContext;

  FakeUser createFakeUser(String email) {
    return FakeUser(
      id: 'fake-user-${email.hashCode}',
      email: email,
      createdAt: clock.now().toIso8601String(),
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

    Modular.init(_CreateAccountPageTestModule(appBootstrap));
    Modular.replaceInstance<SupabaseWrapper>(fakeSupabase);
    router = Modular.get<AppRouter>() as FakeAppRouter;
    clock = Modular.get<Clock>();
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

  Widget makeTestableWidget({required Widget child}) {
    return BlocProvider<CreateAccountBloc>(
      create: (context) => Modular.get<CreateAccountBloc>(),
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

  bool isContinueButtonEnabled(WidgetTester tester) {
    final buttonFinder = find.ancestor(
      of: find.text(l10n().agreeAndContinueButton),
      matching: find.byType(CoreButton),
    );
    if (buttonFinder.evaluate().isEmpty) return false;
    final button = tester.widget<CoreButton>(buttonFinder);
    return !button.isDisabled;
  }

  group('A User on CreateAccountPage', () {
    testWidgets('sees all form labels and instructions', (tester) async {
      await renderPage(tester);

      expect(find.textContaining(l10n().createAccountTitle), findsOneWidget);
      expect(find.textContaining(l10n().createAccountSubtitle), findsOneWidget);

      expect(find.text(l10n().firstNameLabel), findsOneWidget);
      expect(find.text(l10n().lastNameLabel), findsOneWidget);
      expect(find.text(l10n().emailLabel), findsOneWidget);
      expect(find.text(l10n().mobileNumberLabel), findsOneWidget);
      expect(find.text(l10n().passwordLabel), findsOneWidget);
      expect(find.text(l10n().confirmPasswordLabel), findsOneWidget);
      expect(find.text(l10n().roleLabel), findsOneWidget);

      expect(
        find.textContaining(l10n().termsAndConditionsText),
        findsOneWidget,
      );
      expect(find.textContaining(l10n().termsAndServicesLink), findsOneWidget);
      expect(find.textContaining(l10n().privacyPolicyLink), findsOneWidget);

      expect(find.text(l10n().agreeAndContinueButton), findsOneWidget);
    });

    testWidgets('cannot submit when first name is empty', (tester) async {
      await renderPage(tester);

      await enterLastName(tester, 'Doe');
      await enterPassword(tester, 'Password123!');
      await enterConfirmPassword(tester, 'Password123!');
      await selectRole(tester, testRole);

      expect(isContinueButtonEnabled(tester), isFalse);
    });

    testWidgets('cannot submit when last name is empty', (tester) async {
      await renderPage(tester);

      await enterFirstName(tester, 'John');
      await enterPassword(tester, 'Password123!');
      await enterConfirmPassword(tester, 'Password123!');
      await selectRole(tester, testRole);

      expect(isContinueButtonEnabled(tester), isFalse);
    });

    testWidgets('cannot submit when password is empty', (tester) async {
      await renderPage(tester);

      await enterFirstName(tester, 'John');
      await enterLastName(tester, 'Doe');
      await enterConfirmPassword(tester, 'Password123!');
      await selectRole(tester, testRole);

      expect(isContinueButtonEnabled(tester), isFalse);
    });

    testWidgets('cannot submit when passwords do not match', (tester) async {
      await renderPage(tester);

      await enterFirstName(tester, 'John');
      await enterLastName(tester, 'Doe');
      await enterPassword(tester, 'Password123!');
      await enterConfirmPassword(tester, 'DifferentPassword123!');
      await selectRole(tester, testRole);

      expect(isContinueButtonEnabled(tester), isFalse);
    });

    testWidgets('cannot submit when role is not selected', (tester) async {
      await renderPage(tester);

      await enterFirstName(tester, 'John');
      await enterLastName(tester, 'Doe');
      await enterPassword(tester, 'Password123!');
      await enterConfirmPassword(tester, 'Password123!');

      expect(isContinueButtonEnabled(tester), isFalse);
    });

    testWidgets('can select a professional role', (tester) async {
      await renderPage(tester);

      await tester.tap(find.text(l10n().roleLabel));
      await tester.pumpAndSettle();

      expect(find.text(l10n().selectRoleTitle), findsOneWidget);
      expect(find.text(testRole), findsAtLeastNWidgets(1));

      await tester.tap(find.text(testRole).last);
      await tester.pumpAndSettle();

      expect(find.text(testRole), findsAtLeastNWidgets(1));
    });

    testWidgets('sees error when roles fail to load', (tester) async {
      fakeSupabase.shouldThrowOnSelect = true;
      await renderPage(tester);

      expect(find.text(l10n().rolesLoadingError), findsOneWidget);
    });

    testWidgets('can toggle password visibility', (tester) async {
      await renderPage(tester);

      await enterPassword(tester, 'MyPassword123!');

      final passwordField = find.ancestor(
        of: find.text(l10n().passwordLabel),
        matching: find.byType(TextField),
      );

      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      final toggleButton = find.descendant(
        of: find.ancestor(
          of: find.text(l10n().passwordLabel),
          matching: find.byType(CoreTextField),
        ),
        matching: find.byType(IconButton),
      );
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    });

    testWidgets('can toggle confirm password visibility', (tester) async {
      await renderPage(tester);

      await enterConfirmPassword(tester, 'MyPassword123!');

      final confirmPasswordField = find.ancestor(
        of: find.text(l10n().confirmPasswordLabel),
        matching: find.byType(TextField),
      );

      expect(
        tester.widget<TextField>(confirmPasswordField).obscureText,
        isTrue,
      );

      final toggleButton = find.descendant(
        of: find.ancestor(
          of: find.text(l10n().confirmPasswordLabel),
          matching: find.byType(CoreTextField),
        ),
        matching: find.byType(IconButton),
      );
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(confirmPasswordField).obscureText,
        isFalse,
      );
    });

    testWidgets('sees continue button disabled when form is incomplete', (
      tester,
    ) async {
      await renderPage(tester);

      expect(isContinueButtonEnabled(tester), isFalse);

      await enterFirstName(tester, 'John');
      expect(isContinueButtonEnabled(tester), isFalse);

      await enterLastName(tester, 'Doe');
      expect(isContinueButtonEnabled(tester), isFalse);

      await selectRole(tester, testRole);
      expect(isContinueButtonEnabled(tester), isFalse);

      await enterPassword(tester, 'Password123!');
      expect(isContinueButtonEnabled(tester), isFalse);
    });

    testWidgets(
      'sees continue button enabled when all required fields are valid',
      (tester) async {
        await renderPage(tester);

        expect(isContinueButtonEnabled(tester), isFalse);

        await fillValidForm(tester);

        expect(isContinueButtonEnabled(tester), isTrue);
      },
    );

    testWidgets('sees continue button disabled if first name is invalid', (
      tester,
    ) async {
      await renderPage(tester);

      await enterFirstName(tester, '');
      await enterLastName(tester, 'Doe');
      await selectRole(tester, testRole);
      await enterPassword(tester, 'Password123!');
      await enterConfirmPassword(tester, 'Password123!');

      expect(isContinueButtonEnabled(tester), isFalse);
    });

    testWidgets('sees continue button disabled if last name is invalid', (
      tester,
    ) async {
      await renderPage(tester);

      await enterFirstName(tester, 'John');
      await enterLastName(tester, '');
      await selectRole(tester, testRole);
      await enterPassword(tester, 'Password123!');
      await enterConfirmPassword(tester, 'Password123!');

      expect(isContinueButtonEnabled(tester), isFalse);
    });

    testWidgets('sees continue button disabled if passwords do not match', (
      tester,
    ) async {
      await renderPage(tester);

      await enterFirstName(tester, 'John');
      await enterLastName(tester, 'Doe');
      await selectRole(tester, testRole);
      await enterPassword(tester, 'Password123!');
      await enterConfirmPassword(tester, 'DifferentPassword!');

      expect(isContinueButtonEnabled(tester), isFalse);
    });

    testWidgets('sees success message after successful account creation', (
      tester,
    ) async {
      fakeSupabase.setCurrentUser(createFakeUser(testEmail));
      await renderPage(tester);

      await fillValidForm(tester);
      await tapContinueButton(tester);

      expect(find.text(l10n().createAccountSuccessMessage), findsOneWidget);

      expect(find.text(l10n().continueButton), findsOneWidget);
    });

    testWidgets(
      'is navigated to dashboard after tapping continue on success modal',
      (tester) async {
        fakeSupabase.setCurrentUser(createFakeUser(testEmail));
        await renderPage(tester);

        await fillValidForm(tester);
        await tapContinueButton(tester);

        await tester.tap(find.text(l10n().continueButton));
        await tester.pumpAndSettle();

        expect(router.navigationHistory.length, 1);
        expect(router.navigationHistory.first.route, dashboardRoute);
      },
    );

    testWidgets('sees error message when account creation fails', (
      tester,
    ) async {
      fakeSupabase.shouldThrowOnInsert = true;
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.invalidCredentials;
      await renderPage(tester);

      await fillValidForm(tester);
      await tapContinueButton(tester);

      expect(find.text(l10n().invalidCredentialsError), findsOneWidget);

      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
    });

    testWidgets('sees button label change during account creation', (
      tester,
    ) async {
      fakeSupabase.setCurrentUser(createFakeUser(testEmail));
      await renderPage(tester);

      await fillValidForm(tester);

      final buttonFinder = find.text(l10n().agreeAndContinueButton);
      expect(buttonFinder, findsOneWidget);

      await tapContinueButton(tester);

      expect(find.text(l10n().createAccountSuccessMessage), findsOneWidget);
    });

    testWidgets(
      'sees email field shows pre-filled email and cannot be edited',
      (tester) async {
        await renderPage(tester, email: testEmail);

        final emailFieldFinder = find.ancestor(
          of: find.text(l10n().emailLabel),
          matching: find.byType(TextField),
        );

        final emailField = tester.widget<TextField>(emailFieldFinder);
        expect(emailField.controller?.text, testEmail);
        expect(emailField.enabled, isFalse);
      },
    );

    testWidgets('sees phone field is optional for email registration', (
      tester,
    ) async {
      await renderPage(tester, email: testEmail);

      await fillValidForm(tester);

      expect(isContinueButtonEnabled(tester), isTrue);
    });

    testWidgets('can interact with terms and conditions links', (tester) async {
      await renderPage(tester);

      expect(find.textContaining(l10n().termsAndServicesLink), findsOneWidget);
      expect(find.textContaining(l10n().privacyPolicyLink), findsOneWidget);

      await tester.tap(
        find.textContaining(l10n().termsAndServicesLink),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.textContaining(l10n().privacyPolicyLink),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n().createAccountTitle), findsOneWidget);
    });

    testWidgets('can register with phone number instead of email', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(phone: '1234567890')),
      );
      await tester.pumpAndSettle();

      await enterFirstName(tester, 'John');
      await enterLastName(tester, 'Doe');
      await selectRole(tester, testRole);
      await enterPassword(tester, 'Password123!');
      await enterConfirmPassword(tester, 'Password123!');

      expect(isContinueButtonEnabled(tester), isTrue);
    });

    testWidgets('completes phone registration and sees success', (
      tester,
    ) async {
      fakeSupabase.setCurrentUser(createFakeUser(testEmail));

      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(phone: '5551234567')),
      );
      await tester.pumpAndSettle();

      await fillValidForm(tester);
      await tapContinueButton(tester);

      expect(find.text(l10n().createAccountSuccessMessage), findsOneWidget);
    });
  });
}

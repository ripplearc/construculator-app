import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/create_account_page.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:core_ui/core_ui.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  const testEmail = 'test@example.com';
  const testRole = 'Engineer';
  const defaultCountryCode = '+1';
  BuildContext? buildContext;

  FakeUser createFakeUser(String email) {
    return FakeUser(
      id: 'fake-user-${email.hashCode}',
      email: email,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  setUp(() {
    CoreToast.disableTimers();
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
    fakeSupabase.addTableData('professional_roles', [
      {'id': 'uuid', 'name': testRole},
    ]);
  });

  tearDown(() {
    fakeSupabase.reset();
    Modular.destroy();
    CoreToast.enableTimers();
  });

  Widget makeTestableWidget({required Widget child}) {
    final bloc = Modular.get<CreateAccountBloc>();
    return BlocProvider.value(
      value: bloc,
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

  group('CreateAccountPage', () {
    testWidgets('renders all input fields, dropdown, terms, and button', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.createAccountTitle,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.createAccountSubtitle,
        ),
        findsOneWidget,
      );

      expect(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.firstNameLabel,
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.lastNameLabel,
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.emailLabel,
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.mobileNumberLabel,
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.passwordLabel,
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
        ),
        findsOneWidget,
      );

      final emailField = tester.widget<CoreTextField>(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.emailLabel,
        ),
      );
      expect(emailField.readOnly, isTrue);
      expect(emailField.enabled, isFalse);
      expect(emailField.suffix, isA<CoreIconWidget>());

      expect(find.byType(SingleItemSelector<String>), findsOneWidget);

      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.termsAndConditionsText,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.termsAndServicesLink,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(AppLocalizations.of(buildContext!)!.andAcknowledge),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.privacyPolicyLink,
        ),
        findsOneWidget,
      );

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.agreeAndContinueButton,
      );
      expect(continueButton, findsOneWidget);
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
    });
    testWidgets('password visibility toggles work', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: '')),
      );
      final iconButton = find.descendant(
        of: find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.passwordLabel,
        ),
        matching: find.byType(IconButton),
      );

      expect(iconButton, findsOneWidget);
      await tester.ensureVisible(iconButton);
      await tester.tap(iconButton);
      await tester.pumpAndSettle();

      final coreIcon = find.descendant(
        of: iconButton,
        matching: find.byType(CoreIconWidget),
      );
      expect(tester.widget<CoreIconWidget>(coreIcon).icon, CoreIcons.eye);
    });
    testWidgets('confirm password visibility toggles work', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: '')),
      );
      final iconButton = find.descendant(
        of: find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
        ),
        matching: find.byType(IconButton),
      );

      expect(iconButton, findsOneWidget);
      await tester.ensureVisible(iconButton);
      await tester.tap(iconButton);
      await tester.pumpAndSettle();

      final coreIcon = find.descendant(
        of: iconButton,
        matching: find.byType(CoreIconWidget),
      );
      expect(tester.widget<CoreIconWidget>(coreIcon).icon, CoreIcons.eye);
    });

    testWidgets('shows validation errors when input fields are invalid', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.firstNameLabel,
        ),
        '',
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.firstNameRequired,
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.lastNameLabel,
        ),
        '',
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.lastNameRequired,
        ),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.passwordLabel,
        ),
        '',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SingleItemSelector<String>));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.roleRequiredError,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.passwordRequiredError,
        ),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
        ),
        'Password123',
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.passwordsDoNotMatchError,
        ),
        findsOneWidget,
      );
    });
    testWidgets(
      'agree and continue button is disabled if firstname is invalid',
      (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
        );
        await tester.pumpAndSettle();
        final continueButton = find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.agreeAndContinueButton,
        );
        expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.firstNameLabel,
          ),
          '',
        );
        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.lastNameLabel,
          ),
          'Doe',
        );

        await tester.tap(find.byType(SingleItemSelector<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(testRole));

        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.passwordLabel,
          ),
          '@Password123!',
        );
        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
          ),
          '@Password123!',
        );
        await tester.pumpAndSettle();
        expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
      },
    );

    testWidgets('agree and continue button disables when lastname is invalid', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();
      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.agreeAndContinueButton,
      );
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.firstNameLabel,
        ),
        'John',
      );
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.lastNameLabel,
        ),
        '',
      );

      await tester.tap(find.byType(SingleItemSelector<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testRole));

      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.passwordLabel,
        ),
        '@Password123!',
      );
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
        ),
        '@Password123!',
      );
      await tester.pumpAndSettle();
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
    });

    testWidgets('agree and continue button disables when password is invalid', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();
      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.agreeAndContinueButton,
      );
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.firstNameLabel,
        ),
        'John',
      );
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.lastNameLabel,
        ),
        'Doe',
      );
      await tester.tap(find.byType(SingleItemSelector<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testRole));

      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.passwordLabel,
        ),
        '',
      );
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
        ),
        '@Password123!',
      );
      await tester.pumpAndSettle();
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
    });

    testWidgets(
      'agree and continue button disables when confirm password is invalid',
      (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
        );
        await tester.pumpAndSettle();
        final continueButton = find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.agreeAndContinueButton,
        );
        expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.firstNameLabel,
          ),
          'John',
        );
        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.lastNameLabel,
          ),
          'Doe',
        );

        await tester.tap(find.byType(SingleItemSelector<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(testRole));

        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.passwordLabel,
          ),
          '@Password123!',
        );
        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
          ),
          '@Pa',
        );
        await tester.pumpAndSettle();
        expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
      },
    );
    testWidgets('agree and continue button disables when phone is invalid', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();
      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.agreeAndContinueButton,
      );
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.firstNameLabel,
        ),
        'John',
      );
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.lastNameLabel,
        ),
        'Doe',
      );

      await tester.tap(find.byType(SingleItemSelector<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testRole));

      final prefixButtonFinder = find.descendant(
        of: find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.mobileNumberLabel,
        ),
        matching: find.byType(TextButton),
      );
      // select country code
      await tester.ensureVisible(prefixButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(prefixButtonFinder);

      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, defaultCountryCode));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.mobileNumberLabel,
        ),
        '123',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.passwordLabel,
        ),
        '@Password123!',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
        ),
        '@Password123!',
      );
      await tester.pumpAndSettle();
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
    });

    testWidgets(
      'agree and continue button enables when form fields are valid',
      (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
        );
        await tester.pumpAndSettle();
        final continueButton = find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.agreeAndContinueButton,
        );
        expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.firstNameLabel,
          ),
          'John',
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.lastNameLabel,
          ),
          'Doe',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(SingleItemSelector<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(testRole));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.passwordLabel,
          ),
          '@Password123!',
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
          ),
          '@Password123!',
        );
        await tester.pumpAndSettle();
        expect(tester.widget<CoreButton>(continueButton).isDisabled, isFalse);
      },
    );

    testWidgets('role selection bottom sheet shows on tap', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SingleItemSelector<String>));
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizations.of(buildContext!)!.selectRoleTitle),
        findsOneWidget,
      );
    });

    testWidgets('shows success modal on successful account creation', (
      tester,
    ) async {
      fakeSupabase.setCurrentUser(createFakeUser(testEmail));
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.firstNameLabel,
        ),
        'John',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.lastNameLabel,
        ),
        'Doe',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SingleItemSelector<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testRole));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.passwordLabel,
        ),
        'Password123!',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
        ),
        'Password123!',
      );
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.agreeAndContinueButton,
      );

      final scrollableFinder = find.byType(Scrollable).first;

      await tester.scrollUntilVisible(
        continueButton,
        100,
        scrollable: scrollableFinder,
      );

      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.createAccountSuccessMessage,
        ),
        findsOneWidget,
      );
      final continueToHomeButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueToHomeButton);
      await tester.pumpAndSettle();
      expect(router.navigationHistory.length, 1);
      expect(router.navigationHistory.first.route, dashboardRoute);
    });

    testWidgets('shows error toast when account creation fails', (
      tester,
    ) async {
      fakeSupabase.shouldThrowOnInsert = true;
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.invalidCredentials;
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.firstNameLabel,
        ),
        'John',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.lastNameLabel,
        ),
        'Doe',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SingleItemSelector<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testRole));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.passwordLabel,
        ),
        'Password123!',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
        ),
        'Password123!',
      );
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.agreeAndContinueButton,
      );

      final scrollableFinder = find.byType(Scrollable).first;

      await tester.scrollUntilVisible(
        continueButton,
        100,
        scrollable: scrollableFinder,
      );

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.invalidCredentialsError,
        ),
        findsOneWidget,
      );
    });
    testWidgets('shows error when professional roles fails to load', (
      tester,
    ) async {
      fakeSupabase.shouldThrowOnSelect = true;
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizations.of(buildContext!)!.rolesLoadingError),
        findsOneWidget,
      );
    });
 });
}

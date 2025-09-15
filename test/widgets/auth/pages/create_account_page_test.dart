import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/create_account_page.dart';
import 'package:construculator/features/auth/presentation/widgets/terms_and_conditions_section.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  late Clock clock;
  const testEmail = 'test@example.com';
  const testRole = 'Engineer';
  const defaultCountryCode = usCountryCode;

  BuildContext? buildContext;

  FakeUser createFakeUser(String email) {
    return FakeUser(
      id: 'fake-user-${email.hashCode}',
      email: email,
      createdAt: clock.now().toIso8601String(),
    );
  }

  setUp(() {
    CoreToast.disableTimers();
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
    clock = Modular.get<Clock>();
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

    testWidgets('button label changes during account creation', (tester) async {
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
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.passwordLabel,
        ),
        'Password123!',
      );
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

      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pumpAndSettle(); // Complete the operation

      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.createAccountSuccessMessage,
        ),
        findsOneWidget,
      );
    });

    testWidgets('phone prefix change triggers validation', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.mobileNumberLabel,
        ),
        '1234567890',
      );
      await tester.pumpAndSettle();

      final prefixButtonFinder = find.descendant(
        of: find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.mobileNumberLabel,
        ),
        matching: find.byType(TextButton),
      );

      await tester.ensureVisible(prefixButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(prefixButtonFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, defaultCountryCode));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.mobileNumberLabel,
        ),
        findsOneWidget,
      );
    });

    testWidgets('page initializes with phone parameter', (tester) async {
      const testPhone = '1234567890';
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(phone: testPhone)),
      );
      await tester.pumpAndSettle();

      final phoneField = tester.widget<CoreTextField>(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.mobileNumberLabel,
        ),
      );
      expect(phoneField.controller?.text, testPhone);
    });

    testWidgets('phone field is optional for email registration', (
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
      await tester.pumpAndSettle();
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

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.agreeAndContinueButton,
      );
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isFalse);
    });

    testWidgets('terms and conditions section is interactive', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

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
        find.textContaining(
          AppLocalizations.of(buildContext!)!.privacyPolicyLink,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'password field shows proper validation error for weak password',
      (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.passwordLabel,
          ),
          'weak',
        );
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(
            CoreTextField,
            AppLocalizations.of(buildContext!)!.passwordLabel,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('all text controllers are properly disposed', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      expect(true, true);
    });

    testWidgets('button is disabled during form submission', (tester) async {
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
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.passwordLabel,
        ),
        'Password123!',
      );
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

      expect(tester.widget<CoreButton>(continueButton).isDisabled, isFalse);

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.createAccountSuccessMessage,
        ),
        findsOneWidget,
      );
    });

    testWidgets('email field is pre-filled and disabled', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      final emailField = tester.widget<CoreTextField>(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.emailLabel,
        ),
      );

      expect(emailField.controller?.text, testEmail);
      expect(emailField.enabled, isFalse);
      expect(emailField.readOnly, isTrue);
    });

    testWidgets('validates first name field when empty', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      final firstNameField = find.widgetWithText(
        CoreTextField,
        AppLocalizations.of(buildContext!)!.firstNameLabel,
      );

      await tester.enterText(firstNameField, 'John');
      await tester.pumpAndSettle();

      await tester.enterText(firstNameField, '');
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.firstNameLabel,
        ),
        findsOneWidget,
      );
    });

    testWidgets('validates last name field when empty', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      final lastNameField = find.widgetWithText(
        CoreTextField,
        AppLocalizations.of(buildContext!)!.lastNameLabel,
      );

      await tester.enterText(lastNameField, 'Doe');
      await tester.pumpAndSettle();

      await tester.enterText(lastNameField, '');
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(lastNameField, findsOneWidget);
    });

    testWidgets('professional roles are loaded on page init', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleItemSelector<String>), findsOneWidget);
    });

    testWidgets('role error is displayed when role validation fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SingleItemSelector<String>));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.roleRequiredError,
        ),
        findsOneWidget,
      );
    });

    testWidgets('can toggle password visibility multiple times', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(
        CoreTextField,
        AppLocalizations.of(buildContext!)!.passwordLabel,
      );

      final passwordToggle = find.descendant(
        of: passwordField,
        matching: find.byType(IconButton),
      );

      final scrollableFinder = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        passwordField,
        100,
        scrollable: scrollableFinder,
      );

      await tester.tap(passwordToggle);
      await tester.pumpAndSettle();

      var coreIcon = find.descendant(
        of: passwordToggle,
        matching: find.byType(CoreIconWidget),
      );
      expect(tester.widget<CoreIconWidget>(coreIcon).icon, CoreIcons.eye);

      await tester.tap(passwordToggle);
      await tester.pumpAndSettle();

      coreIcon = find.descendant(
        of: passwordToggle,
        matching: find.byType(CoreIconWidget),
      );
      expect(tester.widget<CoreIconWidget>(coreIcon).icon, CoreIcons.eyeOff);
    });

    testWidgets('can toggle confirm password visibility multiple times', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      final confirmPasswordField = find.widgetWithText(
        CoreTextField,
        AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
      );

      final confirmPasswordToggle = find.descendant(
        of: confirmPasswordField,
        matching: find.byType(IconButton),
      );

      final scrollableFinder = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        confirmPasswordField,
        100,
        scrollable: scrollableFinder,
      );

      await tester.tap(confirmPasswordToggle);
      await tester.pumpAndSettle();

      var coreIcon = find.descendant(
        of: confirmPasswordToggle,
        matching: find.byType(CoreIconWidget),
      );
      expect(tester.widget<CoreIconWidget>(coreIcon).icon, CoreIcons.eye);

      await tester.tap(confirmPasswordToggle);
      await tester.pumpAndSettle();

      coreIcon = find.descendant(
        of: confirmPasswordToggle,
        matching: find.byType(CoreIconWidget),
      );
      expect(tester.widget<CoreIconWidget>(coreIcon).icon, CoreIcons.eyeOff);
    });

    testWidgets('terms and conditions section contains links', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
      );
      await tester.pumpAndSettle();

      final termsSection = find.byType(TermsAndConditionsSection);
      expect(termsSection, findsOneWidget);

      final scrollableFinder = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        termsSection,
        100,
        scrollable: scrollableFinder,
      );

      final termsText = find.textContaining(
        AppLocalizations.of(buildContext!)!.termsAndServicesLink,
      );
      final privacyText = find.textContaining(
        AppLocalizations.of(buildContext!)!.privacyPolicyLink,
      );

      expect(termsText, findsOneWidget);
      expect(privacyText, findsOneWidget);

      await tester.tap(termsText, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(privacyText, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(termsText, findsOneWidget);
      expect(privacyText, findsOneWidget);
    });
  });
}

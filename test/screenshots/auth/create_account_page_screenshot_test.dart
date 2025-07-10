import 'package:construculator/features/auth/domain/repositories/auth_repository.dart';
import 'package:construculator/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/create_account_page.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:construculator/features/auth/domain/usecases/get_professional_roles_usecase.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:core_ui/core_ui.dart';
import '../font_loader.dart';

import '../await_images_extension.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late AuthManager authManager;
  late AuthRepository repository;
  late FakeAppRouter router;
  const testEmail = 'test@example.com';
  BuildContext? buildContext;
  final size = const Size(390, 844);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  FakeUser createFakeUser(String email) {
    return FakeUser(
      id: 'fake-user-${email.hashCode}',
      email: email,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  setUp(() async {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    authManager = Modular.get<AuthManager>();
    repository = Modular.get<AuthRepository>();
    router = Modular.get<AppRouter>() as FakeAppRouter;
    await loadAppFonts();
    fakeSupabase.addTableData('professional_roles', [
      {'id': 'uuid', 'name': 'Engineer'},
    ]);
  });

  tearDown(() {
    fakeSupabase.reset();
    Modular.destroy();
  });

  Widget makeTestableWidget({required Widget child}) {
    final bloc = CreateAccountBloc(
      createAccountUseCase: CreateAccountUseCase(authManager),
      getProfessionalRolesUseCase: GetProfessionalRolesUseCase(repository),
      sendOtpUseCase: SendOtpUseCase(authManager),
    );
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

  group('CreateAccountPage Screenshot Tests', () {
    testWidgets('displays default state with all form fields', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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

      // Take screenshot of default state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/create_account/${size.width}x${size.height}/create_account_default_state.png',
        ),
      );
    });

    testWidgets('displays filled form state with enabled continue button', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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
      await tester.tap(find.text('Engineer'));

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
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.passwordsDoNotMatchError,
        ),
        findsNothing,
      );
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isFalse);

      // Take screenshot of filled state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/create_account/${size.width}x${size.height}/create_account_filled_state.png',
        ),
      );
    });

    testWidgets('displays role selection dropdown when role field is tapped', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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

      // Take screenshot of role selection state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/create_account/${size.width}x${size.height}/create_account_role_dropdown_state.png',
        ),
      );
    });

    testWidgets(
      'displays success modal when account creation is completed successfully',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
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
      await tester.tap(find.text('Engineer'));
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
        await tester.awaitImages();
        expect(
          find.textContaining(
            AppLocalizations.of(buildContext!)!.createAccountSuccessMessage,
          ),
          findsOneWidget,
        );

        // Take screenshot of success state
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/create_account/${size.width}x${size.height}/create_account_success_state.png',
          ),
        );

        final continueToHomeButton = find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        );
        await tester.tap(continueToHomeButton);
        await tester.pumpAndSettle();
        expect(router.navigationHistory.length, 1);
        expect(router.navigationHistory.first.route, dashboardRoute);
      },
    );

    testWidgets(
      'displays default state with all form fields and disabled continue button',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        await tester.pumpWidget(
          makeTestableWidget(child: const CreateAccountPage(email: testEmail)),
        );
        await tester.pumpAndSettle();

        final continueButton = find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.agreeAndContinueButton,
        );
        expect(continueButton, findsOneWidget);
        expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);

        final scrollableFinder = find.byType(Scrollable).first;

        await tester.scrollUntilVisible(
          continueButton,
          100,
          scrollable: scrollableFinder,
        );
        await tester.pumpAndSettle();

        // Take screenshot of default state
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/create_account/${size.width}x${size.height}/create_account_default_with_disabled_button.png',
          ),
        );
      },
    );

    testWidgets('displays enabled agree and continue button', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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
      await tester.tap(find.byType(SingleItemSelector<String>));
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizations.of(buildContext!)!.selectRoleTitle),
        findsOneWidget,
      );
      await tester.tap(find.text('Engineer'));
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
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/create_account/${size.width}x${size.height}/create_account_enabled_agree_and_continue_button.png',
        ),
      );
    });
  });
}

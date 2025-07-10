import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:core_ui/core_ui.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:construculator/features/auth/presentation/pages/login_with_email_page.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/features/auth/presentation/bloc/login_with_email_bloc/login_with_email_bloc.dart';
import 'package:construculator/features/auth/domain/usecases/check_email_availability_usecase.dart';
import '../font_loader.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late AuthManager authManager;
  late FakeAppRouter router;
  BuildContext? buildContext;
  final size = const Size(392, 873);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget makeTestableWidget({required Widget child}) {
    final loginBloc = LoginWithEmailBloc(
      checkEmailAvailabilityUseCase: CheckEmailAvailabilityUseCase(authManager),
    );
    return BlocProvider<LoginWithEmailBloc>.value(
      value: loginBloc,
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            buildContext = context;
            return child;
          },
        ),
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

  setUp(() async {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
    authManager = Modular.get<AuthManager>();
    await loadAppFonts();
  });


  tearDown(() {
    fakeSupabase.reset();
    router.reset();
    Modular.destroy();
  });

  group('LoginWithEmailPage Screenshot Tests', () {
    testWidgets(
      'displays default state with email input and disabled continue button',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        await tester.pumpWidget(
          makeTestableWidget(child: const LoginWithEmailPage(email: '')),
        );
        expect(
          find.text(AppLocalizations.of(buildContext!)!.emailLabel),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(
            CoreButton,
            AppLocalizations.of(buildContext!)!.continueButton,
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(AppLocalizations.of(buildContext!)!.register),
          findsOneWidget,
        );

        // Take screenshot of default state
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/login_with_email/${size.width}x${size.height}/login_with_email_default_state.png',
          ),
        );
      },
    );

    testWidgets(
      'displays validation errors when empty or invalid email is entered',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        await tester.pumpWidget(
          makeTestableWidget(child: const LoginWithEmailPage(email: '')),
        );
        await tester.enterText(find.byType(TextFormField), '');
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            AppLocalizations.of(buildContext!)!.emailRequiredError,
          ),
          findsOneWidget,
        );
        await tester.enterText(find.byType(TextFormField), 'invalid-email');
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            AppLocalizations.of(buildContext!)!.invalidEmailError,
          ),
          findsOneWidget,
        );

        // Take screenshot of validation error state
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/login_with_email/${size.width}x${size.height}/login_with_email_validation_error.png',
          ),
        );
      },
    );

    testWidgets(
      'displays enabled continue button when valid registered email is entered',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        fakeSupabase.addTableData('users', [
          {
            'id': '1',
            'email': 'registered@example.com',
            'created_at': DateTime.now().toIso8601String(),
          },
        ]);
        await tester.pumpWidget(
          makeTestableWidget(child: const LoginWithEmailPage(email: '')),
        );
        final enteredEmail = 'registered@example.com';
        await tester.enterText(find.byType(CoreTextField), enteredEmail);
        await tester.pumpAndSettle();

        final continueButton = find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        );
        expect(tester.widget<CoreButton>(continueButton).isDisabled, isFalse);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        expect(router.navigationHistory.first.route, fullEnterPasswordRoute);
        expect(router.navigationHistory.first.arguments, enteredEmail);

        // Take screenshot of valid email state
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/login_with_email/${size.width}x${size.height}/login_with_email_valid_email.png',
          ),
        );
      },
    );

    testWidgets(
      'displays error message with register link when unregistered email is entered',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        await tester.pumpWidget(
          makeTestableWidget(child: LoginWithEmailPage(email: '')),
        );
        await tester.enterText(
          find.byType(CoreTextField),
          'notregistered@example.com',
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            AppLocalizations.of(buildContext!)!.emailNotRegistered,
          ),
          findsOneWidget,
        );
        // Tap register link
        final registerLink = find.byKey(
          Key(AppLocalizations.of(buildContext!)!.register),
        );
        await tester.tap(registerLink);
        expect(router.navigationHistory.length, 1);
        expect(router.navigationHistory.first.route, fullRegisterRoute);

        // Take screenshot of email not registered state
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/login_with_email/${size.width}x${size.height}/login_with_email_not_registered.png',
          ),
        );
      },
    );

    testWidgets(
      'displays register link interaction when unregistered email is entered',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        await tester.pumpWidget(
          makeTestableWidget(child: LoginWithEmailPage(email: '')),
        );
        final enteredEmail = 'notregistered@example.com';
        await tester.enterText(find.byType(CoreTextField), enteredEmail);
        await tester.pumpAndSettle();

        final registerLink = find.byKey(
          Key(AppLocalizations.of(buildContext!)!.register),
        );
        await tester.tap(registerLink);

        expect(router.navigationHistory.first.route, fullRegisterRoute);
        expect(router.navigationHistory.first.arguments, enteredEmail);

        // Take screenshot of register link interaction
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/login_with_email/${size.width}x${size.height}/login_with_email_register_link.png',
          ),
        );
      },
    );

    testWidgets('displays backend error message when server error occurs', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      fakeSupabase.shouldThrowOnSelect = true;
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.invalidCredentials;
      await tester.pumpWidget(
        makeTestableWidget(child: LoginWithEmailPage(email: '')),
      );
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.emailLabel,
        ),
        'error@example.com',
      );
      await tester.pumpAndSettle();

      // Take screenshot of backend error state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/login_with_email/${size.width}x${size.height}/login_with_email_backend_error.png',
        ),
      );
    });
  });
}

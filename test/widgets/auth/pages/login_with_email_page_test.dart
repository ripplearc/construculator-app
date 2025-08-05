import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
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

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  BuildContext? buildContext;

  Widget makeTestableWidget({required Widget child}) {
    final loginBloc = Modular.get<LoginWithEmailBloc>();
    return BlocProvider<LoginWithEmailBloc>.value(
      value: loginBloc,
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

  setUp(() {
    CoreToast.disableTimers();
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
  });

  tearDown(() {
    fakeSupabase.reset();
    router.reset();
    Modular.destroy();
    CoreToast.enableTimers();
  });
  group('LoginWithEmailPage', () {
    testWidgets('renders email input, continue button, and register link', (
      WidgetTester tester,
    ) async {
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
    });

    testWidgets('shows validation errors for empty and invalid email', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const LoginWithEmailPage(email: '')),
      );
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.emailRequiredError,
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.pump();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.invalidEmailError,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'valid, registered email enables button and navigates to enter password',
      (WidgetTester tester) async {
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
        await tester.pump();

        final continueButton = find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        );
        expect(tester.widget<CoreButton>(continueButton).isDisabled, isFalse);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        expect(router.navigationHistory.first.route, fullEnterPasswordRoute);
        expect(router.navigationHistory.first.arguments, enteredEmail);
      },
    );

    testWidgets('email not registered shows error and register link', (
      WidgetTester tester,
    ) async {
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
      await tester.pumpAndSettle();
      expect(router.navigationHistory.length, 1);
      expect(router.navigationHistory.first.route, fullRegisterRoute);
    });

    testWidgets('login link navigates to login page on tap', (
      WidgetTester tester,
    ) async {
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
      await tester.pumpAndSettle();

      expect(router.navigationHistory.first.route, fullRegisterRoute);
      expect(router.navigationHistory.first.arguments, enteredEmail);
    });

    testWidgets('backend error shows error message', (
      WidgetTester tester,
    ) async {
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

      expect(
        find.textContaining(AppLocalizations.of(buildContext!)!.serverError),
        findsWidgets,
      );
    });

    testWidgets('footer register link navigates to register page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: LoginWithEmailPage(email: '')),
      );
      final registerLink = find.byKey(Key('auth_footer_link'));
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      expect(router.navigationHistory.first.route, fullRegisterRoute);
    });
  });
}

import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_ui/core_ui.dart';
import 'package:construculator/features/auth/presentation/pages/enter_password_page.dart';
import 'package:construculator/features/auth/presentation/bloc/enter_password_bloc/enter_password_bloc.dart';
import 'package:construculator/features/auth/domain/usecases/login_usecase.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  BuildContext? buildContext;
  const testEmail = 'test@example.com';
  setUp(() {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
  });

  tearDown(() {
    Modular.destroy();
  });

  Widget makeTestableWidget({required Widget child}) {
    final enterPasswordBloc = EnterPasswordBloc(
      loginUseCase: LoginUseCase(Modular.get<AuthManager>()),
    );
    return BlocProvider<EnterPasswordBloc>.value(
      value: enterPasswordBloc,
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

  group('EnterPasswordPage', () {
    testWidgets('renders password input, email, and main button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const EnterPasswordPage(email: testEmail)),
      );
      expect(
        find.text(AppLocalizations.of(buildContext!)!.passwordLabel),
        findsOneWidget,
      );
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));

      bool emailFound = richTexts.any((richText) {
        final span = richText.text;
        if (span is TextSpan) {
          return span.toPlainText().contains(testEmail);
        }
        return false;
      });
      expect(emailFound, isTrue);
      expect(
        find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        ),
        findsOneWidget,
      );
    });

    testWidgets('password visibility toggle works', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const EnterPasswordPage(email: testEmail)),
      );
      final eyeOffButton = find.byType(CoreIconWidget);
      final eyeOff = tester.widget<CoreIconWidget>(eyeOffButton);
      expect(eyeOff.icon, CoreIcons.eyeOff);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      final eyeButton = find.byType(CoreIconWidget);
      final eyeOn = tester.widget<CoreIconWidget>(eyeButton);
      expect(eyeOn.icon, CoreIcons.eye);
    });

    testWidgets('shows error for empty password', (WidgetTester tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const EnterPasswordPage(email: testEmail)),
      );
      await tester.enterText(find.byType(CoreTextField), '');
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.passwordRequiredError,
        ),
        findsWidgets,
      );
      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      expect(continueButton, findsOneWidget);
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
    });

    testWidgets('correct password shows success modal and navigates to home', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const EnterPasswordPage(email: testEmail)),
      );
      await tester.enterText(find.byType(CoreTextField), '5i2Un@D8Y9!');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.loginSuccessMessage,
        ),
        findsWidgets,
      );
    });

    testWidgets('wrong password shows error', (WidgetTester tester) async {
      fakeSupabase.shouldThrowOnSignIn = true;
      fakeSupabase.authErrorCode = SupabaseAuthErrorCode.invalidCredentials;
      await tester.pumpWidget(
        makeTestableWidget(child: const EnterPasswordPage(email: testEmail)),
      );
      await tester.enterText(find.byType(CoreTextField), '5i2Un@D8Y9!');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.invalidCredentialsError,
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
    });

    testWidgets('forgot password link navigates to forgot password page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: EnterPasswordPage(email: '')),
      );
      final forgotLink = find.textContaining(
        AppLocalizations.of(buildContext!)!.forgotPasswordTitle,
      );
      await tester.tap(forgotLink);
      await tester.pumpAndSettle();
      expect(router.navigationHistory.first.route, fullForgotPasswordRoute);
    });

    testWidgets('email edit link is present and tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const EnterPasswordPage(email: testEmail)),
      );
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      bool emailFound = richTexts.any((richText) {
        final span = richText.text;
        if (span is TextSpan) {
          return span.toPlainText().contains(testEmail);
        }
        return false;
      });
      expect(emailFound, isTrue);
      final emailLink = find.byKey(Key('edit_link'));
      await tester.tap(emailLink);
      await tester.pumpAndSettle();
      expect(router.popCalls, 1);
    });
  });
}

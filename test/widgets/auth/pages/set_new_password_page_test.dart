import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core_ui/core_ui.dart';
import 'package:construculator/features/auth/presentation/pages/set_new_password_page.dart';
import 'package:construculator/features/auth/presentation/bloc/set_new_password_bloc/set_new_password_bloc.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/testing/auth_test_module.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  BuildContext? buildContext;

  FakeUser createFakeUser(String email) {
    return FakeUser(
      id: 'fake-user-${email.hashCode}',
      email: email,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  setUp(() {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
  });

  tearDown(() {
    Modular.destroy();
  });

  Widget makeTestableWidget({required Widget child}) {
    final bloc = SetNewPasswordBloc(setNewPasswordUseCase: Modular.get());
    return BlocProvider<SetNewPasswordBloc>.value(
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

  group('SetNewPasswordPage', () {
    testWidgets('renders password and confirm password fields and button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const SetNewPasswordPage(email: '')),
      );
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.newPasswordLabel,
        ),
        findsWidgets,
      );
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
        ),
        findsWidgets,
      );
      final sentNewPasswordButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.setPasswordButton,
      );
      expect(sentNewPasswordButton, findsOneWidget);

      expect(
        tester.widget<CoreButton>(sentNewPasswordButton).isDisabled,
        isTrue,
      );
    });

    testWidgets('password and confirm password visibility toggles work', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const SetNewPasswordPage(email: '')),
      );
      final eyeOffButtons = find.byType(CoreIconWidget);
      expect(eyeOffButtons, findsNWidgets(2));

      // first toggle
      final eyeOffButton = eyeOffButtons.first;
      final eyeOff = tester.widget<CoreIconWidget>(eyeOffButton);
      expect(eyeOff.icon, CoreIcons.eyeOff);

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      final eyeButton = find.byType(CoreIconWidget).first;
      final eyeOn = tester.widget<CoreIconWidget>(eyeButton);
      expect(eyeOn.icon, CoreIcons.eye);

      // second toggle
      final eyeOffButton2 = eyeOffButtons.last;
      final eyeOff2 = tester.widget<CoreIconWidget>(eyeOffButton2);
      expect(eyeOff2.icon, CoreIcons.eyeOff);

      await tester.tap(find.byType(IconButton).last);
      await tester.pumpAndSettle();

      final eyeButton2 = find.byType(CoreIconWidget).last;
      final eyeOn2 = tester.widget<CoreIconWidget>(eyeButton2);
      expect(eyeOn2.icon, CoreIcons.eye);
    });

    testWidgets('shows error for weak password and password mismatch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const SetNewPasswordPage(email: '')),
      );
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.newPasswordLabel,
        ),
        '123',
      );
      await tester.pump();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.passwordTooShortError,
        ),
        findsWidgets,
      );

      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.newPasswordLabel,
        ),
        'Password123!',
      );
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.confirmPasswordLabel,
        ),
        'Password321!',
      );
      await tester.pump();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.passwordsDoNotMatchError,
        ),
        findsWidgets,
      );
        final sentNewPasswordButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.setPasswordButton,
      );
      expect(
        tester.widget<CoreButton>(sentNewPasswordButton).isDisabled,
        isTrue,
      );
    });

    testWidgets('valid passwords shows success modal', (
      WidgetTester tester,
    ) async {
      final String email = 'email@example.com';
      fakeSupabase.setCurrentUser(createFakeUser(email));
      await tester.pumpWidget(
        makeTestableWidget(child: SetNewPasswordPage(email: email)),
      );
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.newPasswordLabel,
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
        final sentNewPasswordButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.setPasswordButton,
      );
      expect(
        tester.widget<CoreButton>(sentNewPasswordButton).isDisabled,
        isFalse,
      );
      await tester.tap(sentNewPasswordButton);
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.passwordResetSuccessMessage,
        ),
        findsWidgets,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        ),
      );
      expect(router.navigationHistory.length, 1);
      expect(router.navigationHistory.first.route, dashboardRoute);
    });

    testWidgets('backend error shows error message', (
      WidgetTester tester,
    ) async {
      fakeSupabase.shouldThrowOnUpdate = true;
      await tester.pumpWidget(
        makeTestableWidget(child: const SetNewPasswordPage(email: '')),
      );
      await tester.enterText(
        find.widgetWithText(
          CoreTextField,
          AppLocalizations.of(buildContext!)!.newPasswordLabel,
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
      await tester.pump();
      await tester.tap(
        find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.setPasswordButton,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
      expect(
        find.textContaining(AppLocalizations.of(buildContext!)!.serverError),
        findsWidgets,
      );
    });
  });
}

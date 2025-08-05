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
import '../font_loader.dart';

import '../await_images_extension.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  BuildContext? buildContext;
  const size = Size(392, 873);
  const ratio = 1.0;

  FakeUser createFakeUser(String email) {
    return FakeUser(
      id: 'fake-user-${email.hashCode}',
      email: email,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  setUp(() async {
    CoreToast.disableTimers();
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    await loadAppFonts();
  });

  tearDown(() {
    Modular.destroy();
    CoreToast.enableTimers();
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

  group('SetNewPasswordPage Screenshot Tests', () {
    testWidgets('renders password and confirm password fields and button', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await tester.pumpWidget(
        makeTestableWidget(child: const SetNewPasswordPage(email: '')),
      );
      expect(find.textContaining(AppLocalizations.of(buildContext!)!.newPasswordLabel), findsWidgets);
      expect(find.textContaining(AppLocalizations.of(buildContext!)!.confirmPasswordLabel), findsWidgets);
      expect(find.widgetWithText(CoreButton, AppLocalizations.of(buildContext!)!.setPasswordButton), findsOneWidget);

      // Take screenshot of default state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/set_new_password/${size.width}x${size.height}/set_new_password_default_state.png',
        ),
      );
    });

    testWidgets('password and confirm password visibility toggles work', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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

      // Take screenshot of password visibility toggles
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/set_new_password/${size.width}x${size.height}/set_new_password_visibility_toggles.png',
        ),
      );
    });

    testWidgets('shows error for weak password and password mismatch', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await tester.pumpWidget(
        makeTestableWidget(child: const SetNewPasswordPage(email: '')),
      );
      await tester.enterText(
        find.widgetWithText(CoreTextField, AppLocalizations.of(buildContext!)!.newPasswordLabel),
        '123',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(AppLocalizations.of(buildContext!)!.passwordTooShortError), findsWidgets);

      await tester.enterText(
        find.widgetWithText(CoreTextField, AppLocalizations.of(buildContext!)!.newPasswordLabel),
        'Password123!',
      );
      await tester.enterText(
        find.widgetWithText(CoreTextField, AppLocalizations.of(buildContext!)!.confirmPasswordLabel),
        'Password321!',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(AppLocalizations.of(buildContext!)!.passwordsDoNotMatchError), findsWidgets);

      // Take screenshot of validation errors
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/set_new_password/${size.width}x${size.height}/set_new_password_validation_errors.png',
        ),
      );
    });

    testWidgets('valid passwords shows success modal', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      final String email = 'email@example.com';
      fakeSupabase.setCurrentUser(createFakeUser(email));
      await tester.pumpWidget(
        makeTestableWidget(child: SetNewPasswordPage(email: email)),
      );
      await tester.enterText(
        find.widgetWithText(CoreTextField, AppLocalizations.of(buildContext!)!.newPasswordLabel),
        '@Password123!',
      );
      await tester.enterText(
        find.widgetWithText(CoreTextField, AppLocalizations.of(buildContext!)!.confirmPasswordLabel),
        '@Password123!',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CoreButton, AppLocalizations.of(buildContext!)!.setPasswordButton));
      await tester.pumpAndSettle();
      expect(find.textContaining(AppLocalizations.of(buildContext!)!.passwordResetSuccessMessage), findsWidgets);
      await tester.awaitImages();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CoreButton, AppLocalizations.of(buildContext!)!.continueButton));

      // Take screenshot of success state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/set_new_password/${size.width}x${size.height}/set_new_password_success.png',
        ),
      );
    });

    testWidgets('backend error shows error message', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      fakeSupabase.shouldThrowOnUpdate = true;
      await tester.pumpWidget(
        makeTestableWidget(child: const SetNewPasswordPage(email: '')),
      );
      await tester.enterText(
        find.widgetWithText(CoreTextField, AppLocalizations.of(buildContext!)!.newPasswordLabel),
        'Password123!',
      );
      await tester.enterText(
        find.widgetWithText(CoreTextField, AppLocalizations.of(buildContext!)!.confirmPasswordLabel),
        'Password123!',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(CoreButton, AppLocalizations.of(buildContext!)!.setPasswordButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
      expect(find.textContaining(AppLocalizations.of(buildContext!)!.serverError), findsWidgets);

      // Take screenshot of backend error state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/set_new_password/${size.width}x${size.height}/set_new_password_backend_error.png',
        ),
      );
    });
  });
}

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

import '../await_images_extension.dart';
import '../font_loader.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  BuildContext? buildContext;
  const testEmail = 'test@example.com';
  final size = const Size(392, 873);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
    await loadAppFonts();
  });

  tearDown(() {
    fakeSupabase.reset();
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

  group('EnterPasswordPage Screenshot Tests', () {
    testWidgets('displays default state with password input and email display', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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

      // Take screenshot of default state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/enter_password/${size.width}x${size.height}/enter_password_default_state.png',
        ),
      );
    });

    testWidgets('displays password visibility toggle when eye icon is tapped', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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

      // Take screenshot of password visibility toggle
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/enter_password/${size.width}x${size.height}/enter_password_visibility_toggle.png',
        ),
      );
    });

    testWidgets('displays validation error when empty password is entered', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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

      // Take screenshot of empty password error
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/enter_password/${size.width}x${size.height}/enter_password_empty_error.png',
        ),
      );
    });

    testWidgets('displays success modal when correct password is entered', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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
      await tester.awaitImages();

      // Take screenshot of success state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/enter_password/${size.width}x${size.height}/enter_password_success.png',
        ),
      );
    });

    testWidgets('displays error message when incorrect password is entered', (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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

      // Take screenshot of wrong password error
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/enter_password/${size.width}x${size.height}/enter_password_wrong_password.png',
        ),
      );
    });

    testWidgets('displays forgot password link interaction when link is tapped', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await tester.pumpWidget(
        makeTestableWidget(child: EnterPasswordPage(email: '')),
      );
      final forgotLink = find.textContaining(
        AppLocalizations.of(buildContext!)!.forgotPasswordTitle,
      );
      await tester.tap(forgotLink);
      await tester.pumpAndSettle();
      expect(router.navigationHistory.first.route, fullForgotPasswordRoute);

      // Take screenshot of forgot password link interaction
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/enter_password/${size.width}x${size.height}/enter_password_forgot_link.png',
        ),
      );
    });

    testWidgets('email edit link is present and tappable', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
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

      // Take screenshot of email edit link interaction
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/enter_password/${size.width}x${size.height}/enter_password_email_edit.png',
        ),
      );
    });
  });
}

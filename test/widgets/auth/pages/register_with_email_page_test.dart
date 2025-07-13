import 'package:construculator/features/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/features/auth/presentation/pages/register_with_email_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/features/auth/presentation/bloc/register_with_email_bloc/register_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:core_ui/core_ui.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  late FakeAppRouter router;
  BuildContext? buildContext;

  Widget makeTestableWidget({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegisterWithEmailBloc>.value(
          value: Modular.get<RegisterWithEmailBloc>(),
        ),
        BlocProvider<OtpVerificationBloc>.value(
          value: Modular.get<OtpVerificationBloc>(),
        ),
      ],
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
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    router = Modular.get<AppRouter>() as FakeAppRouter;
  });

  tearDown(() {
    fakeSupabase.reset();
    Modular.destroy();
  });
  group('RegisterWithEmailPage', () {
    testWidgets('renders all page elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CoreTextField), findsOneWidget);

      expect(
        find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        ),
        findsOneWidget,
      );

      expect(
        find.textContaining(
          AppLocalizations.of(
            buildContext!,
          )!.heyEnterYourDetailsToRegisterWithUs,
        ),
        findsOneWidget,
      );
    });

    testWidgets('continue button is disabled on page load', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);
    });

    testWidgets('shows error message when invalid email is entered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'invalid-email');
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.invalidEmailError,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows error with login link when registered email is entered',
      (WidgetTester tester) async {
        fakeSupabase.addTableData('users', [
          {
            'id': '1',
            'email': 'registered@example.com',
            'created_at': DateTime.now().toIso8601String(),
          },
        ]);

        await tester.pumpWidget(
          makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
        );

        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(CoreTextField),
          'registered@example.com',
        );
        await tester.pumpAndSettle();

        final methodCalls = fakeSupabase.getMethodCallsFor('selectSingle');

        expect(methodCalls.length, 1);
        expect(
          find.textContaining(
            AppLocalizations.of(buildContext!)!.emailAlreadyRegistered,
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(
            CoreButton,
            AppLocalizations.of(buildContext!)!.continueButton,
          ),
          findsOneWidget,
        );
      },
    );
    testWidgets(
      'already registered login link pops page on tap',
      (WidgetTester tester) async {
        fakeSupabase.addTableData('users', [
          {
            'id': '1',
            'email': 'registered@example.com',
            'created_at': DateTime.now().toIso8601String(),
          },
        ]);

        await tester.pumpWidget(
          makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
        );

        await tester.pumpAndSettle();
        final enteredEmail = 'registered@example.com';
        await tester.enterText(find.byType(CoreTextField), enteredEmail);
        await tester.pumpAndSettle();

        final loginLink = find.byKey(
          Key(AppLocalizations.of(buildContext!)!.logginLink),
        );
        await tester.tap(loginLink);
        await tester.pumpAndSettle();

        expect(router.popCalls, 1);
      },
    );

    testWidgets('shows toast error when backend error occurs', (
      WidgetTester tester,
    ) async {
      fakeSupabase.shouldThrowOnSelect = true;

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'error@example.com');
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizations.of(buildContext!)!.serverError),
        findsOneWidget,
      );
      expect(find.byKey(const Key('toast_close_button')), findsOneWidget);
    });

    testWidgets(
      'enables continue button when valid unregistered email is entered',
      (WidgetTester tester) async {
        fakeSupabase.clearTableData('users');

        await tester.pumpWidget(
          makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(CoreTextField),
          'newuser@example.com',
        );
        await tester.pumpAndSettle();

        final continueButton = find.widgetWithText(
          CoreButton,
          AppLocalizations.of(buildContext!)!.continueButton,
        );
        expect(tester.widget<CoreButton>(continueButton).isDisabled, isFalse);
      },
    );

    testWidgets('displays OTP bottom sheet when continue button is pressed', (
      WidgetTester tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuser@example.com');
      await tester.pumpAndSettle();
      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.authenticationCodeTitle,
        ),
        findsOneWidget,
      );
      final verifyButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.verifyButtonLabel,
      );
      expect(tester.widget<CoreButton>(verifyButton).isDisabled, isTrue);
    });

    testWidgets('enables verify button when OTP is entered', (
      WidgetTester tester,
    ) async {
      fakeSupabase.clearTableData('users');

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'newuser@example.com');
      await tester.pumpAndSettle();
      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(Key('pin_input')), '123456');
      await tester.pumpAndSettle();
      final verifyButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.verifyButtonLabel,
      );
      expect(tester.widget<CoreButton>(verifyButton).isDisabled, isFalse);
    });
    testWidgets('footer login link pops page on tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(child: RegisterWithEmailPage(email: '')),
      );
      final loginLink = find.byKey(Key('auth_footer_link'));
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      expect(router.popCalls, 1);
    });
  });
}

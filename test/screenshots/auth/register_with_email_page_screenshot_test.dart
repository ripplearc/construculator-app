import 'dart:async';

import 'package:construculator/features/auth/testing/auth_test_module.dart';
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
import '../font_loader.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabase;
  BuildContext? buildContext;
  final size = const Size(392, 873);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget makeTestableWidget({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegisterWithEmailBloc>.value(
          value: RegisterWithEmailBloc(
            checkEmailAvailabilityUseCase: Modular.get(),
            sendOtpUseCase: Modular.get(),
          ),
        ),
        BlocProvider<OtpVerificationBloc>.value(
          value: OtpVerificationBloc(
            verifyOtpUseCase: Modular.get(),
            sendOtpUseCase: Modular.get(),
          ),
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

  setUp(() async {
    Modular.init(AuthTestModule());
    fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    await loadAppFonts();
  });

  tearDown(() {
    fakeSupabase.reset();
    Modular.destroy();
  });

  group('RegisterWithEmailPage Screenshot Tests', () {
    testWidgets(
      'displays default state with empty email input and disabled continue button',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
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

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/register_with_email/${size.width}x${size.height}/register_with_email_default_state.png',
          ),
        );
      },
    );

    testWidgets('displays disabled continue button state when page loads', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(
        CoreButton,
        AppLocalizations.of(buildContext!)!.continueButton,
      );
      expect(tester.widget<CoreButton>(continueButton).isDisabled, isTrue);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/register_with_email/${size.width}x${size.height}/register_with_email_disabled_button.png',
        ),
      );
    });

    testWidgets(
      'displays validation error when invalid email format is entered',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
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

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/register_with_email/${size.width}x${size.height}/register_with_email_invalid_email_state.png',
          ),
        );
      },
    );

    testWidgets('displays enabled button when valid email is entered', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'valid@example.com');
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.invalidEmailError,
        ),
        findsNothing,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/register_with_email/${size.width}x${size.height}/register_with_email_valid_email_state.png',
        ),
      );
    });
    testWidgets('displays disabled continue button when email is submited', (
      WidgetTester tester,
    ) async {
      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = Completer<void>();
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
      await tester.pump();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/register_with_email/${size.width}x${size.height}/register_with_email_button_loading_state.png',
        ),
      );
      fakeSupabase.completer!.complete();
    });
    testWidgets('displays otp bottom sheet when valid email is submited', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'valid@example.com');
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
          AppLocalizations.of(buildContext!)!.authenticationCodeTitle,
        ),
        findsOneWidget,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/register_with_email/${size.width}x${size.height}/register_with_email_otp_sheet_state.png',
        ),
      );
    });

    testWidgets('displays enabled verify button when otp is entered', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'valid@example.com');
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
          AppLocalizations.of(buildContext!)!.authenticationCodeTitle,
        ),
        findsOneWidget,
      );
      final editableText = find.descendant(
        of: find.byKey(const Key('pin_input')),
        matching: find.byType(EditableText),
      );
      expect(editableText, findsOneWidget);
      await tester.enterText(editableText, '123456');
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/register_with_email/${size.width}x${size.height}/register_with_email_otp_filled_state.png',
        ),
      );
    });

    testWidgets('displays disabled verify button when OTP is submitted', (
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
        AppLocalizations.of(buildContext!)!.verifyOtpButton,
      );

      fakeSupabase.shouldDelayOperations = true;
      fakeSupabase.completer = Completer<void>();

      await tester.tap(verifyButton);
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/register_with_email/${size.width}x${size.height}/register_with_email_otp_submitted_loading_state.png',
        ),
      );
      fakeSupabase.completer!.complete();
    });

    testWidgets(
      'displays error message with login link when already registered email is entered',
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

        // Take screenshot of email already registered state
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/register_with_email/${size.width}x${size.height}/register_with_email_already_registered_state.png',
          ),
        );
      },
    );
    testWidgets('displays backend error toast when server error occurs', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      fakeSupabase.shouldThrowOnSelect = true;

      await tester.pumpWidget(
        makeTestableWidget(child: const RegisterWithEmailPage(email: '')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CoreTextField), 'error@example.com');
      await tester.pumpAndSettle();

      // Take screenshot of backend error state
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/register_with_email/${size.width}x${size.height}/register_with_email_backend_error_state.png',
        ),
      );
    });
  });
}

import 'package:construculator/features/auth/presentation/widgets/auth_provider_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import '../../../../utils/screenshot/font_loader.dart';

void main() {
  BuildContext? buildContext;

  Future<void> pumpWidgetWith({
    required WidgetTester tester,
    required Function(AuthMethod) onPressed,
    required bool isEmailAuth,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            buildContext = context;
            return Scaffold(
              body: AuthProviderButtons(
                onPressed: onPressed,
                isEmailAuth: isEmailAuth,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AuthMethods Button Texts - isEmailAuth: true', () {
    testWidgets('shows Google button with correct text', (tester) async {
      await pumpWidgetWith(
        tester: tester,
        onPressed: (_) {},
        isEmailAuth: true,
      );
      expect(
        find.text(AppLocalizations.of(buildContext!)!.continueWithGoogle),
        findsOneWidget,
      );
    });

    testWidgets('shows Apple button with correct text', (tester) async {
      await pumpWidgetWith(
        tester: tester,
        onPressed: (_) {},
        isEmailAuth: true,
      );
      expect(
        find.text(AppLocalizations.of(buildContext!)!.continueWithApple),
        findsOneWidget,
      );
    });

    testWidgets('shows Microsoft button with correct text', (tester) async {
      await pumpWidgetWith(
        tester: tester,
        onPressed: (_) {},
        isEmailAuth: true,
      );
      expect(
        find.text(AppLocalizations.of(buildContext!)!.continueWithMicrosoft),
        findsOneWidget,
      );
    });

    testWidgets('shows Phone button with correct text', (tester) async {
      await pumpWidgetWith(
        tester: tester,
        onPressed: (_) {},
        isEmailAuth: true,
      );
      expect(
        find.text(AppLocalizations.of(buildContext!)!.continueWithPhone),
        findsOneWidget,
      );
    });

    testWidgets('does not show Email button', (tester) async {
      await pumpWidgetWith(
        tester: tester,
        onPressed: (_) {},
        isEmailAuth: true,
      );
      expect(
        find.text(AppLocalizations.of(buildContext!)!.continueWithEmail),
        findsNothing,
      );
    });
  });

  group('AuthMethods Button Texts - isEmailAuth: false', () {
    testWidgets('shows Email button with correct text', (tester) async {
      await pumpWidgetWith(
        tester: tester,
        onPressed: (_) {},
        isEmailAuth: false,
      );
      expect(
        find.text(AppLocalizations.of(buildContext!)!.continueWithEmail),
        findsOneWidget,
      );
    });

    testWidgets('does not show Phone button', (tester) async {
      await pumpWidgetWith(
        tester: tester,
        onPressed: (_) {},
        isEmailAuth: false,
      );
      expect(
        find.text(AppLocalizations.of(buildContext!)!.continueWithPhone),
        findsNothing,
      );
    });
  });

  group('AuthMethods Button Taps', () {
    testWidgets(
      'tapping Google button triggers callback with AuthMethod.google',
      (tester) async {
        AuthMethod? tapped;
        await pumpWidgetWith(
          tester: tester,
          onPressed: (m) => tapped = m,
          isEmailAuth: true,
        );
        await tester.tap(
          find.text(AppLocalizations.of(buildContext!)!.continueWithGoogle),
        );
        expect(tapped, AuthMethod.google);
      },
    );

    testWidgets(
      'tapping Apple button triggers callback with AuthMethod.apple',
      (tester) async {
        AuthMethod? tapped;
        await pumpWidgetWith(
          tester: tester,
          onPressed: (m) => tapped = m,
          isEmailAuth: true,
        );
        await tester.tap(
          find.text(AppLocalizations.of(buildContext!)!.continueWithApple),
        );
        expect(tapped, AuthMethod.apple);
      },
    );

    testWidgets(
      'tapping Microsoft button triggers callback with AuthMethod.microsoft',
      (tester) async {
        AuthMethod? tapped;
        await pumpWidgetWith(
          tester: tester,
          onPressed: (m) => tapped = m,
          isEmailAuth: true,
        );
        await tester.tap(
          find.text(AppLocalizations.of(buildContext!)!.continueWithMicrosoft),
        );
        expect(tapped, AuthMethod.microsoft);
      },
    );

    testWidgets(
      'tapping Phone button triggers callback with AuthMethod.phone',
      (tester) async {
        AuthMethod? tapped;
        await pumpWidgetWith(
          tester: tester,
          onPressed: (m) => tapped = m,
          isEmailAuth: true,
        );
        await tester.tap(
          find.text(AppLocalizations.of(buildContext!)!.continueWithPhone),
        );
        expect(tapped, AuthMethod.phone);
      },
    );

    testWidgets(
      'tapping Email button triggers callback with AuthMethod.email',
      (tester) async {
        AuthMethod? tapped;
        await pumpWidgetWith(
          tester: tester,
          onPressed: (m) => tapped = m,
          isEmailAuth: false,
        );
        await tester.tap(
          find.text(AppLocalizations.of(buildContext!)!.continueWithEmail),
        );
        expect(tapped, AuthMethod.email);
      },
    );
  });
}

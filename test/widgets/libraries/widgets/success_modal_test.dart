import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/widgets/success_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BuildContext? buildContext;
  testWidgets('SuccessModal displays default content and triggers callback', (
    WidgetTester tester,
  ) async {
    bool wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
            locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Builder(
          builder: (context) {
            buildContext = context;
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    SuccessModal.show(
                      context,
                      message: 'Operation Successful',
                      onPressed: () {
                        wasPressed = true;
                        Navigator.of(context).pop();
                      },
                    );
                  },
                  child: const Text('Open Modal'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    expect(find.text('Operation Successful'), findsOneWidget);

    expect(
      find.text(AppLocalizations.of(buildContext!)!.continueButton),
      findsOneWidget,
    );

    await tester.tap(
      find.text(AppLocalizations.of(buildContext!)!.continueButton),
    );
    await tester.pumpAndSettle();

    expect(wasPressed, isTrue);
    expect(find.text('Operation Successful'), findsNothing);
  });

  testWidgets('SuccessModal displays custom message and button label', (
    WidgetTester tester,
  ) async {
    bool callbackCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      SuccessModal.show(
                        context,
                        message: 'Account created successfully!',
                        buttonLabel: 'Great!',
                        onPressed: () {
                          callbackCalled = true;
                          Navigator.of(context).pop();
                        },
                      );
                    },
                    child: const Text('Trigger Modal'),
                  ),
                ),
              ),
        ),
      ),
    );

    await tester.tap(find.text('Trigger Modal'));
    await tester.pumpAndSettle();

    expect(find.text('Account created successfully!'), findsOneWidget);
    expect(find.text('Great!'), findsOneWidget);

    await tester.tap(find.text('Great!'));
    await tester.pumpAndSettle();

    expect(callbackCalled, isTrue);
  });
}

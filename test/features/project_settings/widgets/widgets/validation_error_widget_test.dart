import 'package:construculator/features/project_settings/presentation/widgets/validation_error_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget wrap(Widget child) => MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      );

  group('ValidationErrorWidget', () {
    group('Rendering', () {
      testWidgets('displays the provided error message', (tester) async {
        await tester.pumpWidget(
          wrap(const ValidationErrorWidget(message: 'Field is required')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Field is required'), findsOneWidget);
      });

      testWidgets('renders an error icon', (tester) async {
        await tester.pumpWidget(
          wrap(const ValidationErrorWidget(message: 'Some error')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('validation_error_icon')), findsOneWidget);
      });

      testWidgets('displays different messages correctly', (tester) async {
        await tester.pumpWidget(
          wrap(const ValidationErrorWidget(message: 'Project name is required')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Project name is required'), findsOneWidget);
      });
    });
  });
}

import 'package:construculator/features/project_settings/presentation/widgets/add_description_sheet.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_description_text_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  group('AddDescriptionSheet', () {
    group('Rendering', () {
      testWidgets('renders title, textarea, counter, and Add button', (tester) async {
        await tester.pumpWidget(
          wrap(AddDescriptionSheet(onAdd: (_) {})),
        );
        await tester.pumpAndSettle();

        expect(find.text('Add project description'), findsOneWidget);
        expect(find.text('Project description'), findsWidgets);
        expect(find.text('0/100'), findsOneWidget);
        expect(find.text('Add'), findsOneWidget);
      });

      testWidgets('pre-populates textarea with initialDescription', (tester) async {
        const initial = 'Existing description';
        await tester.pumpWidget(
          wrap(AddDescriptionSheet(initialDescription: initial, onAdd: (_) {})),
        );
        await tester.pumpAndSettle();

        expect(find.text(initial), findsOneWidget);
      });
    });

    group('Validation', () {
      testWidgets('Add button is enabled when textarea is empty (field is optional)', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(AddDescriptionSheet(onAdd: (_) {})),
        );
        await tester.pumpAndSettle();

        final addButton = tester.widget<CoreButton>(
          find.widgetWithText(CoreButton, 'Add'),
        );
        expect(addButton.isDisabled, isFalse);
      });

      testWidgets('counter updates as user types', (tester) async {
        await tester.pumpWidget(
          wrap(AddDescriptionSheet(onAdd: (_) {})),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(ProjectDescriptionTextField), 'Hello');
        await tester.pumpAndSettle();

        expect(find.text('5/100'), findsOneWidget);
      });

      testWidgets('shows error and disables Add button when text exceeds 100 chars', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(AddDescriptionSheet(onAdd: (_) {})),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'A' * 101,
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Description must be 100 characters or less'),
          findsOneWidget,
        );

        final addButton = tester.widget<CoreButton>(
          find.widgetWithText(CoreButton, 'Add'),
        );
        expect(addButton.isDisabled, isTrue);
      });

      testWidgets('re-enables Add button when text is reduced to valid length', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(AddDescriptionSheet(onAdd: (_) {})),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'A' * 101,
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'Valid text',
        );
        await tester.pumpAndSettle();

        final addButton = tester.widget<CoreButton>(
          find.widgetWithText(CoreButton, 'Add'),
        );
        expect(addButton.isDisabled, isFalse);
      });
    });

    group('User interactions', () {
      testWidgets('calls onAdd with trimmed text when Add is tapped', (tester) async {
        String? addedDescription;
        await tester.pumpWidget(
          wrap(AddDescriptionSheet(onAdd: (desc) => addedDescription = desc)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          '  My description  ',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(addedDescription, equals('My description'));
      });

      testWidgets('shows no error on first keystroke before limit is reached', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(AddDescriptionSheet(onAdd: (_) {})),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'Hello',
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Description must be 100 characters or less'),
          findsNothing,
        );
      });
    });
  });
}

import 'package:construculator/features/project_settings/presentation/widgets/project_description_text_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController();
  });

  tearDown(() {
    controller.dispose();
  });

  Widget wrap(Widget child) => MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      );

  group('ProjectDescriptionTextField', () {
    group('Rendering', () {
      testWidgets('renders label and counter at zero', (tester) async {
        await tester.pumpWidget(
          wrap(ProjectDescriptionTextField(controller: controller)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Project description'), findsWidgets);
        expect(find.text('0/100'), findsOneWidget);
      });

      testWidgets('shows no error before first interaction', (tester) async {
        await tester.pumpWidget(
          wrap(ProjectDescriptionTextField(controller: controller)),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Description must be 100 characters or less'),
          findsNothing,
        );
      });
    });

    group('Validation', () {
      testWidgets('empty field is valid (optional)', (tester) async {
        bool? validValue;
        await tester.pumpWidget(
          wrap(
            ProjectDescriptionTextField(
              controller: controller,
              onValidationChanged: (isValid) => validValue = isValid,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'A' * 101,
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          '',
        );
        await tester.pumpAndSettle();

        expect(find.text('Description must be 100 characters or less'), findsNothing);
        expect(validValue, isTrue);
      });

      testWidgets('shows no error for valid text within limit', (tester) async {
        await tester.pumpWidget(
          wrap(ProjectDescriptionTextField(controller: controller)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'A valid description',
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Description must be 100 characters or less'),
          findsNothing,
        );
      });

      testWidgets('shows too-long error when text exceeds 100 characters', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(ProjectDescriptionTextField(controller: controller)),
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
      });

      testWidgets('accepts text with exactly 100 characters', (tester) async {
        await tester.pumpWidget(
          wrap(ProjectDescriptionTextField(controller: controller)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'A' * 100,
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Description must be 100 characters or less'),
          findsNothing,
        );
      });

      testWidgets('error only appears after first interaction', (tester) async {
        await tester.pumpWidget(
          wrap(ProjectDescriptionTextField(controller: controller)),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Description must be 100 characters or less'),
          findsNothing,
        );

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'A' * 101,
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Description must be 100 characters or less'),
          findsOneWidget,
        );
      });
    });

    group('Counter', () {
      testWidgets('counter updates as user types', (tester) async {
        await tester.pumpWidget(
          wrap(ProjectDescriptionTextField(controller: controller)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'Hello',
        );
        await tester.pumpAndSettle();

        expect(find.text('5/100'), findsOneWidget);
      });

      testWidgets('counter shows 100/100 at limit', (tester) async {
        await tester.pumpWidget(
          wrap(ProjectDescriptionTextField(controller: controller)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'A' * 100,
        );
        await tester.pumpAndSettle();

        expect(find.text('100/100'), findsOneWidget);
      });
    });

    group('Callbacks', () {
      testWidgets('calls onDirtyChanged(true) on first keystroke', (
        tester,
      ) async {
        bool? dirtyValue;
        await tester.pumpWidget(
          wrap(
            ProjectDescriptionTextField(
              controller: controller,
              onDirtyChanged: (isDirty) => dirtyValue = isDirty,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(dirtyValue, isNull);

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'x',
        );
        await tester.pumpAndSettle();

        expect(dirtyValue, isTrue);
      });

      testWidgets('onDirtyChanged fires exactly once even after multiple keystrokes', (
        tester,
      ) async {
        int dirtyCount = 0;
        await tester.pumpWidget(
          wrap(
            ProjectDescriptionTextField(
              controller: controller,
              onDirtyChanged: (_) => dirtyCount++,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(ProjectDescriptionTextField), 'a');
        await tester.pump();
        await tester.enterText(find.byType(ProjectDescriptionTextField), 'ab');
        await tester.pump();

        expect(dirtyCount, 1);
      });

      testWidgets('calls onValidationChanged with false when over limit', (
        tester,
      ) async {
        bool? validValue;
        await tester.pumpWidget(
          wrap(
            ProjectDescriptionTextField(
              controller: controller,
              onValidationChanged: (isValid) => validValue = isValid,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'A' * 101,
        );
        await tester.pumpAndSettle();

        expect(validValue, isFalse);
      });

      testWidgets('calls onValidationChanged with true when text returns to valid', (
        tester,
      ) async {
        bool? validValue;
        await tester.pumpWidget(
          wrap(
            ProjectDescriptionTextField(
              controller: controller,
              onValidationChanged: (isValid) => validValue = isValid,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'A' * 101,
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(ProjectDescriptionTextField),
          'Valid description',
        );
        await tester.pumpAndSettle();

        expect(validValue, isTrue);
      });
    });
  });
}

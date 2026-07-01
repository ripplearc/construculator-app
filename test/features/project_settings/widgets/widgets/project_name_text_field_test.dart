import 'package:construculator/features/project_settings/presentation/widgets/project_name_text_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  late TextEditingController controller;

  setUpAll(() async {
    await loadAppFontsAll();
  });

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

  group('ProjectNameTextField', () {
    group('Rendering', () {
      testWidgets('renders label and hint text', (tester) async {
        await tester.pumpWidget(wrap(ProjectNameTextField(controller: controller)));
        await tester.pumpAndSettle();

        expect(find.text('Project name*'), findsOneWidget);
        expect(find.text('Enter project name'), findsOneWidget);
      });

      testWidgets('shows no error before first interaction', (tester) async {
        await tester.pumpWidget(wrap(ProjectNameTextField(controller: controller)));
        await tester.pumpAndSettle();

        expect(find.text('Project name is required'), findsNothing);
        expect(find.text('Project name must be 100 characters or less'), findsNothing);
      });

      testWidgets('is not interactable when disabled', (tester) async {
        await tester.pumpWidget(
          wrap(ProjectNameTextField(controller: controller, enabled: false)),
        );
        await tester.pumpAndSettle();

        final textField = tester.widget<CoreTextField>(find.byType(CoreTextField));
        expect(textField.enabled, isFalse);
      });
    });

    group('Validation', () {
      testWidgets('shows required error when field is empty after first interaction', (
        tester,
      ) async {
        await tester.pumpWidget(wrap(ProjectNameTextField(controller: controller)));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(ProjectNameTextField), 'a');
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(ProjectNameTextField), '');
        await tester.pumpAndSettle();

        expect(find.text('Project name is required'), findsOneWidget);
      });

      testWidgets('shows required error when field contains only whitespace', (
        tester,
      ) async {
        await tester.pumpWidget(wrap(ProjectNameTextField(controller: controller)));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(ProjectNameTextField), '   ');
        await tester.pumpAndSettle();

        expect(find.text('Project name is required'), findsOneWidget);
      });

      testWidgets('shows no error for valid non-empty name', (tester) async {
        await tester.pumpWidget(wrap(ProjectNameTextField(controller: controller)));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(ProjectNameTextField), 'My Project');
        await tester.pumpAndSettle();

        expect(find.text('Project name is required'), findsNothing);
        expect(find.text('Project name must be 100 characters or less'), findsNothing);
      });

      testWidgets('shows too-long error when name exceeds 100 characters', (
        tester,
      ) async {
        await tester.pumpWidget(wrap(ProjectNameTextField(controller: controller)));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectNameTextField),
          'A' * 101,
        );
        await tester.pumpAndSettle();

        expect(find.text('Project name must be 100 characters or less'), findsOneWidget);
      });

      testWidgets('accepts name with exactly 100 characters', (tester) async {
        await tester.pumpWidget(wrap(ProjectNameTextField(controller: controller)));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(ProjectNameTextField),
          'A' * 100,
        );
        await tester.pumpAndSettle();

        expect(find.text('Project name must be 100 characters or less'), findsNothing);
      });
    });

    group('showErrors', () {
      testWidgets('showErrors: true shows required error without user interaction', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(ProjectNameTextField(controller: controller, showErrors: true)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Project name is required'), findsOneWidget);
      });

      testWidgets('showErrors: false hides error before user interacts', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(ProjectNameTextField(controller: controller)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Project name is required'), findsNothing);
      });

      testWidgets('showErrors: true clears error once valid name is entered', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(ProjectNameTextField(controller: controller, showErrors: true)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Project name is required'), findsOneWidget);

        await tester.enterText(find.byType(ProjectNameTextField), 'My Project');
        await tester.pumpAndSettle();

        expect(find.text('Project name is required'), findsNothing);
      });
    });

    group('Callbacks', () {
      testWidgets('calls onDirtyChanged(true) on first keystroke', (tester) async {
        bool? dirtyValue;
        await tester.pumpWidget(
          wrap(
            ProjectNameTextField(
              controller: controller,
              onDirtyChanged: (isDirty) => dirtyValue = isDirty,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(dirtyValue, isNull);

        await tester.enterText(find.byType(ProjectNameTextField), 'a');
        await tester.pumpAndSettle();

        expect(dirtyValue, isTrue);
      });

      testWidgets('calls onDirtyChanged only once across multiple keystrokes', (
        tester,
      ) async {
        int callCount = 0;
        await tester.pumpWidget(
          wrap(
            ProjectNameTextField(
              controller: controller,
              onDirtyChanged: (_) => callCount++,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(ProjectNameTextField), 'a');
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(ProjectNameTextField), 'ab');
        await tester.pumpAndSettle();

        expect(callCount, 1);
      });

      testWidgets('calls onValidationChanged with false for empty name after interaction', (
        tester,
      ) async {
        bool? validValue;
        await tester.pumpWidget(
          wrap(
            ProjectNameTextField(
              controller: controller,
              onValidationChanged: (isValid) => validValue = isValid,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(ProjectNameTextField), 'a');
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(ProjectNameTextField), '');
        await tester.pumpAndSettle();

        expect(validValue, isFalse);
      });

      testWidgets('calls onValidationChanged with true for valid name', (tester) async {
        bool? validValue;
        await tester.pumpWidget(
          wrap(
            ProjectNameTextField(
              controller: controller,
              onValidationChanged: (isValid) => validValue = isValid,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(ProjectNameTextField), 'My Project');
        await tester.pumpAndSettle();

        expect(validValue, isTrue);
      });

      testWidgets('fires onValidationChanged on mount when controller is pre-populated', (
        tester,
      ) async {
        final prefilledController = TextEditingController(text: 'Existing Project');
        addTearDown(prefilledController.dispose);

        bool? validValue;
        await tester.pumpWidget(
          wrap(
            ProjectNameTextField(
              controller: prefilledController,
              onValidationChanged: (isValid) => validValue = isValid,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(validValue, isTrue);
      });

      testWidgets('re-validates and detaches old controller when parent swaps controller', (
        tester,
      ) async {
        bool? validValue;
        final controllerA = TextEditingController(text: 'HD building');
        final controllerB = TextEditingController();
        addTearDown(controllerA.dispose);
        addTearDown(controllerB.dispose);

        await tester.pumpWidget(
          wrap(ProjectNameTextField(
            controller: controllerA,
            onValidationChanged: (v) => validValue = v,
          )),
        );
        await tester.pumpAndSettle();
        expect(validValue, isTrue);

        await tester.pumpWidget(
          wrap(ProjectNameTextField(
            controller: controllerB,
            onValidationChanged: (v) => validValue = v,
          )),
        );
        await tester.pumpAndSettle();
        expect(validValue, isFalse);

        final valueBefore = validValue;
        controllerA.text = 'should be ignored';
        await tester.pumpAndSettle();
        expect(validValue, equals(valueBefore));
      });
    });
  });
}

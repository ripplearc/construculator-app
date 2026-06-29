import 'package:construculator/features/project_settings/presentation/widgets/delete_project_button.dart';
import 'package:construculator/features/project_settings/presentation/widgets/deletion_confirmation_bottom_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  group('DeleteProjectButton', () {
    const testProjectName = 'Material of Building';

    BuildContext? buildContext;

    Widget createWidget({
      String projectName = testProjectName,
      bool canDelete = true,
      bool isDeleting = false,
      VoidCallback? onDeleteConfirmed,
    }) {
      return MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            buildContext = context;
            return Scaffold(
              body: DeleteProjectButton(
                projectName: projectName,
                canDelete: canDelete,
                isDeleting: isDeleting,
                onDeleteConfirmed: onDeleteConfirmed,
              ),
            );
          },
        ),
      );
    }

    AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

    group('Visibility', () {
      testWidgets('renders button when canDelete is true', (tester) async {
        await tester.pumpWidget(createWidget(canDelete: true));

        expect(find.byKey(const Key('delete_project_button')), findsOneWidget);
      });

      testWidgets('renders nothing when canDelete is false', (tester) async {
        await tester.pumpWidget(createWidget(canDelete: false));

        expect(find.byKey(const Key('delete_project_button')), findsNothing);
      });
    });

    group('Disabled state', () {
      testWidgets('tapping shows sheet when isDeleting is false', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(isDeleting: false));

        await tester.tap(find.byKey(const Key('delete_project_button')));
        await tester.pumpAndSettle();

        expect(find.byType(DeletionConfirmationBottomSheet), findsOneWidget);
      });

      testWidgets('tapping does nothing when isDeleting is true', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(isDeleting: true));

        await tester.tap(
          find.byKey(const Key('delete_project_button')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.byType(DeletionConfirmationBottomSheet), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });

    group('Bottom sheet', () {
      testWidgets('tapping button shows DeletionConfirmationBottomSheet', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());

        await tester.tap(find.byKey(const Key('delete_project_button')));
        await tester.pumpAndSettle();

        expect(find.byType(DeletionConfirmationBottomSheet), findsOneWidget);
      });

      testWidgets('confirming deletion calls onDeleteConfirmed', (
        tester,
      ) async {
        bool confirmed = false;

        await tester.pumpWidget(
          createWidget(onDeleteConfirmed: () => confirmed = true),
        );

        await tester.tap(find.byKey(const Key('delete_project_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('delete_project_confirm_button')));
        await tester.pumpAndSettle();

        expect(confirmed, isTrue);
      });

      testWidgets('cancelling does not call onDeleteConfirmed', (
        tester,
      ) async {
        bool confirmed = false;

        await tester.pumpWidget(
          createWidget(onDeleteConfirmed: () => confirmed = true),
        );

        await tester.tap(find.byKey(const Key('delete_project_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('delete_project_cancel_button')));
        await tester.pumpAndSettle();

        expect(confirmed, isFalse);
      });

      testWidgets('sheet shows the correct project name', (tester) async {
        await tester.pumpWidget(createWidget(projectName: 'My Test Project'));

        await tester.tap(find.byKey(const Key('delete_project_button')));
        await tester.pumpAndSettle();

        expect(
          find.text(l10n().deleteProjectConfirmTitle('My Test Project')),
          findsOneWidget,
        );
      });
    });

    group('Edge cases', () {
      testWidgets('null onDeleteConfirmed does not throw when confirmed', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());

        await tester.tap(find.byKey(const Key('delete_project_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('delete_project_confirm_button')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });
  });
}

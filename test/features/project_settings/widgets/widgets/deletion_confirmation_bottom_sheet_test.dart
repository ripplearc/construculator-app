import 'package:construculator/features/project_settings/presentation/widgets/deletion_confirmation_bottom_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/screenshot/font_loader.dart';

void main() {
  group('DeletionConfirmationBottomSheet', () {
    const testProjectName = 'Material of Building';

    BuildContext? buildContext;

    Widget createWidget({
      String projectName = testProjectName,
      VoidCallback? onConfirm,
      VoidCallback? onCancel,
      int? imagesAttachedCount,
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
              body: DeletionConfirmationBottomSheet(
                projectName: projectName,
                onConfirm: onConfirm,
                onCancel: onCancel,
                imagesAttachedCount: imagesAttachedCount,
              ),
            );
          },
        ),
      );
    }

    AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

    group('Button callbacks', () {
      testWidgets('calls onConfirm when Yes, Delete is tapped', (tester) async {
        bool confirmed = false;

        await tester.pumpWidget(createWidget(onConfirm: () => confirmed = true));

        await tester.tap(find.text(l10n().yesDeleteButton));
        await tester.pump();

        expect(confirmed, isTrue);
      });

      testWidgets('calls onCancel when No, Keep is tapped', (tester) async {
        bool cancelled = false;

        await tester.pumpWidget(createWidget(onCancel: () => cancelled = true));

        await tester.tap(find.text(l10n().noKeepButton));
        await tester.pump();

        expect(cancelled, isTrue);
      });

      testWidgets('handles multiple confirm taps without exception', (
        tester,
      ) async {
        int count = 0;

        await tester.pumpWidget(createWidget(onConfirm: () => count++));

        await tester.tap(find.text(l10n().yesDeleteButton));
        await tester.pump();
        await tester.tap(find.text(l10n().yesDeleteButton));
        await tester.pump();

        expect(count, 2);
        expect(tester.takeException(), isNull);
      });
    });

    group('Image count chip rendering', () {
      testWidgets('shows chip when imagesAttachedCount is non-null', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(imagesAttachedCount: 25));

        expect(find.text(l10n().imagesAttachedCount(25)), findsOneWidget);
        expect(
          find.byKey(const Key('project_images_attached_count_container')),
          findsOneWidget,
        );
      });

      testWidgets('hides chip when imagesAttachedCount is null', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget());

        expect(
          find.byKey(const Key('project_images_attached_count_container')),
          findsNothing,
        );
      });

      testWidgets('shows chip with zero count when explicitly set to zero', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(imagesAttachedCount: 0));

        expect(find.text(l10n().imagesAttachedCount(0)), findsOneWidget);
        expect(
          find.byKey(const Key('project_images_attached_count_container')),
          findsOneWidget,
        );
      });

      testWidgets('handles large image count without exception', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(imagesAttachedCount: 9999));

        expect(find.text(l10n().imagesAttachedCount(9999)), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Edge cases', () {
      testWidgets('handles empty project name without exception', (
        tester,
      ) async {
        await tester.pumpWidget(createWidget(projectName: ''));

        expect(tester.takeException(), isNull);
      });

      testWidgets('handles null callbacks without exception', (tester) async {
        await tester.pumpWidget(createWidget());

        await tester.tap(find.text(l10n().yesDeleteButton));
        await tester.pump();
        await tester.tap(find.text(l10n().noKeepButton));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });
  });
}

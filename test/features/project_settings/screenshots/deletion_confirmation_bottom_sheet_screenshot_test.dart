import 'package:construculator/features/project_settings/presentation/widgets/deletion_confirmation_bottom_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  // Part A — isolated widget
  screenshotThemeGroups('DeletionConfirmationBottomSheet Screenshot Tests', (
    theme,
    suffix,
  ) {
    const size = Size(390, 420);
    const ratio = 1.0;

    Future<void> pumpSheet({
      required WidgetTester tester,
      String projectName = 'Material of Building',
      int? imagesAttachedCount,
      Size pumpSize = size,
    }) async {
      tester.view.physicalSize = pumpSize;
      tester.view.devicePixelRatio = ratio;

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) => Scaffold(
              backgroundColor: ctx.colorTheme.pageBackground,
              body: DeletionConfirmationBottomSheet(
                projectName: projectName,
                onConfirm: () {},
                onCancel: () {},
                imagesAttachedCount: imagesAttachedCount,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders default state without image count', (tester) async {
      await pumpSheet(tester: tester);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/deletion_confirmation_bottom_sheet/${size.width.toInt()}x${size.height.toInt()}/default_no_images$suffix.png',
        ),
      );
    });

    testWidgets('renders with 25 images attached', (tester) async {
      await pumpSheet(tester: tester, imagesAttachedCount: 25);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/deletion_confirmation_bottom_sheet/${size.width.toInt()}x${size.height.toInt()}/with_images_attached$suffix.png',
        ),
      );
    });

    testWidgets('renders with long project name', (tester) async {
      await pumpSheet(
        tester: tester,
        projectName:
            'This is a very long construction project name that should wrap to multiple lines to test overflow handling',
        imagesAttachedCount: 25,
        pumpSize: const Size(390, 500),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/deletion_confirmation_bottom_sheet/390x500/long_project_name$suffix.png',
        ),
      );
    });
  });

  // Part B — modal over empty background (validates Figma overlay appearance)
  screenshotThemeGroups(
    'DeletionConfirmationBottomSheet modal over background Screenshot Tests',
    (theme, suffix) {
      const size = Size(390, 844);
      const ratio = 1.0;

      testWidgets('renders as modal over page background', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: _ModalBackgroundPage(
              projectName: 'Material of Building',
              imagesAttachedCount: 25,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/deletion_confirmation_bottom_sheet/${size.width.toInt()}x${size.height.toInt()}/modal_over_background$suffix.png',
          ),
        );
      });
    },
  );
}

/// Renders a plain background page and opens the deletion sheet as a modal
/// after the first frame, so the golden captures the real modal overlay.
class _ModalBackgroundPage extends StatelessWidget {
  final String projectName;
  final int? imagesAttachedCount;

  const _ModalBackgroundPage({
    required this.projectName,
    this.imagesAttachedCount,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeletionConfirmationBottomSheet.show(
        context,
        projectName: projectName,
        imagesAttachedCount: imagesAttachedCount,
        onConfirm: () {},
        onCancel: () {},
      );
    });
    return const Scaffold(
      body: Center(child: Text('Project Details')),
    );
  }
}

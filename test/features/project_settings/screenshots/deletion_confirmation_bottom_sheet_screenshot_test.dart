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

  group('DeletionConfirmationBottomSheet Screenshot Tests', () {
    // Part A — isolated widget
    group('isolated widget', () {
      const size = Size(390, 420);
      const ratio = 1.0;

      Future<void> pumpSheet({
        required WidgetTester tester,
        String projectName = 'Material of Building',
        int? imagesAttachedCount,
      }) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;

        await tester.pumpWidget(
          MaterialApp(
            theme: createTestTheme(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DeletionConfirmationBottomSheet(
                projectName: projectName,
                onConfirm: () {},
                onCancel: () {},
                imagesAttachedCount: imagesAttachedCount,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      testWidgets('renders default state without image count', (tester) async {
        await pumpSheet(tester: tester);

        await expectLater(
          find.byType(DeletionConfirmationBottomSheet),
          matchesGoldenFile(
            'goldens/deletion_confirmation_bottom_sheet/${size.width.toInt()}x${size.height.toInt()}/default_no_images.png',
          ),
        );
      });

      testWidgets('renders with 25 images attached', (tester) async {
        await pumpSheet(tester: tester, imagesAttachedCount: 25);

        await expectLater(
          find.byType(DeletionConfirmationBottomSheet),
          matchesGoldenFile(
            'goldens/deletion_confirmation_bottom_sheet/${size.width.toInt()}x${size.height.toInt()}/with_images_attached.png',
          ),
        );
      });

      testWidgets('renders with long project name', (tester) async {
        const longNameSize = Size(390, 500);
        tester.view.physicalSize = longNameSize;
        tester.view.devicePixelRatio = ratio;

        await tester.pumpWidget(
          MaterialApp(
            theme: createTestTheme(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DeletionConfirmationBottomSheet(
                projectName:
                    'This is a very long construction project name that should wrap to multiple lines to test overflow handling',
                imagesAttachedCount: 25,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(DeletionConfirmationBottomSheet),
          matchesGoldenFile(
            'goldens/deletion_confirmation_bottom_sheet/${longNameSize.width.toInt()}x${longNameSize.height.toInt()}/long_project_name.png',
          ),
        );
      });
    });

    // Part B — modal over empty background (validates Figma overlay appearance)
    group('modal over background', () {
      const size = Size(390, 844);
      const ratio = 1.0;

      testWidgets('renders as modal over page background', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;

        await tester.pumpWidget(
          MaterialApp(
            theme: createTestTheme(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: _ModalBackgroundPage(
              sheet: DeletionConfirmationBottomSheet(
                projectName: 'Material of Building',
                imagesAttachedCount: 25,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/deletion_confirmation_bottom_sheet/${size.width.toInt()}x${size.height.toInt()}/modal_over_background.png',
          ),
        );
      });
    });
  });
}

/// Renders a plain background page and shows [sheet] as a modal bottom sheet
/// after the first frame, so the golden captures the real modal overlay.
class _ModalBackgroundPage extends StatelessWidget {
  final Widget sheet;

  const _ModalBackgroundPage({required this.sheet});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colorTheme.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => sheet,
      );
    });
    return const Scaffold(
      body: Center(child: Text('Project Details')),
    );
  }
}

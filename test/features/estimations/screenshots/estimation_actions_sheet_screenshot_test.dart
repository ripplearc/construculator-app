import 'package:construculator/features/estimation/presentation/widgets/estimation_actions_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 550);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  late ValueNotifier<bool> lockStatusNotifier;

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpActionsSheet({
    required WidgetTester tester,
    required String estimationName,
    bool isLocked = false,
    ThemeData? theme,
  }) async {
    lockStatusNotifier = ValueNotifier<bool>(isLocked);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EstimationActionsSheet(
            estimationName: estimationName,
            lockStatusNotifier: lockStatusNotifier,
            onRename: () {},
            onFavourite: () {},
            onRemove: () {},
            onLockToggle: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('EstimationActionsSheet Screenshot Tests - Light', () {
    tearDown(() {
      lockStatusNotifier.dispose();
    });

    testWidgets('renders with default state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpActionsSheet(tester: tester, estimationName: 'Estimation 1');

      await expectLater(
        find.byType(EstimationActionsSheet),
        matchesGoldenFile(
          'goldens/estimation_actions_sheet/${size.width}x${size.height}/estimation_actions_sheet_default.png',
        ),
      );
    });

    testWidgets('renders with long estimation name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpActionsSheet(
        tester: tester,
        estimationName:
            'This is a very very long long long estimation name that should be truncated to best fit the screen',
      );

      await expectLater(
        find.byType(EstimationActionsSheet),
        matchesGoldenFile(
          'goldens/estimation_actions_sheet/${size.width}x${size.height}/estimation_actions_sheet_long_name.png',
        ),
      );
    });

    testWidgets('renders with locked state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpActionsSheet(
        tester: tester,
        estimationName: 'Estimation 1',
        isLocked: true,
      );

      await expectLater(
        find.byType(EstimationActionsSheet),
        matchesGoldenFile(
          'goldens/estimation_actions_sheet/${size.width}x${size.height}/estimation_actions_sheet_locked.png',
        ),
      );
    });
  });

  group('EstimationActionsSheet Screenshot Tests - Dark', () {
    tearDown(() {
      lockStatusNotifier.dispose();
    });

    testWidgets('renders with default state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpActionsSheet(
        tester: tester,
        estimationName: 'Estimation 1',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(EstimationActionsSheet),
        matchesGoldenFile(
          'goldens/estimation_actions_sheet/${size.width}x${size.height}/estimation_actions_sheet_default_dark.png',
        ),
      );
    });

    testWidgets('renders with long estimation name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpActionsSheet(
        tester: tester,
        estimationName:
            'This is a very very long long long estimation name that should be truncated to best fit the screen',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(EstimationActionsSheet),
        matchesGoldenFile(
          'goldens/estimation_actions_sheet/${size.width}x${size.height}/estimation_actions_sheet_long_name_dark.png',
        ),
      );
    });

    testWidgets('renders with locked state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpActionsSheet(
        tester: tester,
        estimationName: 'Estimation 1',
        isLocked: true,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(EstimationActionsSheet),
        matchesGoldenFile(
          'goldens/estimation_actions_sheet/${size.width}x${size.height}/estimation_actions_sheet_locked_dark.png',
        ),
      );
    });
  });
}

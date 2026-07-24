import 'package:construculator/features/auth/presentation/widgets/error_widget_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 844);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  Future<void> pumpErrorWidget({
    required WidgetTester tester,
    String? error,
    String? link,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) {
                return buildErrorWidgetWithLink(
                  context: context,
                  errorText: error,
                  linkText: link,
                  onPressed: () {},
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ErrorWidgetBuilder Screenshot Tests - Light', () {
    testWidgets('renders error only correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpErrorWidget(
        tester: tester,
        error: 'Email not found. Please ',
        link: 'register',
      );

      await expectLater(
        find.byType(Center),
        matchesGoldenFile(
          'goldens/error_widget_builder/${size.width}x${size.height}/error_widget_builder_error_only.png',
        ),
      );
    });

    testWidgets('renders error with link correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpErrorWidget(
        tester: tester,
        error: 'Email ID already registered with us. Please ',
        link: 'login',
      );

      await expectLater(
        find.byType(Center),
        matchesGoldenFile(
          'goldens/error_widget_builder/${size.width}x${size.height}/error_widget_builder_error_with_link.png',
        ),
      );
    });
  });

  group('ErrorWidgetBuilder Screenshot Tests - Dark', () {
    testWidgets('renders error only correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpErrorWidget(
        tester: tester,
        error: 'Email not found. Please ',
        link: 'register',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Center),
        matchesGoldenFile(
          'goldens/error_widget_builder/${size.width}x${size.height}/error_widget_builder_error_only_dark.png',
        ),
      );
    });

    testWidgets('renders error with link correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpErrorWidget(
        tester: tester,
        error: 'Email ID already registered with us. Please ',
        link: 'login',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Center),
        matchesGoldenFile(
          'goldens/error_widget_builder/${size.width}x${size.height}/error_widget_builder_error_with_link_dark.png',
        ),
      );
    });
  });
}

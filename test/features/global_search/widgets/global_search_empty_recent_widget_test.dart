import 'package:construculator/features/global_search/presentation/widgets/global_search_empty_recent_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../utils/screenshot/font_loader.dart';

void main() {
  BuildContext? buildContext;

  Widget makeTestableWidget({required Widget child}) {
    return MaterialApp(
      theme: createTestTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            buildContext = context;
            return Center(child: child);
          },
        ),
      ),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(buildContext!)!;

  group('GlobalSearchEmptyRecentWidget', () {
    testWidgets('renders empty recent message from l10n', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const GlobalSearchEmptyRecentWidget()),
      );

      expect(find.text(l10n().globalSearchEmptyRecentMessage), findsOneWidget);
    });

    testWidgets('renders search icon image', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(child: const GlobalSearchEmptyRecentWidget()),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      expect((image.image as AssetImage).assetName, 'assets/icons/search_icon.png');
    });
  });
}


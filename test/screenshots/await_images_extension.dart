import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extension to wait for all images to be loaded in a [WidgetTester] context.
/// Use: await tester.awaitImages();
extension AwaitImages on WidgetTester {
  /// Waits for all Image and DecoratedBox (with image) widgets to be loaded.
  Future<void> awaitImages() async {
    await runAsync(() async {
      // Precache standalone Image widgets
      for (final element in find.byType(Image).evaluate()) {
        final imageWidget = element.widget as Image;
        final imageProvider = imageWidget.image;
        await precacheImage(imageProvider, element);
        await pumpAndSettle();
      }

      // Precache BoxDecoration images inside DecoratedBox widgets
      for (final element in find.byType(DecoratedBox).evaluate()) {
        final decoratedBox = element.widget as DecoratedBox;
        final decoration = decoratedBox.decoration;

        if (decoration is BoxDecoration) {
          final imageProvider = decoration.image?.image;
          if (imageProvider != null) {
            await precacheImage(imageProvider, element);
            await pumpAndSettle();
          }
        }
      }
    });
  }
}

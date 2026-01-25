import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Manually loads fonts for golden tests without relying on golden_toolkit.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadMaterialIcons();
  await _loadRobotoFonts(
    fontFiles: ['test/utils/screenshot/fonts/Roboto-Regular.ttf'],
  );
}

/// Use this when tests require Regular, Medium, and Bold Roboto variants.
Future<void> loadAppFontsAll() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadMaterialIcons();
  await _loadRobotoFonts(
    fontFiles: [
      'test/utils/screenshot/fonts/Roboto-Regular.ttf',
      'test/utils/screenshot/fonts/Roboto-Medium.ttf',
      'test/utils/screenshot/fonts/Roboto-Bold.ttf',
    ],
  );
}

Future<void> _loadRobotoFonts({List<String> fontFiles = const []}) async {
  try {
    final loader = FontLoader('Roboto');
    for (final filePath in fontFiles) {
      final bytes = await File(filePath).readAsBytes();
      final byteData = ByteData.view(Uint8List.fromList(bytes).buffer);
      loader.addFont(Future.value(byteData));
    }
    await loader.load();
  } catch (e) {
    debugPrint('Failed to load Roboto fonts: $e');
  }
}

Future<void> loadMaterialIcons() async {
  try {
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await iconLoader.load();
  } catch (e) {
    // Fallback to empty font to prevent crashes
    final fallbackLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(Uint8List(0).buffer)));
    await fallbackLoader.load();
  }
}

/// Creates a test theme with Roboto font applied to all typography styles
ThemeData createTestTheme() {
  final baseTheme = CoreTheme.light();
  final typography = baseTheme.extension<AppTypographyExtension>()!;
  final colors = baseTheme.extension<AppColorsExtension>()!;

  return ThemeData(
    fontFamily: 'Roboto',
    materialTapTargetSize: MaterialTapTargetSize.padded,
    primaryColor: colors.backgroundDarkOrient,
    extensions: [colors, typography],
  );
}

String derivedFontFamily(Map<String, dynamic> fontDefinition) {
  if (!fontDefinition.containsKey('family')) return '';

  final String fontFamily = fontDefinition['family'];

  // Skip MaterialIcons as we already loaded it
  if (fontFamily == 'MaterialIcons') return '';

  if (_overridableFonts.contains(fontFamily)) {
    return fontFamily;
  }

  if (fontFamily.startsWith('packages/')) {
    final fontFamilyName = fontFamily.split('/').last;
    if (_overridableFonts.any((font) => font == fontFamilyName)) {
      return fontFamilyName;
    }
  } else {
    for (final Map<String, dynamic> fontType in fontDefinition['fonts']) {
      final String? asset = fontType['asset'];
      if (asset != null && asset.startsWith('packages')) {
        final packageName = asset.split('/')[1];
        return 'packages/$packageName/$fontFamily';
      }
    }
  }
  return fontFamily;
}

const List<String> _overridableFonts = [
  'Roboto',
  '.SF UI Display',
  '.SF UI Text',
  '.SF Pro Text',
  '.SF Pro Display',
  'CupertinoIcons', // Added for Cupertino icons
];

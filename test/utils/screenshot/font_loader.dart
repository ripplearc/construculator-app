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
  var typography = baseTheme.extension<AppTypographyExtension>()!;
  typography = typography.copyWith(
    headlineLargeRegular: typography.headlineLargeRegular.copyWith(fontFamily: 'Roboto'),
      headlineLargeSemiBold: typography.headlineLargeSemiBold.copyWith(fontFamily: 'Roboto'),

      // Headline Medium - 24/32
      headlineMediumRegular: typography.headlineMediumRegular.copyWith(fontFamily: 'Roboto'),
      headlineMediumSemiBold: typography.headlineMediumSemiBold.copyWith(fontFamily: 'Roboto'),

      // Title Large - 20/28
      titleLargeRegular: typography.titleLargeRegular.copyWith(fontFamily: 'Roboto'),
      titleLargeMedium: typography.titleLargeMedium.copyWith(fontFamily: 'Roboto'),
      titleLargeSemiBold: typography.titleLargeSemiBold.copyWith(fontFamily: 'Roboto'),

      // Title Medium - 18/26
      titleMediumRegular: typography.titleMediumRegular.copyWith(fontFamily: 'Roboto'),
      titleMediumMedium: typography.titleMediumMedium.copyWith(fontFamily: 'Roboto'),
      titleMediumSemiBold: typography.titleMediumSemiBold.copyWith(fontFamily: 'Roboto'),

      // Body Large - 16/24
      bodyLargeRegular: typography.bodyLargeRegular.copyWith(fontFamily: 'Roboto'),
      bodyLargeMedium: typography.bodyLargeMedium.copyWith(fontFamily: 'Roboto'),
      bodyLargeSemiBold: typography.bodyLargeSemiBold.copyWith(fontFamily: 'Roboto'),

      // Body Medium - 14/20
      bodyMediumRegular: typography.bodyMediumRegular.copyWith(fontFamily: 'Roboto'),
      bodyMediumMedium: typography.bodyMediumMedium.copyWith(fontFamily: 'Roboto'),
      bodyMediumSemiBold: typography.bodyMediumSemiBold.copyWith(fontFamily: 'Roboto'),

      // Body Small - 12/16
      bodySmallRegular: typography.bodySmallRegular.copyWith(fontFamily: 'Roboto'),
      bodySmallMedium: typography.bodySmallMedium.copyWith(fontFamily: 'Roboto'),
      bodySmallSemiBold: typography.bodySmallSemiBold.copyWith(fontFamily: 'Roboto'),
    
    );
  final colors = baseTheme.extension<AppColorsExtension>()!;

  return ThemeData(
    fontFamily: 'Roboto',
    materialTapTargetSize: MaterialTapTargetSize.padded,
    primaryColor: colors.backgroundDarkOrient,
    extensions: [colors, typography],
  );
}

/// Creates a dark test theme with Roboto font for a11y tests.
ThemeData createTestThemeDark() {
  final baseTheme = CoreTheme.dark();
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

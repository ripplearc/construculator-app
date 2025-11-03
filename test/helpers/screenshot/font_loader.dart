import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadMaterialIcons();

  await _loadFontFromFile(
    'Roboto',
    'test/helpers/screenshot/fonts/Roboto-Regular.ttf',
  );
}

Future<void> _loadMaterialIcons() async {
  try {
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await iconLoader.load();
  } catch (e) {
    debugPrint('Failed to load MaterialIcons: $e');
    // Fallback to empty font to prevent crashes
    final fallbackLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(Uint8List(0).buffer)));
    await fallbackLoader.load();
  }
}

Future<void> _loadFontFromFile(String family, String filePath) async {
  try {
    final bytes = await File(filePath).readAsBytes();
    final byteData = ByteData.view(Uint8List.fromList(bytes).buffer);

    final loader = FontLoader(family)..addFont(Future.value(byteData));
    await loader.load();
  } catch (e) {
    debugPrint('Failed to load $family from $filePath: $e');

    final fallback = FontLoader(family)
      ..addFont(Future.value(ByteData.view(Uint8List(0).buffer)));
    await fallback.load();
  }
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

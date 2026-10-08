import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

/// The fill of an equipment sheet or dialog: white in the light theme, as in
/// the storyboard frames, and the page background in the dark theme.
// TODO: [CA-1251](https://ripplearc.youtrack.cloud/issue/CA-1251) Replace with CoreUI's white surface once it exists.
Color sheetSurface(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light
    ? context.colorTheme.buttonInverse
    : context.colorTheme.pageBackground;

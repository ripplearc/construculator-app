import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Extension on [BuildContext] to provide convenient access to theme and localization data.
///
/// This extension reduces boilerplate code by providing shorthand getters for commonly
/// accessed theme and localization properties.
///
/// Usage:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Container(
///     color: context.colorTheme.pageBackground,
///     child: Text(
///       context.l10n.helloWorld,
///       style: context.textTheme.bodyMediumRegular,
///     ),
///   );
/// }
/// ```
extension BuildContextExtensions on BuildContext {
  /// Returns the [AppColorsExtension] from the current theme.
  ///
  /// This is a shorthand for `Theme.of(context).extension<AppColorsExtension>()!`.
  ///
  /// Throws a [StateError] if the color extension is not found in the theme.
  ///
  /// Example:
  /// ```dart
  /// final backgroundColor = context.c.pageBackground;
  /// final primaryColor = context.colorTheme.primary;
  /// ```
  AppColorsExtension get colorTheme {
    final colors = Theme.of(this).extension<AppColorsExtension>();
    if (colors == null) {
      throw StateError(
        'AppColorsExtension not found in the theme. '
        'Ensure that your MaterialApp theme includes AppColorsExtension.',
      );
    }
    return colors;
  }

  /// Returns the [AppTypographyExtension] from the current theme.
  ///
  /// This is a shorthand for `Theme.of(context).extension<AppTypographyExtension>()!`.
  ///
  /// Throws a [StateError] if the typography extension is not found in the theme.
  ///
  /// Example:
  /// ```dart
  /// final titleStyle = context.textTheme.titleLargeBold;
  /// final bodyStyle = context.textTheme.bodyMediumRegular;
  /// ```
  AppTypographyExtension get textTheme {
    final typography = Theme.of(this).extension<AppTypographyExtension>();
    if (typography == null) {
      throw StateError(
        'AppTypographyExtension not found in the theme. '
        'Ensure that your MaterialApp theme includes AppTypographyExtension.',
      );
    }
    return typography;
  }

  /// Returns the [AppLocalizations] for the current locale.
  ///
  /// This is a shorthand for `AppLocalizations.of(context)!` with proper null checking.
  ///
  /// Throws a [StateError] if AppLocalizations is not found in the widget tree,
  /// providing a clear error message about missing localization configuration.
  ///
  /// Example:
  /// ```dart
  /// final greeting = context.l10n.helloWorld;
  /// final errorMessage = context.l10n.connectionError;
  /// ```
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      throw StateError(
        'AppLocalizations not found in the widget tree. '
        'Ensure that your MaterialApp has localizationsDelegates configured '
        'and that you are accessing this from a descendant widget.',
      );
    }
    return localizations;
  }
}

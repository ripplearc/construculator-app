import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// A mixin to automatically handle `AppLocalizations` lookup in `StatefulWidgets`.
///
/// This mixin:
/// - Defines a nullable `l10n` property containing `AppLocalizations`.
/// - Automatically updates `l10n` in `didChangeDependencies()`.
///
/// Usage:
/// ```dart
/// class MyPage extends StatefulWidget {
///   @override
///   _MyPageState createState() => _MyPageState();
/// }
///
/// class _MyPageState extends State<MyPage> with LocalizationMixin {
///   @override
///   Widget build(BuildContext context) {
///     return Text(l10n?.helloWorld ?? "Hello");
///   }
/// }
/// ```
mixin LocalizationMixin<T extends StatefulWidget> on State<T> {
  /// Holds the current localization instance for the widget.
  ///
  /// This is updated automatically in `didChangeDependencies`.
  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      throw StateError(
        'AppLocalizations not found in the widget tree. '
        'Ensure that your MaterialApp has localizationsDelegates configured '
        'and that you are accessing this from a descendant widget.',
      );
    }
    l10n = localizations;
  }
}

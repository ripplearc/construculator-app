import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Keeps a money field to digits with at most two decimals, and cleans what a
/// person naturally pastes or types into it.
///
/// `$`, spaces and thousands separators are removed, so `$1,250.00` becomes
/// `1250.00`. On a phone whose region writes a decimal comma, the comma is the
/// decimal point and a point is a thousands separator, so `8,50` becomes
/// `8.50`. The text the field holds is always a plain number such as `1250.5`.
///
/// A keystroke or paste that would add a third decimal, or go above
/// [largestAmount], is dropped and the field keeps its text. Both cases call
/// [onLimitReached], so the form can say why nothing happened. Other wrong
/// input (letters, a sign, a second point) is dropped silently.
class MoneyInputFormatter extends TextInputFormatter {
  /// The largest amount the field takes, or null when the field has no ceiling
  /// of its own.
  final double? largestAmount;

  /// Called when an edit is dropped for adding a third decimal or going above
  /// [largestAmount].
  final VoidCallback? onLimitReached;

  /// The locale of the phone, read on every edit so a region change applies
  /// without rebuilding the field. A null result reads as a decimal point.
  final Locale? Function()? deviceLocale;

  static final _twoDecimalsAtMost = RegExp(r'^\d*\.?\d{0,2}$');
  static final _digitsAndOnePoint = RegExp(r'^\d*\.?\d*$');
  static final _dollarSignOrSpace = RegExp(r'[$\s]');

  /// Creates a formatter that reports a refused limit edit through
  /// [onLimitReached].
  MoneyInputFormatter({
    this.largestAmount,
    this.onLimitReached,
    this.deviceLocale,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final text = _plainNumber(newValue.text);
    if (text.isEmpty) return oldValue;
    if (!_twoDecimalsAtMost.hasMatch(text)) {
      if (_digitsAndOnePoint.hasMatch(text)) onLimitReached?.call();
      return oldValue;
    }
    final value = double.tryParse(text);
    final ceiling = largestAmount;
    if (value != null && ceiling != null && value > ceiling) {
      onLimitReached?.call();
      return oldValue;
    }
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  String _plainNumber(String raw) {
    final withoutSymbols = raw.replaceAll(_dollarSignOrSpace, '');
    if (!_usesDecimalComma || !withoutSymbols.contains(',')) {
      return withoutSymbols.replaceAll(',', '');
    }
    return withoutSymbols.replaceAll('.', '').replaceAll(',', '.');
  }

  bool get _usesDecimalComma {
    final locale = deviceLocale?.call();
    if (locale == null) return false;
    final known = Intl.verifiedLocale(
      locale.toLanguageTag(),
      NumberFormat.localeExists,
      onFailure: (_) => 'en',
    );
    return NumberFormat.decimalPattern(known).symbols.DECIMAL_SEP == ',';
  }
}

import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Keeps a money field to digits with at most two decimals, and cleans what a
/// person naturally pastes or types into it.
///
/// Only the text that was typed or pasted is cleaned. The amount already in
/// the field stays as it is.
///
/// `$` and spaces are removed. On a phone whose region writes a decimal point,
/// a comma is removed only when it is a real thousands mark, so `$1,250.00`
/// becomes `1250.00` and `12,345,678` becomes `12345678`. Any other comma, such
/// as `12,50`, is refused instead of read as a thousands mark, because that
/// would make the amount 100 times larger.
///
/// On a phone whose region writes a decimal comma, the comma is the decimal
/// point, so `8,50` becomes `8.50`. In a pasted value a point is a thousands
/// separator, so `1.250,00` and `1.250` become `1250.00` and `1250`, and a
/// value with a point after the last comma is read in the US style, so
/// `1,250.00` becomes `1250.00`. The text the field holds is always a plain
/// number such as `1250.5`.
///
/// A keystroke or paste that would add a third decimal, or go above
/// [largestAmount], is dropped and the field keeps its text. Both cases call
/// [onLimitReached], so the form can say why nothing happened. Any other edit
/// that is dropped (letters, a sign, a second point, a comma that is not a
/// thousands mark) calls [onEditRefused].
class MoneyInputFormatter extends TextInputFormatter {
  /// The largest amount the field takes, or null when the field has no ceiling
  /// of its own.
  final double? largestAmount;

  /// Called when an edit is dropped for adding a third decimal or going above
  /// [largestAmount].
  final VoidCallback? onLimitReached;

  /// Called when an edit is dropped for a reason other than the two limits
  /// above.
  final VoidCallback? onEditRefused;

  /// The locale of the phone, read on every edit so a region change applies
  /// without rebuilding the field. A null result reads as a decimal point.
  final Locale? Function()? deviceLocale;

  static final _twoDecimalsAtMost = RegExp(r'^\d*\.?\d{0,2}$');
  static final _digitsAndOnePoint = RegExp(r'^\d*\.?\d*$');
  static final _commaThousands = RegExp(r'^\d{1,3}(,\d{3})+(\.\d*)?$');
  static final _pointThousands = RegExp(r'^\d{1,3}(\.\d{3})+$');
  static final _dollarSignOrSpace = RegExp(r'[$\s]');

  /// Creates a formatter that reports a refused limit edit through
  /// [onLimitReached] and any other refused edit through [onEditRefused].
  MoneyInputFormatter({
    this.largestAmount,
    this.onLimitReached,
    this.onEditRefused,
    this.deviceLocale,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final edit = _Edit.of(oldValue, newValue.text);
    final typed = edit.inserted.replaceAll(_dollarSignOrSpace, '');
    if (edit.inserted.isNotEmpty && typed.isEmpty) {
      onEditRefused?.call();
      return oldValue;
    }
    final text = edit.inserted.isEmpty
        ? newValue.text
        : _plainNumber(edit.head, typed, edit.tail);
    if (text == null || !_digitsAndOnePoint.hasMatch(text)) {
      onEditRefused?.call();
      return oldValue;
    }
    if (!_twoDecimalsAtMost.hasMatch(text)) {
      onLimitReached?.call();
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
      selection: TextSelection.collapsed(
        offset: text.length - edit.tail.length,
      ),
    );
  }

  String? _plainNumber(String head, String typed, String tail) {
    if (_usesDecimalComma) {
      return '$head${_decimalCommaInsert(typed)}$tail';
    }
    final joined = '$head$typed$tail';
    if (!joined.contains(',')) return joined;
    return _commaThousands.hasMatch(joined) ? joined.replaceAll(',', '') : null;
  }

  String _decimalCommaInsert(String typed) {
    final isOneTypedKey = typed.length == 1;
    if (isOneTypedKey) return typed == ',' ? '.' : typed;
    final lastComma = typed.lastIndexOf(',');
    final lastPoint = typed.lastIndexOf('.');
    if (lastComma > lastPoint) {
      return typed.replaceAll('.', '').replaceAll(',', '.');
    }
    if (lastComma >= 0) return typed.replaceAll(',', '');
    return _pointThousands.hasMatch(typed) ? typed.replaceAll('.', '') : typed;
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

/// The part of a new text that differs from the old one: what stays in front
/// ([head]), what was typed or pasted ([inserted]) and what stays behind
/// ([tail]).
class _Edit {
  final String head;
  final String inserted;
  final String tail;

  const _Edit(this.head, this.inserted, this.tail);

  // The replaced part comes from the selection the edit started with, so a
  // paste over a selected amount is cleaned whole. When the new text does not
  // fit that selection (a delete, or no selection), the part is found by
  // comparing the two texts.
  factory _Edit.of(TextEditingValue before, String after) {
    final selection = before.selection;
    if (selection.isValid && selection.end <= before.text.length) {
      final head = before.text.substring(0, selection.start);
      final tail = before.text.substring(selection.end);
      if (after.length >= head.length + tail.length &&
          after.startsWith(head) &&
          after.endsWith(tail)) {
        return _Edit(
          head,
          after.substring(head.length, after.length - tail.length),
          tail,
        );
      }
    }
    return _Edit.between(before.text, after);
  }

  factory _Edit.between(String before, String after) {
    final shortest = before.length < after.length
        ? before.length
        : after.length;
    var headLength = 0;
    while (headLength < shortest &&
        before.codeUnitAt(headLength) == after.codeUnitAt(headLength)) {
      headLength++;
    }
    var tailLength = 0;
    while (tailLength < shortest - headLength &&
        before.codeUnitAt(before.length - 1 - tailLength) ==
            after.codeUnitAt(after.length - 1 - tailLength)) {
      tailLength++;
    }
    return _Edit(
      after.substring(0, headLength),
      after.substring(headLength, after.length - tailLength),
      after.substring(after.length - tailLength),
    );
  }
}

import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:flutter/services.dart';

/// Keeps the Delivery field to a dollar amount the storyboard accepts: digits
/// with at most two decimals, up to [largestMoneyAmount] (CUJ 6, "Accepted
/// values").
///
/// A keystroke or paste that would add a third decimal or go above
/// [largestMoneyAmount] is dropped and the field keeps its text. Both cases
/// call [onLimitReached], so the form can say why nothing happened. Other
/// wrong input (letters, a comma, a second point) is dropped silently.
class DeliveryFeeInputFormatter extends TextInputFormatter {
  /// Called when an edit is dropped for adding a third decimal or going above
  /// [largestMoneyAmount].
  final VoidCallback? onLimitReached;

  static final _twoDecimalsAtMost = RegExp(r'^\d*\.?\d{0,2}$');
  static final _digitsAndOnePoint = RegExp(r'^\d*\.?\d*$');

  /// Creates a formatter that reports a refused limit edit through
  /// [onLimitReached].
  DeliveryFeeInputFormatter({this.onLimitReached});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!_twoDecimalsAtMost.hasMatch(text)) {
      if (_digitsAndOnePoint.hasMatch(text)) onLimitReached?.call();
      return oldValue;
    }
    final value = double.tryParse(text);
    if (value != null && value > largestMoneyAmount) {
      onLimitReached?.call();
      return oldValue;
    }
    return newValue;
  }
}

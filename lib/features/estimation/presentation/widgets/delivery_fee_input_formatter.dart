import 'package:flutter/services.dart';

/// Keeps the Delivery field to a dollar amount the storyboard accepts: digits
/// with at most two decimals, up to [largestFee] (CUJ 6, "Accepted values").
///
/// A keystroke or paste that would break the shape or go above [largestFee] is
/// dropped and the field keeps its text. Only the too-large case calls
/// [onTooLarge], so the form can say why nothing happened.
class DeliveryFeeInputFormatter extends TextInputFormatter {
  /// The largest delivery fee the form accepts, the same bound as a rate.
  static const double largestFee = 999999.99;

  /// Called when an edit is dropped for going above [largestFee].
  final VoidCallback? onTooLarge;

  static final _shape = RegExp(r'^\d*\.?\d{0,2}$');

  /// Creates a formatter that reports a too-large edit through [onTooLarge].
  DeliveryFeeInputFormatter({this.onTooLarge});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!_shape.hasMatch(text)) return oldValue;
    final value = double.tryParse(text);
    if (value != null && value > largestFee) {
      onTooLarge?.call();
      return oldValue;
    }
    return newValue;
  }
}

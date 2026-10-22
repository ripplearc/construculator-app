import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/widgets.dart';

/// A [TextEditingController] whose text stays a plain number such as `400`,
/// but which paints it as currency (`$400.00`) while [focusNode] is not
/// focused.
///
/// Because only the painted text changes, listeners and `double.tryParse` on
/// [text] keep working, and the user edits the raw number once the field
/// takes focus. Text that is not a number is painted as typed.
class CurrencyDisplayController extends TextEditingController {
  /// The focus node of the field this controller paints for. The controller
  /// listens to it to switch between the money format and the raw number.
  final FocusNode focusNode;

  /// Creates a controller that paints its number as currency while
  /// [focusNode] is not focused.
  CurrencyDisplayController({required this.focusNode}) {
    focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (focusNode.hasFocus) {
      selection = TextSelection.collapsed(offset: text.length);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final amount = double.tryParse(text);
    if (focusNode.hasFocus || amount == null) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    return TextSpan(
      style: style,
      text: DisplayFormatter.currency.format(amount),
    );
  }
}
